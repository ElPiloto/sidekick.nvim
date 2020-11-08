--TODO(elpiloto): Using functions inside vim lua module e.g. for splitting strings or counting elements.
ts_query = require 'vim.treesitter.query'
nts_locals = require('nvim-treesitter.locals')
nts_parsers = require('nvim-treesitter.parsers')
nts_query = require('nvim-treesitter.query')
ts_utils = require('nvim-treesitter.ts_utils')
tablex = require('pl.tablex')

local function recursive_print(current_defs, indent, parents_to_defs, ids_to_nodes)
	print('hmmmmm')
	print(vim.inspect(parents_to_defs))
	for _, n_id in pairs(current_defs) do
		local node = ids_to_nodes[n_id]
		print(indent .. ts_utils.get_node_text(node)[1])
		if parents_to_defs[n_id] then
			recursive_print(parents_to_defs[n_id], indent + ' ', parents_to_defs, ids_to_nodes)
		end
	end
end
Stack = {}

-- Create a Table with stack functions
function Stack:new()

	-- stack table
	local t = {}
	-- entry table
	t._et = {}

	-- push a value on to the stack
	function t:push(...)
		if ... then
			local targs = {...}
			-- add values
			for _,v in ipairs(targs) do
				table.insert(self._et, v)
			end
		end
	end

	-- pop a value from the stack
	function t:pop(num)

		-- get num values from stack
		local num = num or 1

		-- return table
		local entries = {}

		-- get values into entries
		for i = 1, num do
			-- get last entry
			if #self._et ~= 0 then
				table.insert(entries, self._et[#self._et])
				-- remove last value
				table.remove(self._et)
			else
				break
			end
		end
		-- return unpacked entries
		return unpack(entries)
	end

	-- get entries
	function t:getn()
		return #self._et
	end

	-- list values
	function t:list()
		for i,v in pairs(self._et) do
			print(i, v)
		end
	end
	return t
end





local function print_node(node)
	print(ts_utils.get_node_text(node)[1], node:type())
end

local function linesStrToTable(str)
	lines = {}
	for s in str:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	return lines
end
local function getSidekickTextOld()
str = [[
         _____ _     __     __ __ _      __  
        / ___/(_)___/ /__  / //_/(_)____/ /__
        \__ \/ / __  / _ \/ ,<  / / ___/ //_/
       ___/ / / /_/ /  __/ /| |/ / /__/ ,<   
      /____/_/\__,_/\___/_/ |_/_/\___/_/|_|  
      =======================================

	   

                                     &&&&&(%%      
                                  &&&        #%%   
                                 &&            %%  
                                 &&             %% 
                                 &&&           &&  
                                   &&&&     &&&%   
                                        @&         
                                       &&          
                                    (&%&@@         
                        &&&&&&&&&@&&&  & @@        
                                      &&  &&       
                                      @& &&%       
                                     %@&           
                                     @&            
          %&@&&&&&&&&@@&&&@@@@&@@ @@@@&            
&&@&&&%%#/                 @@@@@                   
                         @&#                         
	         					                  
			          			                  
					    	                  
]]
lines = {}
num_lines = 0
for s in str:gmatch("[^\r\n]+") do
    table.insert(lines, s)
	num_lines = num_lines + 1
end
return lines, num_lines
end

local function getSidekickText()
header = [[
   
   _____ _     __     __ __ _      __   
  / ___/(_)___/ /__  / //_/(_)____/ /__ 
  \__ \/ / __  / _ \/ ,<  / / ___/ //_/ 
 ___/ / / /_/ /  __/ /| |/ / /__/ ,<    
/____/_/\__,_/\___/_/ |_/_/\___/_/|_|   
=======================================
 
	 
]]
lines = {}
num_lines = 0
for s in header:gmatch("[^\r\n]+") do
    table.insert(lines, s)
	num_lines = num_lines + 1
end
header_and_dude = [[
         ..      
        :  :     _____ _     __     __ __ _      __   
         ``     / ___/(_)___/ /__  / //_/(_)____/ /__ 
      \__|      \__ \/ / __  / _ \/ ,<  / / ___/ //_/ 
        _| >   ___/ / / /_/ /  __/ /| |/ / /__/ ,<    
o________/    /____/_/\__,_/\___/_/ |_/_/\___/_/|_|   
    o___/     =======================================
 
	 
]]
header_and_poof = [[
                
   .( * .        _____ _     __     __ __ _      __   
 .*  .  ) .     / ___/(_)___/ /__  / //_/(_)____/ /__ 
. . POOF .* .   \__ \/ / __  / _ \/ ,<  / / ___/ //_/ 
 '* . (  .) '  ___/ / / /_/ /  __/ /| |/ / /__/ ,<    
  ` ( . *     /____/_/\__,_/\___/_/ |_/_/\___/_/|_|   
              =======================================
	 
]]
return linesStrToTable(header), linesStrToTable(header_and_dude), linesStrToTable(header_and_poof)
end

local function getQueries()
str = '(comparison_operator (identifier) @myifarg (string) @sweep_name (#eq? @myifarg "sweep_id"))'
str = [[
;;; Programm structure
(module) @scope

(class_definition
  body: (block
          (expression_statement
            (assignment
              left: (expression_list
                      (identifier) @definition.associated))))) @scope

; Imports
(aliased_import
  alias: (identifier) @definition.import)
(import_statement
  name: (dotted_name ((identifier) @definition.import)))
(import_from_statement
  name: (dotted_name ((identifier) @definition.import)))

; Function with parameters, defines parameters
(parameters
  (identifier) @definition.parameter)

(default_parameter
  (identifier) @definition.parameter)

(typed_parameter
  (identifier) @definition.parameter)

(typed_default_parameter
  (identifier) @definition.parameter)

(with_statement
  (with_item
    alias: (identifier) @definition.var))

; *args parameter
(parameters
  (list_splat
    (identifier) @definition.parameter))

; **kwargs parameter
(parameters
  (dictionary_splat
    (identifier) @definition.parameter))

; Function defines function and scope
((function_definition
  name: (identifier) @definition.function) @scope
 (#set! definition.function.scope "parent"))


((class_definition
  name: (identifier) @definition.type) @scope
 (#set! definition.type.scope "parent"))

(class_definition
  body: (block
          (function_definition
            name: (identifier) @definition.method)))

;;; Loops
; not a scope!
(for_statement
  left: (variables
          (identifier) @definition.var))

; not a scope!
;(while_statement) @scope

; for in list comprehension
(for_in_clause
  left: (variables
          (identifier) @definition.var))

(dictionary_comprehension) @scope
(list_comprehension) @scope
(set_comprehension) @scope

;;; Assignments

(left_hand_side
 (identifier) @definition.var)

(left_hand_side
 (attribute
  (identifier)
  (identifier) @definition.field))

; Walrus operator  x := 1
(named_expression
  (identifier) @definition.var)


;;; REFERENCES
(identifier) @reference

(assignment
  left: (left_hand_side (identifier) @plan_variable)
  right: (expression_list (dictionary
  (pair
    key: (string) @definition.component_name
    value: [
    (dictionary)
    (call
      function: (attribute) @da
    )
    (call
      function: (identifier) @di
    )
    ])
  ))
  (#eq? @plan_variable "plan")
)

(comparison_operator) @equalsmaybe

(comparison_operator
  (identifier) @myifarg
  (string) @definition.sweep_name
  (#eq? @myifarg "sweep_id")
)
]]
return str
end

local function getAllData(t, prevData)
  -- if prevData == nil, start empty, otherwise start with prevData
  local data = prevData or {}

  -- copy all the attributes from t
  for k,v in pairs(t) do
	  -- data[k] = data[k] or v
	  print(k, data[k] or v)
  end

  -- get t's metatable, or exit if not existing
  local mt = getmetatable(t)
  if type(mt)~='table' then return data end

  -- get the __index from mt, or exit if not table
  local index = mt.__index
  if type(index)~='table' then return data end

  -- include the data from index into data, recursively, and return
  return getAllData(index, data)
end

local function animateBufferOpen(win, header, matches, poof)
	-- Smoothly expand window width, contract a bit, and then expand to final size.
	final_width=40
	widths = {60, 50, 52}
	speeds = {100, 200, 200}
	prev_w = 1
	for i, target_w in pairs(widths) do
		speed = speeds[i]
		if target_w > prev_w then
			step_dir = 1
		else
			step_dir = -1
		end
		-- Gradually modify our width to target width
		for i = prev_w, target_w, step_dir do
			new_width_fn = function()
				vim.api.nvim_win_set_width(win, i)
				-- Need this for smooth animation.
				vim.api.nvim_command('redraw')
			end
			vim.defer_fn(new_width_fn, speed)
		end
		prev_w = target_w
	end
	-- finally after all that has been done, let's set the final text
	if poof then
		print('poofing')
		final_text_fn = function()
			-- Display matches
			vim.api.nvim_buf_set_option(buf, 'modifiable', true)
			vim.api.nvim_buf_set_lines(buf, 0, #poof, false, poof)
			-- Apparently this needs to be set after we insert text.
			vim.api.nvim_buf_set_option(buf, 'modifiable', false)
		end
		vim.defer_fn(final_text_fn, speed*6)
	end
	-- finally after all that has been done, let's set the final text
	final_text_fn = function()
		-- Display matches
		vim.api.nvim_buf_set_option(buf, 'modifiable', true)
		vim.api.nvim_buf_set_lines(buf, 0, #header, false, header)
		vim.api.nvim_buf_set_lines(buf, #header, #header+#matches, false, matches)
		-- Apparently this needs to be set after we insert text.
		vim.api.nvim_buf_set_option(buf, 'modifiable', false)
		vim.api.nvim_win_set_width(win, final_width)
		-- Need this for smooth animation.
		vim.api.nvim_command('redraw')
	end
	vim.defer_fn(final_text_fn, speed*12)
end

local function openNewBuffer(doKick, matches)
	-- Make new window and move into it.
	win_name = 'Sidekick'
	vim.api.nvim_command('keepalt botright vertical 1 split ' .. win_name)
	win = vim.api.nvim_get_current_win()
	buf = vim.api.nvim_get_current_buf()

	--Disable wrapping
	vim.api.nvim_win_set_option(win, 'wrap', false)
	vim.api.nvim_win_set_option(win, 'list', false)
	vim.api.nvim_win_set_option(win, 'number', false)
	vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
	vim.api.nvim_buf_set_option(buf, 'swapfile', false)
	vim.api.nvim_command('hi NonText guifg=bg')
	
	-- Display some ascii art text
	header, header_and_dude, header_and_poof = getSidekickText()
	vim.api.nvim_buf_set_option(buf, 'modifiable', true)
	vim.api.nvim_buf_set_lines(buf, 0, #header_and_dude, false, header_and_dude)

	-- Apparently this needs to be set after we insert text.
	vim.api.nvim_buf_set_option(buf, 'modifiable', false)


	if doKick then
		animateBufferOpen(win, header, matches, header_and_poof)
	end
	return buf, win
end

local function query()
  -- check out this file: https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/query.lua
  -- the second argument is on the argument below
  --q = ts_query.get_query('python', 'locals')
  --q = ts_query.parse_query('python', '(identifier) @someVar')
  local q = ts_query.parse_query('python', getQueries())
  print(vim.inspect(tree))
  for cid, node in q:iter_captures(tree:root(), buf, 0, #lines) do
	  local name = q.captures[cid] -- name of the capture in the query
	  -- typically useful info about the node:
	  local type = node:type() -- type of the captured node
	  local row1, col1, row2, col2 = node:range() -- range of the capture
	  print(name, type, row1)
  end

end

local function prepare_match(entry, kind)
  local entries = {}

  if entry.node then
      entry["kind"] = kind
      table.insert(entries, entry)
  else
    for name, item in pairs(entry) do
        vim.list_extend(entries, prepare_match(item, name))
    end
  end

  return entries
end

local function custom_tags()
	-- Gets tags defined via queries/${language}/custom_tags.scm
	-- Only displays matches with "sidekick" in name e.g. @function.sidekick
	local processed_matches = {}
	for _, match in pairs(nts_query.get_matches(0, 'custom_tags')) do
		if match.sidekick then
			local entries = prepare_match(match.sidekick)
			for t, entry in ipairs(entries) do
				local kind = entry.kind
				-- TODO(elpiloto): Unclear if getting first value is sufficient.
				local node_text = ts_utils.get_node_text(entry.node)[1]
				local start_line, start_col, end_line, end_col = ts_utils.get_node_range(entry.node)
				-- For some reason, we need to add 1 to this.
				start_line = start_line + 1
				local str = start_line .. ': ' .. '[' .. kind .. '] ' .. node_text
				table.insert(processed_matches, str)
			end
		end
	end
	print(vim.inspect(processed_matches))
	return processed_matches
end

local function get_ts_definitions()
	-- Gets tags defined via queries/${language}/custom_tags.scm
	-- Only displays matches with "sidekick" in name e.g. @function.sidekick
	local processed_matches = {}
	for pattern, match in pairs(nts_query.get_matches(0, 'locals')) do
		--print(pattern, vim.inspect(match))
		if match.definition and match.scope then
			local entries = prepare_match(match.definition)
			local prepped_match = prepare_match(match)
			print('\\\\\\\\NOT PREPPED\\\\\\\\\\')
			print(vim.inspect(match))
			print('0000000PREPPED00000000')
			print(vim.inspect(prepped_match))
			print('++++++++++++++++++++++++++++++')
			print(vim.inspect(entries))
			print('////////////ENTRIES\\\\\\\\\\')
			--print(vim.inspect(entries))
			for t, entry in ipairs(entries) do
				local kind = entry.kind
				-- TODO(elpiloto): Unclear if getting first value is sufficient.
				local node_text = ts_utils.get_node_text(entry.node)[1]
				local start_line, start_col, end_line, end_col = ts_utils.get_node_range(entry.node)
				-- For some reason, we need to add 1 to this.
				start_line = start_line + 1
				local str = start_line .. ': ' .. '[' .. kind .. '] ' .. node_text
				--print(str, _, '__________________')
				--if entry.scope then
					--local scope = nts_locals.containing_scope(entry.node)
					--local loops = 1
					--while !scope.definition do
						--scope = nts_locals.containing_scope(scope)
					--end
					--print(scope['function'])
					--print(vim.inspect(ts_utils.get_node_text(scope)))
					--print(scope.definition)
					--local scope_definition = nts_locals.find_definition(scope)
					--print(scope_definition)
					--local scope_text = ts_utils.get_node_text(definition.scope.node)[1]
					--if definition.scope.node.definition then
						--print('nutz')
					--end
					--str = str .. ' - @' .. scope_text
				--end
				table.insert(processed_matches, str)
			end
		end
	end
	--print(vim.inspect(nts_query.get_capture_matches(0, '@definition', 'locals')))
	return processed_matches
end

local function scopes()
	-- Gets tags defined via queries/${language}/custom_tags.scm
	-- Only displays matches with "sidekick" in name e.g. @function.sidekick
    local parser = vim.treesitter.get_parser(0, 'python')
    tstree = parser:parse()
	local root_node = tstree:root()
	local processed_matches = {}
	local scopes = {}
	print(vim.inspect(nts_locals.get_scopes(0)))
	--for t, m in pairs(nts_query.get_capture_matches(0, '@scope', 'locals')) do
		--if scopes[m.node] ~= nil then
			--scopes[m.node] = {}
		--end
		----if m.definition.scope then
			----print(vim.inspect(m.scope))
		----end
		--print(t, vim.inspect(m.node))
		----print(vim.inspect(
	--end
	return {}
	--for _, matches in pairs(nts_query.get_matches(0, 'locals')) do
		--if matches.scope then 
			---- This has definition{ function{ node}}, scope { node}
			----print(vim.inspect(matches))
			--if matches.definition then
				--def_node = matches.definition['function'].node
				----print(def_node:named(), def_node:symbol(), def_node:type())
				--print(vim.inspect(matches.definition['function']))
			--end
			----print(vim.inspect(matches.node))
			----print(ts_utils.get_node_text(matches.node))
			----print(matches.node.kind)
		--end
	--end
		--if definition.definition then
			--local entries = prepare_match(definition.definition)
			----print(vim.inspect(definition))
			--for t, entry in ipairs(entries) do
				--local kind = entry.kind
				---- TODO(elpiloto): Unclear if getting first value is sufficient.
				--local node_text = ts_utils.get_node_text(entry.node)[1]
				--local start_line, start_col, end_line, end_col = ts_utils.get_node_range(entry.node)
				---- For some reason, we need to add 1 to this.
				--start_line = start_line + 1
				--local str = start_line .. ': ' .. '[' .. kind .. '] ' .. node_text
				--if entry.scope then
					--local scope = nts_locals.containing_scope(entry.node)
				--end
				--table.insert(processed_matches, str)
			--end
		--end
	--end
	--return processed_matches
	--return {}
end

local function scopes2()
	-- Gets tags defined via queries/${language}/custom_tags.scm
	-- Only displays matches with "sidekick" in name e.g. @function.sidekick
  	local q = ts_query.get_query('python', 'locals')
    local parser = vim.treesitter.get_parser(0, 'python')
    local tstree = parser:parse()
	local root_node = tstree:root()
	-- This gives us all the different types of captures in the .scm file.
	--print(vim.inspect(q.captures))
	--for cid, node in q:iter_captures(tstree:root(), 0, 0, 2000) do
		--if q.captures[cid] ~= 'reference' then
			--print(q.captures[cid], ts_utils.get_node_text(node)[1])
		--end
	--end
	print(vim.inspect(q.info))
	-- Pattern is a unique identifier
	for pattern, match in q:iter_matches(tstree:root(), 0, 0, 2000) do
		for cid, node in pairs(match) do
			if q.captures[cid] ~= 'reference' then
				print(pattern, q.captures[cid], ts_utils.get_node_text(node)[1])
			end
		end
	end
	return {}
end

local function get_scopes_older()
	-- Gets tags defined via queries/${language}/custom_tags.scm
	-- Only displays matches with "sidekick" in name e.g. @function.sidekick
	local q = ts_query.get_query('python', 'locals')
	local parser = vim.treesitter.get_parser(0, 'python')
	local tstree = parser:parse()
	local root_node = tstree:root()
	-- This gives us all the different types of captures in the .scm file.
	--print(vim.inspect(q.info))
	local all_scopes = {}
	local scope_tree = {}
	local all_scope_nodes = {}
	local all_defs = {}
	local def_tree = {}
	local all_def_nodes = {}
	for cid, node in q:iter_captures(tstree:root(), 0, 0, 2000) do
		--if string.match(q.captures[cid], 'definition') then
		if string.match(q.captures[cid], 'scope') then
			-- TODO(elpiloto): Use full range, right now just getting first letter
			--print(testing .. 'woohoo')
			local node_key = node:type() .. node:range() .. ts_utils.get_node_text(node)[1]
			--all_scopes[node] = {node:type(), node:range(), ts_utils.get_node_text(node)[1]}
			all_scopes[node_key] = node
			scope_tree[node_key] = {}
			all_scope_nodes[node] = {}
		end
		if string.match(q.captures[cid], 'definition') then
			-- TODO(elpiloto): Use full range, right now just getting first letter
			--print(testing .. 'woohoo')
			local node_key = node:type() .. node:range() .. ts_utils.get_node_text(node)[1]
			--all_scopes[node] = {node:type(), node:range(), ts_utils.get_node_text(node)[1]}
			all_defs[node_key] = node
			def_tree[node_key] = {}
			all_def_nodes[node] = {}
		end
	end
	--print(vim.inspect(all_scopes[last_inserted_node]))
	-- TODO(elpiloto): Can make this quicker by checking if the scope we're in has already been added to 
	--  ACTUALLY, above may not be a speed up. May just be a correctness requirement, we should probably break after we've found a parent.
	local num_parents_checked = 0
	local scopes_to_parents = {}
	local parents_to_scopes = {}
	for scope, _ in pairs(all_scope_nodes) do
		local scope_key = scope:type() .. scope:range() .. ts_utils.get_node_text(scope)[1]
		scopes_to_parents[scope] = {}
		local node = scope:parent()
		while node do
			local node_key = node:type() .. node:range() .. ts_utils.get_node_text(node)[1]
			if all_scopes[node_key] then
				table.insert(scopes_to_parents[scope], node)
				--table.insert(scopes_to_parents[scope], node_key)
				if parents_to_scopes[node] == nil then
					parents_to_scopes[node] = {}
				end
				--table.insert(parents_to_scopes[node], scope_key)
				table.insert(parents_to_scopes[node], scope)
			end
			node = node:parent()
		end
	end
	print(vim.inspect(scopes_to_parents))
	print(vim.inspect(parents_to_scopes))
	--local defs = nts_locals.get_definitions(0)
	--local scopes = nts_locals.get_scope_tree(tstree:root(), 0)
	--for i, m in pairs(defs) do
		---- j is something like function
		--if m['function'] then
			--func = m['function']
			----print(func.node:type(), func['scope'])
			--local fn_name = vim.inspect(ts_utils.get_node_text(func.node))
			--local scope_type = func['scope'] -- ends up being parent or global
			----print(nts_locals.get_definition_scopes(func.node, 0, scope_type))
			--local parent = func.node:parent()
			--print(i)
			----local parent_scope = nts_locals.get_scope_tree(func.node, 0)
			----print(vim.inspect(parent_scope))

		--end
	--end

	----local def_table = nts_locals.get_definitions_lookup_table(0)
	--print(vim.inspect(defs))
	
	return {}
end


local function get_scopes()
	-- Gets tags defined via queries/${language}/custom_tags.scm
	local q = ts_query.get_query('python', 'locals')
	local parser = vim.treesitter.get_parser(nil, 'python')
	local tstree = parser:parse()
	local root_node = tstree:root()
	local start_line, _, end_line, _ = root_node:range()

	local all_scopes = {}
	local scope_tree = {}
	local all_scope_nodes = {}
	local all_defs = {}
	local def_tree = {}
	local all_def_nodes = {}
	for cid, node in q:iter_captures(tstree:root(), bufnr, start_line, end_line) do
		if string.match(q.captures[cid], 'scope') then
			all_scopes[node_key] = true
			scope_tree[node_key] = {}
			all_scope_nodes[node] = {}
		end
		if string.match(q.captures[cid], 'definition') then
			all_defs[node_key] = node
			def_tree[node_key] = {}
			all_def_nodes[node] = {}
		end
	end

	local scopes_to_parents = {}
	local parents_to_scopes = {}
	local top_scope_node = {}
	for scope, _ in pairs(all_scope_nodes) do
		local scope_key = scope:type() .. scope:range() .. ts_utils.get_node_text(scope)[1]
		scopes_to_parents[scope] = {}
		local node = scope:parent()
		local has_parent = false
		while node do
			has_parent = true
			local node_key = node:type() .. node:range() .. ts_utils.get_node_text(node)[1]
			if all_scopes[node_key] then
				table.insert(scopes_to_parents[scope], node)
				--table.insert(scopes_to_parents[scope], node_key)
				if parents_to_scopes[node] == nil then
					parents_to_scopes[node] = {}
				end
				--table.insert(parents_to_scopes[node], scope_key)
				table.insert(parents_to_scopes[node], scope)
			end
			node = node:parent()
		end
		if has_parent == false then
			top_scope_node = scope
		end
	end
	local defs_to_parents = {}
	local parents_to_defs = {}
	local top_def_node = {}
	for def, _ in pairs(all_def_nodes) do
		local def_key = def:type() .. def:range() .. ts_utils.get_node_text(def)[1]
		defs_to_parents[def] = {}
		local node = def:parent()
		local has_parent = false
		local found_parent = false
		while node and found_parent == false do
			has_parent = true
			local node_key = node:type() .. node:range() .. ts_utils.get_node_text(node)[1]
			if all_scopes[node_key] then
				found_parent = true
				table.insert(defs_to_parents[def], node)
				--table.insert(scopes_to_parents[scope], node_key)
				if parents_to_defs[node] == nil then
					parents_to_defs[node] = {}
				end
				--table.insert(parents_to_scopes[node], scope_key)
				table.insert(parents_to_defs[node], def)
			end
			node = node:parent()
		end
		if has_parent == false then
			top_def_node = def
		end
	end
	print(vim.inspect(defs_to_parents))
	print(vim.inspect(parents_to_defs))
	--print(vim.inspect(all_defs))
	local has_printed = {}
	for scope, def_list in pairs(parents_to_defs) do
		if has_printed[scope] == nil then
			if scope == top_scope_node then
				print('ROOT')
			else
				print(ts_utils.get_node_text(scope)[1])
			end
			has_printed[scope] = true
		end
		for _, def in ipairs(def_list) do
			if has_printed[def] == nil then
				print('      *', ts_utils.get_node_text(def)[1])
				has_printed[def] = true
			end
		end
	end

	print('traversing scopes')
	local to_recurse = {top_scope_node}
	all_lines = {}
	for _, n in pairs(to_recurse) do
		--print(ts_utils.get_node_text(n)[1])
		for _, d in pairs(parents_to_defs[n]) do
			print(ts_utils.get_node_text(d)[1])
		end
		
	end
	
	return {}
end

local function get_scopes_working_almost()
	-- Gets tags defined via queries/${language}/custom_tags.scm
	local q = ts_query.get_query('python', 'locals')
	local parser = vim.treesitter.get_parser(0, 'python')
	local tstree = parser:parse()
	local root_node = tstree:root()

	local all_scopes = {}
	local all_scope_nodes = {}

	local all_defs = {}
	local all_def_nodes = {}

	for cid, node in q:iter_captures(tstree:root(), 0, 0, 2000) do
		if string.match(q.captures[cid], 'scope') then
			all_scopes[node] = node
			all_scope_nodes[node] = true
		end
		if string.match(q.captures[cid], 'definition') then
			all_defs[node] = node
			all_def_nodes[node] = true
		end
	end

	local scopes_to_parents = {}
	local parents_to_scopes = {}
	local top_scope_node = {}
	for scope, _ in pairs(all_scope_nodes) do
		--local scope_key = scope:type() .. scope:range() .. ts_utils.get_node_text(scope)[1]
		print('__________I AM A PARENT______')
		print_node(scope)
		print('_____________________________')
		scopes_to_parents[scope] = {}
		local node = scope:parent()
		local has_parent = false
		while node do
			print('__________I AM A PARENT______')
			print_node(node)
			print('_____________________________')
			for other_nodes, _ in pairs(all_scope_nodes) do
				print('..............................')
				print_node(other_nodes)
				print(node:symbol(), node.id)
				if other_nodes == node then
					print('WE DID IT !!!!!!!!!!!!! ==================>>>>')
					print(all_scopes[other_nodes], all_scopes[node])
					print('WE DID IT !!!!!!!!!!!!! ==================>>>>')
					print(node:range())
				end
			end
			print('\n\n')
			has_parent = true
			if all_scopes[node] ~= nil then
				print('WE DID IT !!!!!!!!!!!!! ==================>>>>')
				table.insert(scopes_to_parents[scope], node)
				if parents_to_scopes[node] == nil then
					parents_to_scopes[node] = {}
				end
				table.insert(parents_to_scopes[node], scope)
			end
			node = node:parent()
		end
		if has_parent == false then
			top_scope_node = scope
		end
	end
	print(vim.inspect(scopes_to_parents))
	print(vim.inspect(parents_to_scopes))
	--local defs_to_parents = {}
	--local parents_to_defs = {}
	--local top_def_node = {}
	--for def, _ in pairs(all_def_nodes) do
		--local def_key = def:type() .. def:range() .. ts_utils.get_node_text(def)[1]
		--defs_to_parents[def] = {}
		--local node = def:parent()
		--local has_parent = false
		--local found_parent = false
		--while node and found_parent == false do
			--has_parent = true
			--local node_key = node:type() .. node:range() .. ts_utils.get_node_text(node)[1]
			--if all_scopes[node_key] then
				--found_parent = true
				--table.insert(defs_to_parents[def], node)
				----table.insert(scopes_to_parents[scope], node_key)
				--if parents_to_defs[node] == nil then
					--parents_to_defs[node] = {}
				--end
				--table.insert(parents_to_defs[node], def)
			--end
			--node = node:parent()
		--end
		--if has_parent == false then
			--top_def_node = def
		--end
	--end
	--print(vim.inspect(defs_to_parents))
	--print(vim.inspect(parents_to_defs))

	--local has_printed = {}
	--for scope, def_list in pairs(parents_to_defs) do
		--if has_printed[scope] == nil then
			--if scope == top_scope_node then
				--print('ROOT')
			--else
				--print(ts_utils.get_node_text(scope)[1])
			--end
			--has_printed[scope] = true
		--end
		--for _, def in ipairs(def_list) do
			--if has_printed[def] == nil then
				--print('      *', ts_utils.get_node_text(def)[1])
				--has_printed[def] = true
			--end
		--end
	--end

	--print('traversing scopes')
	--local to_recurse = {top_scope_node}
	--all_lines = {}
	--for _, n in pairs(to_recurse) do
		----print(ts_utils.get_node_text(n)[1])
		--for _, d in pairs(parents_to_defs[n]) do
			--print(ts_utils.get_node_text(d)[1])
		--end
		
	--end
	
	return {}
end

--@public
--- Returns an unique node id based on node range and type.
---
local function get_node_id(node)
	--TODO(elpiloto): Eventually replace this with node.id from neovim.
    return node:type() .. table.concat({node:range()}, "_")
end

--@private
--- Constructs a scope tree.
local function get_scopes()
	-- Gets tags defined via queries/${language}/custom_tags.scm
	local bufnr = vim.api.nvim_get_current_buf()
	print(bufnr)
	local lang = nts_parsers.get_buf_lang(bufnr)
	if not lang then return function() end end
	local q = ts_query.get_query('python', 'locals')
	local parser = vim.treesitter.get_parser(bufnr, 'python')
	local tstree = parser:parse()
	local root_node = tstree:root()
	local start_line, _, end_line, _ = root_node:range()

	local all_scopes = {}
	local scope_tree = {}
	local all_scope_nodes = {}
	local all_defs = {}
	local def_tree = {}
	local all_def_nodes = {}
	for cid, node in q:iter_captures(tstree:root(), bufnr, start_line, end_line) do
		local node_key = node:id()
		if string.match(q.captures[cid], 'scope') then
			local contain_scope = nts_locals.containing_scope(node)
			print(ts_utils.get_node_text(contain_scope)[1], 'CONTAINS', ts_utils.get_node_text(node)[1])
			all_scopes[node_key] = true
			scope_tree[node_key] = {}
			all_scope_nodes[node] = {}
		end
		if string.match(q.captures[cid], 'definition') then
			local contain_scope = nts_locals.containing_scope(node)
			print(ts_utils.get_node_text(contain_scope)[1], 'CONTAINS', ts_utils.get_node_text(node)[1])
			all_defs[node_key] = node
			def_tree[node_key] = {}
			all_def_nodes[node] = {}
		end
	end

	local scopes_to_parents = {}
	local parents_to_scopes = {}
	local top_scope_node = {}
	for scope, _ in pairs(all_scope_nodes) do
		--local scope_key = scope:type() .. scope:range() .. ts_utils.get_node_text(scope)[1]
		local scope_key = scope:id()
		scopes_to_parents[scope] = {}
		local node = scope:parent()
		local has_parent = false
		while node do
			has_parent = true
			--local node_key = node:type() .. node:range() .. ts_utils.get_node_text(node)[1]
			local node_key = node:id()
			if all_scopes[node_key] then
				table.insert(scopes_to_parents[scope], node)
				--table.insert(scopes_to_parents[scope], node_key)
				if parents_to_scopes[node] == nil then
					parents_to_scopes[node] = {}
				end
				--table.insert(parents_to_scopes[node], scope_key)
				table.insert(parents_to_scopes[node], scope)
			end
			node = node:parent()
		end
		if has_parent == false then
			top_scope_node = scope
		end
	end
	local defs_to_parents = {}
	local parents_to_defs = {}
	local top_def_node = {}
	for def, _ in pairs(all_def_nodes) do
		local def_key = def:type() .. def:range() .. ts_utils.get_node_text(def)[1]
		defs_to_parents[def] = {}
		local node = def:parent()
		local has_parent = false
		local found_parent = false
		while node and found_parent == false do
			has_parent = true
			local node_key = node:type() .. node:range() .. ts_utils.get_node_text(node)[1]
			if all_scopes[node_key] then
				found_parent = true
				table.insert(defs_to_parents[def], node)
				--table.insert(scopes_to_parents[scope], node_key)
				if parents_to_defs[node] == nil then
					parents_to_defs[node] = {}
				end
				--table.insert(parents_to_scopes[node], scope_key)
				table.insert(parents_to_defs[node], def)
			end
			node = node:parent()
		end
		if has_parent == false then
			top_def_node = def
		end
	end
	print(vim.inspect(defs_to_parents))
	print(vim.inspect(parents_to_defs))
	--print(vim.inspect(all_defs))
	local has_printed = {}
	for scope, def_list in pairs(parents_to_defs) do
		if has_printed[scope] == nil then
			if scope == top_scope_node then
				print('ROOT')
			else
				print(ts_utils.get_node_text(scope)[1])
			end
			has_printed[scope] = true
		end
		for _, def in ipairs(def_list) do
			if has_printed[def] == nil then
				print('      *', ts_utils.get_node_text(def)[1])
				has_printed[def] = true
			end
		end
	end

	print('traversing scopes')
	local to_recurse = {top_scope_node}
	all_lines = {}
	for _, n in pairs(to_recurse) do
		--print(ts_utils.get_node_text(n)[1])
		for _, d in pairs(parents_to_defs[n]) do
			print(ts_utils.get_node_text(d)[1])
		end
		
	end
	
	return {}
end

local function get_ts_definitions()
	-- Gets tags defined via queries/${language}/locals.scm
	
	-- Tracks all scopes.
	local ids_to_nodes = {}
	local scopes = {}
	local scoped_defs = {}
	local defs_to_scopes = {}
	local scopes_to_scoped_defs = {}
	local processed_matches = {}
	local scopeless_defs = {}
	for pattern, match in pairs(nts_query.get_matches(0, 'locals')) do
		if match.scope then
			local scope_id = get_node_id(match.scope.node)
			scopes[scope_id] = true
			ids_to_nodes[scope_id] = match.scope.node
		end
		if match.definition then
			-- This flattens from { function = { node  = udata} } to {kind = function, node }
			local entries = prepare_match(match.definition)
			for t, entry in ipairs(entries) do
				local kind = entry.kind
				local def_id = get_node_id(entry.node)
				print(kind)
				local desc = ''
				if match.scope then
					--defs_to_scopes[def_id] = match.scope.node
					scopes_to_scoped_defs[get_node_id(match.scope.node)] = entry.node
					scoped_defs[def_id] = true
				end
				scopeless_defs[def_id] = true
				ids_to_nodes[def_id] = entry.node
				-- TODO(elpiloto): Unclear if getting first value is sufficient.
				local node_text = ts_utils.get_node_text(entry.node)[1]
				local start_line, start_col, end_line, end_col = ts_utils.get_node_range(entry.node)
				-- For some reason, we need to add 1 to this.
				start_line = start_line + 1
				local str = start_line .. ': ' .. '[' .. kind .. '] '  .. node_text .. desc
				table.insert(processed_matches, str)
			end
		end
	end
	for def_id in pairs(scopeless_defs) do
		local def = ids_to_nodes[def_id]
		def = def:parent()
		local found_parent = false
		while def and not found_parent do
			local parent_id = get_node_id(def)
			if scopes[parent_id] then
				defs_to_scopes[def_id] = def
				found_parent = true
			end
			def = def:parent()
		end
	end
	-- Make scope tree.
	local scope_tree = {} --mapping from scope id --> {list_of_child_scopes}
	local top_node = {}
	for scope_id, _ in pairs(scopes) do
		local scope = ids_to_nodes[scope_id]
		local node = scope:parent()
		local has_parent = false
		local found_scope = false
		while node and not found_scope do
			has_parent = true
			local node_id = get_node_id(node)
			if scopes[node_id] then
				if scope_tree[node_id] == nil then
					scope_tree[node_id] = {}
				end
				table.insert(scope_tree[node_id], scope)
				found_scope = true
			end
			node = node:parent()
		end
		if has_parent == false then
			top_scope_node = scope
		end
	end
	processed_matches = {}
	for def_id, scope in pairs(defs_to_scopes) do
		local def = ids_to_nodes[def_id]
	    local str =  ts_utils.get_node_text(def)[1] .. ' under scope ' .. ts_utils.get_node_text(scope)[1]
	    table.insert(processed_matches, str)
	end

	local expand_scopes = Stack:new()
	cur_node_id = get_node_id(top_scope_node)
	local counter = 0
	while cur_node_id and counter < 16 do
		local child_scopes = scope_tree[cur_node_id]
		for _, child_scope in ipairs(child_scopes) do
			local child_scope_id = get_node_id(child_scope)
			local def_scope = scopes_to_scoped_defs[child_scope_id]
			if def_scope then
				print(ts_utils.get_node_text(def_scope)[0])
			end
		end
		cur_node_id = expand_scopes:pop()
		counter = counter + 1
	end
	return processed_matches
end

local function recursive_scopes(node)
	local prev_scope = node
	local contain_scope = nts_locals.containing_scope(prev_scope)

	local indent_level = '--------->'
	local all_nodes = ts_utils.get_node_text(prev_scope)[1]
	--while contain_scope do
	while prev_scope ~= contain_scope do
		all_nodes = all_nodes .. indent_level .. ts_utils.get_node_text(contain_scope)[1] .. '\n'
		prev_scope = contain_scope
		contain_scope = nts_locals.containing_scope(contain_scope)
		indent_level = indent_level .. '------->'
	end
	print('\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\')
	print(all_nodes)
	print('\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\')
	print('================================')
	print(ts_utils.get_node_text(contain_scope)[1], ts_utils.get_node_text(prev_scope)[1])
	print('_____________||||||_____________')
	print(ts_utils.get_node_text(nts_locals.containing_scope(contain_scope))[1])
	print('================================')
end


local function get_ts_definitions()
	-- Gets tags defined via queries/${language}/locals.scm
	
	-- Tracks all scopes.
	local ids_to_nodes = {}
	local parents_to_defs = {}
	local processed_matches = {}
	local scopeless_defs = {}
	local defs = {}
	local top_level_defs = {}
	-- get all defs
	for pattern, match in pairs(nts_query.get_matches(nil, 'locals')) do
		if match.definition then
			-- This flattens from { function = { node  = udata} } to {kind = function, node }
			local entries = prepare_match(match.definition)
			for t, entry in ipairs(entries) do
				print(recursive_scopes(entry.node))
				--local contain_scope = nts_locals.containing_scope(entry.node)
				--print(ts_utils.get_node_text(contain_scope)[1], 'CONTAINS', ts_utils.get_node_text(entry.node)[1])
				local kind = entry.kind
				local def_id = get_node_id(entry.node)
				scopeless_defs[def_id] = true
				ids_to_nodes[def_id] = entry.node
				defs[def_id] = true
			end
		end
	end
	for def_id in pairs(scopeless_defs) do
		local def = ids_to_nodes[def_id]
		local parent_def = def:parent()
		local found_parent = false
		while parent_def and not found_parent do
			local parent_id = get_node_id(parent_def)
			print(def_id .. ' testing against parent ' .. parent_id)
			if defs[parent_id] then
				if parents_to_defs[parent_id] == nil then
					print('resetting ' .. parent_id)
					parents_to_defs[parent_id] = {}
			  	end
				table.extend(parents_to_defs[parent_id], ids_to_nodes[def_id])
				found_parent = true
			end
			parent_def = parent_def:parent()
		end
		if not found_parent then
			table.insert(top_level_defs, def_id)
		end
	end
	print('========scholepess')
	print(vim.inspect(scopeless_defs))
	recursive_print(top_level_defs, '', parents_to_defs, ids_to_nodes)
	for _, n in pairs(top_level_defs) do
		print('We got a  top level node here')
		local node = ids_to_nodes[n]
		print(ts_utils.get_node_text(node)[1])
	end
	return processed_matches
end


local function run()
	local doKick = true
	--processed_matches = custom_tags()
	--processed_matches = get_scopes()
	--processed_matches = scopes2()
	--processed_matches = get_scopes_working_almost()
	print('============')
	processed_matches = get_ts_definitions()
	if doKick then
		buf, win = openNewBuffer(doKick, processed_matches)
	end
end


return {
	run = run
}
