local api = vim.api

local sk_outline = require('sidekick.outline')

local M = {}

-- This holds a mapping from a dict[buffer_id --> dict[line_nr --> cursor_position]]
M.per_buffer_jump_info = {}
M.open_windows = {}
M.last_parsed_buf = -1
M.open_tabs = {}

-- Splits string at new lines into table.
local function split_str(str)
  local lines = {}
  for s in str:gmatch("[^\r\n]+") do
    table.insert(lines, s)
  end
  return lines
end

local function getSidekickText()
  -- luacheck: push ignore 613 (trailing whitespaces)
  -- TODO(elpiloto): Figure out why we are stripping blank lines from the bottom
  -- of this string.
  M.header = [[

   _____ _     __     __ __ _      __   
  / ___/(_)___/ /__  / //_/(_)____/ /__ 
  \__ \/ / __  / _ \/ ,<  / / ___/ //_/ 
 ___/ / / /_/ /  __/ /| |/ / /__/ ,<    
/____/_/\__,_/\___/_/ |_/_/\___/_/|_|   
=======================================
                                       
]]
  local lines = {}
  local num_lines = 0
  for s in M.header:gmatch("[^\r\n]+") do
    table.insert(lines, s)
    num_lines = num_lines + 1
  end
  local header_and_dude = [[
         ..      
        :  :     _____ _     __     __ __ _      __   
         ``     / ___/(_)___/ /__  / //_/(_)____/ /__ 
      \__|      \__ \/ / __  / _ \/ ,<  / / ___/ //_/ 
        _| >   ___/ / / /_/ /  __/ /| |/ / /__/ ,<    
o________/    /____/_/\__,_/\___/_/ |_/_/\___/_/|_|   
    o___/     =======================================

]]
  local header_and_poof = [[

   .( * .        _____ _     __     __ __ _      __   
 .*  .  ) .     / ___/(_)___/ /__  / //_/(_)____/ /__ 
. . POOF .* .   \__ \/ / __  / _ \/ ,<  / / ___/ //_/ 
 '* . (  .) '  ___/ / / /_/ /  __/ /| |/ / /__/ ,<    
  ` ( . *     /____/_/\__,_/\___/_/ |_/_/\___/_/|_|   
              =======================================

]]
  -- luacheck: pop
  return split_str(M.header), split_str(header_and_dude), split_str(header_and_poof)
end

local function animate_buffer_open(win, buf, header, matches, poof)
  -- Smoothly expand window width, contract a bit, and then expand to final size.
  local final_width=40
  local widths = {60, 50, 52}
  local speeds = {100, 200, 200}
  local prev_w = 1
  local speed = nil
  for i, target_w in pairs(widths) do
    speed = speeds[i]
    local step_dir = -1
    if target_w > prev_w then
      step_dir = 1
    end
    -- Gradually modify our width to target width
    for j = prev_w, target_w, step_dir do
      local new_width_fn = function()
        api.nvim_win_set_width(win, j)
        -- Need this for smooth animation.
        api.nvim_command('redraw')
      end
      vim.defer_fn(new_width_fn, speed)
    end
    prev_w = target_w
  end
  -- finally after all that has been done, let's set the final text
  if poof then
    local final_text_fn = function()
      -- Display matches
      api.nvim_buf_set_option(buf, 'modifiable', true)
      api.nvim_buf_set_lines(buf, 0, #poof, false, poof)
      -- Apparently this needs to be set after we insert text.
      api.nvim_buf_set_option(buf, 'modifiable', false)
    end
    vim.defer_fn(final_text_fn, speed*6)
  end
  -- finally after all that has been done, let's set the final text
  local final_text_fn = function()
    -- Display matches
    api.nvim_buf_set_option(buf, 'modifiable', true)
    api.nvim_buf_set_lines(buf, 0, #header, false, header)
    api.nvim_buf_set_lines(buf, #header, #header+#matches, false, matches)
    -- Apparently this needs to be set after we insert text.
    api.nvim_buf_set_option(buf, 'modifiable', false)
    api.nvim_win_set_width(win, final_width)
    -- Need this for smooth animation.
    api.nvim_command('redraw')
  end
  vim.defer_fn(final_text_fn, speed*12)
end

local function bufferOpen(win, buf, header, matches)
  -- Smoothly expand window width, contract a bit, and then expand to final size.
  local final_width=40
  api.nvim_win_set_width(win, final_width)
  api.nvim_buf_set_option(buf, 'modifiable', true)
  api.nvim_buf_set_lines(buf, 0, #header, false, header)
  api.nvim_buf_set_lines(buf, #header, #header+#matches, false, matches)
  -- Apparently this needs to be set after we insert text.
  api.nvim_buf_set_option(buf, 'modifiable', false)

end

-- NB: Must be called from within sidekick window.
local function add_keymappings()
  -- jump to definition on <CR>
  api.nvim_buf_set_keymap(0, 'n', '<CR>', ':lua require "sidekick".jump_to_definition()<CR>', { silent = true })
end

-- Re-run sidekick if buffer is written to using autocommands.
local function run_on_buf_write(buf)
  --Wrap autocmd in per-tabpage augroup to stop duplicate registration.
  local tabpage = api.nvim_get_current_tabpage()
  -- TODO(elpiloto): Make util function for adding autocommands.
  local augroup = M._make_augroup_name(tabpage)
  vim.cmd('augroup ' .. augroup)
  local lua_callback_cmd = 'lua require(\'sidekick\').run()'
  local full_cmd = 'autocmd! ' .. augroup .. ' BufWritePost <buffer=' .. tostring(buf) .. '> ' .. lua_callback_cmd
  vim.cmd(full_cmd)
  vim.cmd('augroup END')
end

-- Removes current tab from list of open tabs so we don't try to open sidekick
-- when it has been closed.
function M.remove_tab()
  local tabpage = api.nvim_get_current_tabpage()
  local win_name = M._make_window_name(tabpage)
  local win_id = vim.fn.expand('<afile>')
  if win_id == tostring(M.open_windows[win_name]) then
    M.open_tabs[tabpage] = nil
    print(vim.inspect(M.open_tabs))
    -- TODO(elpiloto): Consider clearing out M.open_windows
    local augroup = M._make_augroup_name(tabpage)
    -- Delete all sidekick autocommands set up for this tab.
    vim.cmd('augroup ' .. augroup)
    vim.cmd('au!')
    vim.cmd('augroup ' .. augroup)
  end
end

--Keep track of what tabs have open pages.
local function cleanup_on_close()
  local tabpage = api.nvim_get_current_tabpage()
  local augroup = M._make_augroup_name(tabpage)
  vim.cmd('augroup ' .. augroup)
  local lua_callback_cmd = 'lua require(\'sidekick\').remove_tab()'
  local full_cmd = 'autocmd! ' .. augroup .. ' WinClosed * ' .. lua_callback_cmd
  vim.cmd(full_cmd)
  vim.cmd('augroup END')
end

-- Runs if sidekick is open for the current tabpage and buffer can be parsed but
-- hasn't been.
function M.maybe_run()
  local tabpage = api.nvim_get_current_tabpage()
  if M.open_tabs[tabpage] and vim.bo.filetype ~= 'sidekick' then
    local buf = api.nvim_get_current_buf()
    local win = api.nvim_get_current_win()
    if M.last_parsed_buf ~= buf then
      M.run()
      api.nvim_set_current_win(win)
    end
  end
end

local function run_on_buf_enter()
  local tabpage = api.nvim_get_current_tabpage()
  local augroup = M._make_augroup_name(tabpage)
  vim.cmd('augroup ' .. augroup)
  local lua_callback_cmd = 'lua require(\'sidekick\').maybe_run()'
  local full_cmd = 'autocmd! ' .. augroup .. ' BufEnter * ' .. lua_callback_cmd
  vim.cmd(full_cmd)
  vim.cmd('augroup END')
end

local function make_outline_window(win_name)
  --local win_name = 'Sidekick' .. tostring(api.nvim_get_current_buf())
  api.nvim_command('keepalt botright vertical 1 split ' .. win_name)
  local win = api.nvim_get_current_win()
  local buf = api.nvim_get_current_buf()

  --Disable wrapping
  api.nvim_win_set_option(win, 'wrap', false)
  api.nvim_win_set_option(win, 'list', false)
  api.nvim_win_set_option(win, 'number', false)
  api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  api.nvim_buf_set_option(buf, 'swapfile', false)
  api.nvim_win_set_option(win, 'wrap', false)
  vim.bo.buflisted = true
  vim.bo.modifiable = false
  vim.bo.textwidth = 0
  vim.bo.filetype = 'sidekick'
  api.nvim_command('hi NonText guifg=bg')
  vim.wo.winfixwidth = true
  vim.wo.spell = false
  -- Additional options to try out
  -- nolist, nowrap, breakindent?, number? nosigncolumn
  return win, buf
end


function M._make_window_name(tabpage)
  return '__SideKick__(' .. tabpage .. ')'
end

function M._make_augroup_name(tabpage)
  return '__sidekick__' .. tabpage .. ''
end

local function set_icon_highlights()
  if vim.g.sidekick_outer_node_icon then
    local syntax_group = "syntax match OuterInnerNodes '["
    syntax_group = syntax_group .. table.concat({vim.g.sidekick_outer_node_icon, vim.g.sidekick_inner_node_icon}, '')
    syntax_group = syntax_group .. "]'"
    vim.cmd(syntax_group)
    local highlight_link = "highlight default link OuterInnerNodes GruvBoxBlue"
    vim.cmd(highlight_link)
  end

  local possible_ones = {'Special', 'Number', 'Function', 'Define', 'String',
                         'Keyword', 'Special', 'Operator', 'Function', 'Define', 'String', 'Keyword',}
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

-- Searches current tabpage for a window containing buf.
local function find_win_for_buf(buf)
  local wins = api.nvim_tabpage_list_wins(0)
  for _, win in ipairs(wins) do
    if api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
  return nil
end

-- Make new window and move into it.
-- @param do_kick
local function open_outline_window(do_kick, matches, highlight_info)
  --TODO(ElPiloto): Make sure we have an open file otherwise this command will fail.
  local tabpage = api.nvim_get_current_tabpage()
  local win_name = M._make_window_name(tabpage)
  local win, buf = nil, nil
  if not M.open_windows[win_name] or vim.fn.win_id2win(M.open_windows[win_name]) == 0 then
    win, buf = make_outline_window(win_name)
    M.open_windows[win_name] = win
  else
    win = M.open_windows[win_name]
    api.nvim_set_current_win(win)
    buf = api.nvim_get_current_buf()
  end

  -- Display some ascii art text
  local header, header_and_dude, header_and_poof = getSidekickText()
  api.nvim_buf_set_option(buf, 'modifiable', true)
  api.nvim_buf_set_lines(buf, 0, #header_and_dude, false, header_and_dude)

  -- Apparently this needs to be set after we insert text.
  api.nvim_buf_set_option(buf, 'modifiable', false)

  if do_kick then
    animate_buffer_open(win, buf, header, matches, header_and_poof)
  else
    bufferOpen(win, buf, header, matches)
  end
  sk_outline.set_highlight(highlight_info)
  set_icon_highlights()
  add_keymappings()
  cleanup_on_close()
  --Track which windows we have been opened in.
  M.open_tabs[tabpage] = true
  -- Also set sidekick_def_type_icons and outline as highlights
  --sidekick_outer_node_icon
  return buf, win
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
  next_node_higher = next_node_higher and nil -- Fix un-accessed variable error.
  local str = entry_prefix(indent_level, is_last_node)
  if vim.g.sidekick_def_type_icons[def_type] then
    str = str .. vim.g.sidekick_left_bracket .. vim.g.sidekick_def_type_icons[def_type] .. vim.g.sidekick_right_bracket
  end
  str = str .. ' ' .. def_name
  return str
end

function M.foldtext()
  local foldstart = vim.v.foldstart
  -- local foldend   = vim.v.foldend
  -- Leaving this here just in case it's useful.
  -- local winwidth  = api.nvim_win_get_width(0)
  local line, _ = (api.nvim_buf_get_lines(0, foldstart - 1, foldstart, false)[1]):gsub('^"', ' ')
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
  local before = nil
  if line_num == 0 then
    before = nil
  else
    before = (api.nvim_buf_get_lines(0, line_num-1, line_num, false)[1])
  end
  local lines, _ = api.nvim_buf_get_lines(0, line_num, line_num+2, false)
  return before, lines[1], lines[2]
end

function M.foldexpr()
  --local winwidth  = api.nvim_win_get_width(0)
  local line_num = vim.v.lnum - 1

  -- Set no fold for anything in the header.
  if line_num < 8 then
    return "0"
  end
  local before, line, after = get_fold_context(line_num)
  local before_indent = get_indent_level(before)
  local line_indent = get_indent_level(line)
  local after_indent = get_indent_level(after)
  -- If we're a blank line or surrounded by blank lines, we are not a fold.
  if line == '' or (before == '' and after == '') then
    return "0"
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
  -- TODO(ElPiloto): check filetype is parsable, otherwise return nil
  local bufnr = api.nvim_get_current_buf()
  -- TODO(ElPiloto): makes 'locals' configurable.
  local scopes, defs, scopes_and_defs = sk_outline.get_scope_and_definition_captures(bufnr, 'locals')
  defs = defs and nil -- Fix lint error
  local root = sk_outline.find_parents(scopes_and_defs, scopes)
  -- NB
  --table.insert(ranges, {def_name, def_type, indent, start_row, start_col, end_row, end_col})
  local outline, hl_info = sk_outline.build_outline(root)
  -- Note: These are relative line numbers from the start of our outline, not the window.
  local jump_info = {}
  local indented_strings = {}
  local line_nr = 1
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
      jump_info[line_nr] = {info[4], info[5]}
      line_nr = line_nr + 1
      if  next_indent_level and next_indent_level < info[3] then
        table.insert(indented_strings, '')
        line_nr = line_nr + 1
      end
      if  next_indent_level and next_indent_level == 0 and info[3] == 0 then
        table.insert(indented_strings, '')
        line_nr = line_nr + 1
      end
    end
  end
  -- Add a final blank line.
  table.insert(indented_strings, '')
  return indented_strings, hl_info, jump_info
end


local function enable_folding()
  vim.wo.foldtext=[[luaeval("require('sidekick').foldtext()")]]
  vim.wo.foldexpr=[[luaeval("require('sidekick').foldexpr()")]]
  vim.wo.foldmethod='expr'
  --vim.wo.foldcolumn='4'
end


function M.jump_to_definition()
  -- TODO(elpiloto): Make this more robust when we switch to the render interface.
  local start_outline_line_nr = #split_str(M.header)
  local abs_line_nr = vim.fn.line('.')
  local relative_line_nr = abs_line_nr - start_outline_line_nr
  -- TODO(elpiloto): Reload cursor location (a.k.a. nodes from Treesitter) if
  -- needed.  This may be the case if the buffer has been modified since we
  -- last populated per_buffer_jump_info.
  if M.per_buffer_jump_info[M.last_parsed_buf] then
    if M.per_buffer_jump_info[M.last_parsed_buf][relative_line_nr] then
      local row_col =  M.per_buffer_jump_info[M.last_parsed_buf][relative_line_nr]
      local win = find_win_for_buf(M.last_parsed_buf)
      if win then
        print('we in', vim.inspect(row_col), M.last_parsed_buf)
        --api.nvim_set_current_buf(M.last_parsed_buf)
        api.nvim_set_current_win(win)
        api.nvim_win_set_cursor(0, { row_col[1] + 1, row_col[2] })
      end
    end
  end
end


function M.run()
  local buf = api.nvim_get_current_buf()
  if not sk_outline.can_parse_buffer(buf) then
    local filetype = vim.bo.filetype
    print('No parser for filetype: ' .. filetype)
    return
  end
  M.last_parsed_buf = buf
  --print('Setting last parsed buf to ' .. tostring(M.last_parsed_buf))
  local processed_matches, hl_info, jump_info = get_outline()
  M.per_buffer_jump_info[M.last_parsed_buf] = jump_info
  local do_kick = false
  open_outline_window(do_kick, processed_matches, hl_info)
  enable_folding()
  if vim.g.sidekick_update_on_buf_write == 1 then
    run_on_buf_write(buf)
  end
  run_on_buf_enter()
end


return M
