fun! SideKick()
	lua for k in pairs(package.loaded) do if k:match("^sidekick") then package.loaded[k] = nil end end
	lua require("sidekick").run()
endfun

augroup SideKick
	autocmd!
augroup END
