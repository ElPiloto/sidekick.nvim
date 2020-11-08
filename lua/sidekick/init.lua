--TODO(elpiloto): Using functions inside vim lua module e.g. for splitting strings or counting elements.
ts_query = require 'vim.treesitter.query'
nts_locals = require('nvim-treesitter.locals')
nts_parsers = require('nvim-treesitter.parsers')
nts_query = require('nvim-treesitter.query')
ts_utils = require('nvim-treesitter.ts_utils')
sk_outline = require('sidekick.outline')

-- Splits string at new lines into table.
local function split_str(str)
	lines = {}
	for s in str:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	return lines
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
return split_str(header), split_str(header_and_dude), split_str(header_and_poof)
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

local function bufferOpen(win, header, matches)
	-- Smoothly expand window width, contract a bit, and then expand to final size.
	final_width=40
	vim.api.nvim_win_set_width(win, final_width)
	vim.api.nvim_buf_set_option(buf, 'modifiable', true)
	vim.api.nvim_buf_set_lines(buf, 0, #header, false, header)
	vim.api.nvim_buf_set_lines(buf, #header, #header+#matches, false, matches)
	-- Apparently this needs to be set after we insert text.
	vim.api.nvim_buf_set_option(buf, 'modifiable', false)

end


-- Make new window and move into it.
-- @param do_kick
local function openNewBuffer(do_kick, matches, highlight_info)
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

	if do_kick then
		animateBufferOpen(win, header, matches, header_and_poof)
	else
		bufferOpen(win, header, matches)
	end
	sk_outline.set_highlight(highlight_info)
	set_icon_highlights()
	-- Also set sidekick_def_type_icons and outline as highlights
	--sidekick_outer_node_icon
	return buf, win
end

function set_icon_highlights()
	if vim.g.sidekick_outer_node_icon then
		local syntax_group = "syntax match OuterInnerNodes '[" ..  table.concat({vim.g.sidekick_outer_node_icon, vim.g.sidekick_inner_node_icon}, '') .. "]'"
		vim.cmd(syntax_group)
		local highlight_link = "highlight default link OuterInnerNodes GruvBoxBlue"
		vim.cmd(highlight_link)
	end

	local possible_ones = {'Special', 'Number', 'Function', 'Define', 'String', 'Keyword', 'Special'}
	if vim.g.sidekick_def_type_icons then
		local i = 1
		for def_type, icon in pairs(vim.g.sidekick_def_type_icons) do
			local group_name = "sidekick" .. def_type
			local syntax_group = "syntax keyword " .. group_name .. " " ..  icon
			vim.cmd(syntax_group)
			local highlight_link = "highlight default link " .. group_name .. " " .. possible_ones[i]
			vim.cmd(highlight_link)
			i = i + 1
		end
	end
	-- Associate that syntax group with existing types
	-- TODO (elpiloto): Make "String" configurable.
end

local function entry_prefix(indent_level, is_last_node)
	local prefix = '  '
	if is_last_node then
		prefix = prefix .. string.rep(' ', indent_level*2) .. vim.g.sidekick_outer_node_icon .. ' '
	else
		prefix = prefix .. string.rep(' ', indent_level*2) .. vim.g.sidekick_inner_node_icon .. ' '
	end
	return prefix
end

local function format_entry(def_name, def_type, indent_level, next_indent_level)
	local is_last_node = false
	local next_node_higher = false
	if not next_indent_level then 
		is_last_node = true
	elseif indent_level ~= next_indent_level then
		is_last_node = true
		if indent_level > next_indent_level then
			next_node_higher = true
		end
	end
	local str = entry_prefix(indent_level, is_last_node)
	if vim.g.sidekick_def_type_icons[def_type] then
		str = str .. vim.g.sidekick_left_bracket .. vim.g.sidekick_def_type_icons[def_type] .. vim.g.sidekick_right_bracket
	end
	str = str .. ' ' .. def_name
	return str
end

function foldtext()
	local foldstart = vim.v.foldstart
    local foldend   = vim.v.foldend
    local winwidth  = vim.api.nvim_win_get_width(0)
    local line, _ = (vim.api.nvim_buf_get_lines(0, foldstart - 1, foldstart, false)[1]):gsub('^"', ' ')
	return line
end

local function get_indent_level(line)
	if not line then
		return nil
	end
	local indent_level = string.match(line, '(%s*)')
	--TODO(elpiloto): Set 2 based on prefix for formatting.
	return #indent_level
end

local function get_fold_context(line_num)
	local before, current, after = nil, nil, nil
	if line_num == 0 then
		before = nil
	else
		before = (vim.api.nvim_buf_get_lines(0, line_num-1, line_num, false)[1])
	end
	local lines, _ = vim.api.nvim_buf_get_lines(0, line_num, line_num+2, false)
	return before, lines[1], lines[2]
end

function foldexpr()
    local winwidth  = vim.api.nvim_win_get_width(0)
	local line_num = vim.v.lnum - 1

	-- Set no fold for anything in the header.
	if line_num < 8 then
		return "0"
	end
	local before, line, after = get_fold_context(line_num)
	local before_indent = get_indent_level(before)
	local line_indent = get_indent_level(line)
	local after_indent = get_indent_level(after)
	--local line, _ = (vim.api.nvim_buf_get_lines(0, line_num, line_num+1, false)[1]):gsub('^"', ' ')
	-- If we're a blank line or surrounded by blank lines, we are not a fold.
	if line == '' or (before == '' and after == '') then
		return "0"
		--return '<1'
	elseif before_indent then
		-- We're indented and have children.
		if line_indent == before_indent and line_indent < after_indent then
			return ">" .. tostring(line_indent)
		-- we're indented but there's nothing after us
		elseif line_indent > before_indent and not after then
			return tostring(before_indent)
		else
			return tostring(line_indent)
		end
	end
	return ">1"
end

local function get_outline()
	local bufnr = vim.api.nvim_get_current_buf()
	-- TODO(ElPiloto): makes 'locals' configurable.
	scopes, defs, scopes_and_defs = sk_outline.get_scope_and_definition_captures(bufnr, 'locals')
	root = sk_outline.find_parents(scopes_and_defs, scopes)
	outline, hl_info = sk_outline.build_outline(root, query)
	local indented_strings = {}
	for i, info in ipairs(outline) do
		local def_type = info[2]
		local next_indent_level = nil
		local next_i = i+1
		if vim.tbl_contains(vim.g.sidekick_printable_def_types, def_type) then
			--Get the next indent level that is actually printable
			while outline[next_i] and not next_indent_level do
				local temp = outline[next_i]
				if vim.tbl_contains(vim.g.sidekick_printable_def_types, temp[2]) then
					next_indent_level = temp[3]
				else
					next_i = next_i + 1
				end
			end
			table.insert(indented_strings, format_entry(info[1], info[2], info[3], next_indent_level))
			if  next_indent_level and next_indent_level < info[3] then
				table.insert(indented_strings, '')
			end
			if  next_indent_level and next_indent_level == 0 and info[3] == 0 then
				table.insert(indented_strings, '')
			end
		end
	end
	-- Add a final blank line.
	table.insert(indented_strings, '')
	return indented_strings, hl_info
end


local function run()
	local processed_matches, hl_info = get_outline()
	local do_kick = false
	buf, win = openNewBuffer(do_kick, processed_matches, hl_info)
	vim.wo.foldtext=[[luaeval("require('sidekick').foldtext()")]]
	vim.wo.foldexpr=[[luaeval("require('sidekick').foldexpr()")]]
	vim.wo.foldmethod='expr'
	--vim.wo.foldcolumn='4'
end


return {
	run = run,
	foldtext = foldtext,
	foldexpr = foldexpr
}
