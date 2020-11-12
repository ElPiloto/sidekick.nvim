ts_query = require 'vim.treesitter.query'
nts_parsers = require('nvim-treesitter.parsers')
ts_utils = require('nvim-treesitter.ts_utils')

--DELETE
--local parser = vim.treesitter.get_parser(py_bufnr, 'python')
--tstree = parser:parse()
--local root_node = tstree:root()
--query = ts_query.get_query('python', 'locals')

local M = {}


local TSOutline = {}
TSOutline.__index = TSDefinition

-- Contains definition and/or scope information.
-- At least one of `def` or `scope` must be populated.
-- @param def {definition_name, definition_node}
-- @param scope {scope_name, scope_node}
function TSOutline.new(def, scope)
	local has_def = not vim.tbl_isempty(def)
	local has_scope = not vim.tbl_isempty(scope)
	local def_type = has_def and def[1][1] or nil
	local def_node = has_def and def[1][2] or nil

	local scope_node = has_scope and scope[1][2] or nil
	return setmetatable({
		--If this definition defines a scope, this contains the node.
		--This is needed to allow checking whether or not children are in this definition.
		scope_node = scope_node,
		--This is a pointer to the containing scope or def.
		parent = nil,
		--This is a pointer to scopes or def that belong in our scope.
		children = {},
		--This contains the specific node for the definition capture.
		--This allows us to print the definition.
		definition_node = def_node,
		--This is the type of definition (e.g. definition.function or definition.parameters)
		definition_type = def_type,
	}, TSOutline)
end

-- STEP 1A)
-- Iterates over the captures in a match to find defintion
-- or scope captures.
-- @param match Match value as returned by `query:iter_matches(...)`
function M.get_definitions_and_scopes_in_match(match, query)
	local defs = {}
	local scopes = {}

	for id, node in pairs(match) do
		local capture_name = query.captures[id]
		if string.match(capture_name, 'definition') then
			table.insert(defs, {capture_name, node})
		end
		if string.match(capture_name, 'scope') then
			table.insert(scopes, {capture_name, node})
		end
	end
	return defs, scopes
end

-- Convenience method.
function M.can_parse_buffer(bufnr)
	local lang = nts_parsers.get_buf_lang(bufnr)
	return nts_parsers.has_parser(lang)
end

--STEP 1)
function M.get_scope_and_definition_captures(bufnr, query_group)
	local lang = nts_parsers.get_buf_lang(bufnr)
	local parser = vim.treesitter.get_parser(bufnr, lang)
	local tstree = parser:parse()
	query_group = query_group or 'locals'
	local query = ts_query.get_query(lang, query_group)

	-- Return values
	local scopes_to_tsdef = {}
	local defs_to_tsdef = {}
	local all_defs = {}

	for pattern, match in query:iter_matches(tstree:root(), py_bufnr, 0, -1) do
		--NB: Currently we assume there's only a single definition that lives
		--in the same match as a scope.  If this assumption is violated, please
		--send @ElPIloto an example.
		local defs, scopes = M.get_definitions_and_scopes_in_match(match, query)
		if #scopes + #defs > 0 then
			ts_def = TSOutline.new(defs, scopes)
			table.insert(all_defs, ts_def)
			if #scopes > 0 then
				scopes_to_tsdef[scopes[1][2]:id()] = ts_def
			end
			if #defs > 0 then
				defs_to_tsdef[defs[1][2]:id()] = ts_def
			end
		end
	end
	return scopes_to_tsdef, defs_to_tsdef, all_defs
end

--STEP 2A)
local function find_parent(tsdef, scopes_to_tsdef)
	local node = nil
	if tsdef.scope_node then
		node = tsdef.scope_node:parent()
	else
		node = tsdef.definition_node:parent()
	end
	local found_parent = false
	while node and not found_parent do
		if scopes_to_tsdef[node:id()] then
			found_parent = true
		else
			node = node:parent()
		end
	end
	return node, found_parent
end

--STEP 2)
function M.find_parents(all_defs, scopes_to_tsdef) 
	local root_tsdef = nil
	for _, tsdef in pairs(all_defs) do
		local parent, found_parent = find_parent(tsdef, scopes_to_tsdef)
		if found_parent then
			local containing_tsdef = scopes_to_tsdef[parent:id()]
			table.insert(containing_tsdef.children, tsdef)
			tsdef.parent = containing_tsdef
		else
			root_tsdef = tsdef
		end
	end
	return root_tsdef
end

-- TODO (elpiloto): Hang this on TSOutline
function get_definition_info(tsdef)
	local def_name = ts_utils.get_node_text(tsdef.definition_node)[1]
	local def_type = tsdef.definition_type:gsub('definition%.', '')
	return def_name, def_type
end


-- Dict: key = definition_type, value = list of definition identifiers
function M.build_outline(root)
	local highlight_info = {}
	local ranges = {}

	-- Builds objects needed for an outline.
	-- @param tsdef current_tsdef being processed
	local function _build_outline(tsdef, indent, ranges)
		if tsdef.definition_node then
			local def_text = ts_utils.get_node_text(tsdef.definition_node)[1]
			local def_type = tsdef.definition_type
			if not highlight_info[def_type] then
				highlight_info[def_type] = {def_text}
			else
				table.insert(highlight_info[def_type], def_text)
			end
			local start_row, start_col, end_row, end_col = tsdef.definition_node:range()
			local def_name, def_type = get_definition_info(tsdef)
			table.insert(ranges, {def_name, def_type, indent, start_row, start_col, end_row, end_col})
			indent = indent + 1
		end
		if tsdef.children then
			for _, child in pairs(tsdef.children) do
				_build_outline(child, indent, ranges)
			end
		end
	end
	_build_outline(root, 0, ranges)
	return ranges, highlight_info
end

function M.set_highlight(highlight_info)
	local syntax_groups = {}
	local highlight_links = {}
	for def_type, def_type_defs in pairs(highlight_info) do
		-- Create syntax group called sidekick$sanitize(def_type)
		local str = "sidekick" .. def_type:gsub("%.", "_")
		local syntax_group = "syntax keyword  " .. str .. " " ..  table.concat(def_type_defs, " ")
		vim.cmd(syntax_group)

		-- Associate that syntax group with existing types
		-- TODO (elpiloto): Make "String" configurable.
		local highlight_link = "highlight default link " .. str .. " String"
		vim.cmd(highlight_link)
	end
end

return M
