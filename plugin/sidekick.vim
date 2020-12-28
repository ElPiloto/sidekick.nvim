fun! SideKick()
	lua for k in pairs(package.loaded) do if k:match("^sidekick") then package.loaded[k] = nil end end
	lua require("sidekick").run(true)
endfun

augroup SideKick
	autocmd!
augroup END

fun! SideKickNoReload()
	lua require("sidekick").run(true)
endfun

fun! SideKickClose()
	lua require("sidekick").close()
endfun

fun! s:AddDefaultSettings()
	if !exists('g:sidekick_update_on_buf_write') | let g:sidekick_update_on_buf_write = 1 | endif
	if !exists('g:sidekick_printable_def_types') | let g:sidekick_printable_def_types = ['function', 'class', 'type', 'module', 'parameter', 'method', 'field', 'flag'] | endif
	if !exists('g:sidekick_def_type_icons')
		let g:sidekick_def_type_icons = {
					\    'class': "\uf0e8",
					\    'type': "\uf0e8",
					\    'function': "\uf794",
					\    'module': "\uf7fe",
					\    'arc_component': "\uf6fe",
					\    'sweep': "\uf7fd",
					\    'parameter': "•",
					\    'var': "v",
					\    'method': "\uf794",
					\    'field': "\uf6de",
					\    'flag': "\uf73a",
					\ }
	endif
	if !exists('g:sidekick_ignore_by_def_type')
		let g:sidekick_ignore_by_def_type = {
					\    'var': {"_": 1, "self": 1},
					\    'parameter': {"self": 1},
					\ }
	endif

	if !exists('g:sidekick_line_num_def_types')
		let g:sidekick_line_num_def_types = {
					\    'class': 1,
					\    'type': 1,
					\    'function': 1,
					\    'module': 1,
					\    'method': 1,
					\ }
	endif

	if !exists('g:sidekick_line_num_separator') | let g:sidekick_line_num_separator = " " | endif
	if !exists('g:sidekick_line_num_left') | let g:sidekick_line_num_left = "\ue0b2" | endif
	if !exists('g:sidekick_line_num_right') | let g:sidekick_line_num_right = "\ue0b0" | endif
	if !exists('g:sidekick_inner_node_icon') | let g:sidekick_inner_node_icon = "\u251c\u2500\u25CB" | endif
	if !exists('g:sidekick_outer_node_icon') | let g:sidekick_outer_node_icon = "\u2570\u2500\u25CB" | endif
	if !exists('g:sidekick_outer_node_folded_icon') | let g:sidekick_outer_node_folded_icon = "\u2570\u2500\u25C9" | endif
	if !exists('g:sidekick_left_bracket') | let g:sidekick_left_bracket = "\u27ea" | endif
	if !exists('g:sidekick_right_bracket') | let g:sidekick_right_bracket = "\u27eb" | endif

endfunction

call s:AddDefaultSettings()
