ts_query = require 'vim.treesitter.query'
nts_locals = require('nvim-treesitter.locals')
nts_parsers = require('nvim-treesitter.parsers')
nts_query = require('nvim-treesitter.query')
ts_utils = require('nvim-treesitter.ts_utils')
tablex = require('pl.tablex')
playground = require('nvim-treesitter-playground.printer')

local py_bufnr = 1
local function pr(t)
	print(vim.inspect(t))
end
local function p_node(t)
	print(ts_utils.get_node_text(t)[1])
end
local parser = vim.treesitter.get_parser(py_bufnr, 'python')
tstree = parser:parse()
local root_node = tstree:root()
query = ts_query.get_query('python', 'locals')


local TSDefinitionTree = {}
-- An __index on a metatable overloads dot lookups
TSDefinitionTree.__index = TSDefinitionTree

function TSDefinitionTree.new(unused_arg)
	return setmetatable({ 
		root = nil,
	}, TSDefinitionTree)
end

local TSDefinition = {}
TSDefinition.__index = TSDefinition

-- Contains definition and/or scope information.
-- At least one of `def` or `scope` must be populated.
-- @param def {definition_name, definition_node}
-- @param scope {scope_name, scope_node}
function TSDefinition.new(def, scope)
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
	}, TSDefinition)
end


-- Checks if this 
function TSDefinition:is_this_my_parent(node)

end

-- Iterates over the captures in a match to find defintion
-- or scope captures.
-- @param match Match value as returned by `query:iter_matches(...)`
local function get_definitions_and_scopes(match)
	local defs = {}
	local scopes = {}

	for id, node in pairs(match) do
		local capture_name = query.captures[id]
		--print(capture_name)
		--p_node(node)
		if string.match(capture_name, 'definition') then
			table.insert(defs, {capture_name, node})
		end
		if string.match(capture_name, 'scope') then
			table.insert(scopes, {capture_name, node})
		end
	end
	return defs, scopes
end

local scopes_to_tsdef = {}
local defs_to_tsdef = {}
local defs = {}
all_defs = {}
for pattern, match in query:iter_matches(tstree:root(), py_bufnr, 0, -1) do
	--NB: Currently twe assume there's only a single definition that lives in the same match as a scope.  If this assumption is violated, please send @ElPIloto an example.
	defs, scopes = get_definitions_and_scopes(match)
	if #scopes + #defs > 0 then
		ts_def = TSDefinition.new(defs, scopes)
		table.insert(all_defs, ts_def)
		if #scopes > 0 then
			scopes_to_tsdef[scopes[1][2]:id()] = ts_def
		end
		if #defs > 0 then
			defs_to_tsdef[defs[1][2]:id()] = ts_def
		end
	end
end

local function find_parent(tsdef)
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

local root_tsdef = nil
for _, tsdef in pairs(all_defs) do
	--pr(tsdef)
	local parent, found_parent = find_parent(tsdef)
	if found_parent then
		local containing_tsdef = scopes_to_tsdef[parent:id()]
		table.insert(containing_tsdef.children, tsdef)
		tsdef.parent = containing_tsdef
	else
		root_tsdef = tsdef
	end
end

-- TODO (elpiloto): Hang this on TSDefinition
function format_definition(tsdef)
	return '[' .. ts_utils.get_node_text(tsdef.definition_node)[1] .. '] ' .. tsdef.definition_type
end


-- Dict: key = definition_type, value = list of definition identifiers
local highlights_by_deftypes = {}

-- Builds objects needed for an outline.
-- @param tsdef current_tsdef being processed
function build_outline(tsdef, indent, str, ranges)
	if tsdef.definition_node then
		local def_text = ts_utils.get_node_text(tsdef.definition_node)[1]
		local def_type = tsdef.definition_type
		if not highlights_by_deftypes[def_type] then
			highlights_by_deftypes[def_type] = {def_text}
		else
			table.insert(highlights_by_deftypes[def_type], def_text)
		end
		local start_row, start_col, end_row, end_col = tsdef.definition_node:range()
		table.insert(str, indent .. format_definition(tsdef))
		table.insert(ranges, {indent .. format_definition(tsdef), start_row, start_col, end_row, end_col})
		indent = indent .. '  '
	end
	if tsdef.children then
		for _, child in pairs(tsdef.children) do
			build_outline(child, indent, str, ranges)
		end
	end
	return ranges
end

for _, l in pairs(build_outline(root_tsdef, '', {}, {})) do
	print(l[1])
end

local function set_highight(bufnr, syntax_groups, highlight_links)
	local function syntax_and_highlight()
		print(vim.api.nvim_get_current_buf())
		vim.cmd('syntax enable')
		for _, sg in ipairs(syntax_groups) do
			print(sg)
			vim.cmd(':' .. sg)
		end
		for _, hl in ipairs(highlight_links) do
			vim.cmd(':' .. hl)
			print(hl)
		end
	end
	vim.api.nvim_buf_call(bufnr, syntax_and_highlight)
end
local syntax_groups = {}
local highlight_links = {}
for def_type, def_type_defs in pairs(highlights_by_deftypes) do
	-- Create syntax group called sidekick$sanitize(def_type)
	local str = "sidekick" .. def_type:gsub("\\.", "_")
	local syntax_group = "syntax keyword  " .. str .. " " ..  table.concat(def_type_defs, " ")
	table.insert(syntax_groups, syntax_group)

	-- Associate that syntax group with existing types
	-- TODO (elpiloto): Make "Keyword" configurable.
	local highlight_link = "highlight default link " .. str .. " Keyword"
	table.insert(highlight_links, highlight_link)
end
set_highight(10, syntax_groups, highlight_links)
