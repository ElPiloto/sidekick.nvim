# sidekick.nvim
An outline window that's always by your side (except for when it's not).

### WIP: This plugin is not yet ready for widespread use.
It requires neovim (~nightly build) and `nvim-treesitter`.

```
   _____ _     __     __ __ _      __   
  / ___/(_)___/ /__  / //_/(_)____/ /__ 
  \__ \/ / __  / _ \/ ,<  / / ___/ //_/ 
 ___/ / / /_/ /  __/ /| |/ / /__/ ,<    
/____/_/\__,_/\___/_/ |_/_/\___/_/|_|   
=======================================
```

![Sidekick Demo](./.github/images/sidekick_demo.jpg)

### TODO

- [x] Jump from outline to definition
- [x] Update outline on editor events
  - [x] Buffer save
  - [x] Change active window
- [ ] Display filename (buffer name) in sidekick.
- [ ] Add custom fold highlight while we want for neovim bug about highlighting folds to get fixed.
- [ ] Allow empty sidekick window. Currently we just don't open an outline window if the current bufffer is empty or corresponds to an un-supported (by treesitter) filetype.
- [ ] Set window settings to stop context.vim from popping up.
- [ ] Add documentation.
- [ ] Improve plugin configs
  - [ ] Add supported options to documentation.
  - [ ] Add error-checking / default values.
- [ ] Decouple rendering from outline in order to:
  1. Allow smarter rendering (e.g. isolated top-level nodes should be displayed as `outerNode`)
  2. Interface to allow other tag definition backends (e.g. LSP or ctags)
- [ ] After jumping to definition, scroll screen upwards (add config option to control this).
- [ ] Document highlight groups so that colorschemes can explicitly support them.
- [ ] Learn how to make tests for your plugin and test your code, guy.
- [X] Use treesitter to generate outline for custom queries ~~~(queries/$LANG/sidekick.scm)~~~ (`queries/$LANG/locals.scm`)

### BUGS

- [X] Outline is incomplete: functions are missing - may be a max line issue.
- [X] Outline is cut off for first entry.
- [X] Window contains parts of multiple outlines when switching windows (clear sidekick buffer).
- [ ] First entry is not foldable.

### Roadmap

- [ ] Use treesitter to generate outline for "standard" queries (`queries/$LANG/locals.scm`)
- [ ] Sort by order or kind.  
- [ ] Generate outline based on LSP.  
- [ ] Pop-up documentation for symbol when using LSP.  
- [ ] After getting experience, re-write most of codebase using an extensible system to allow end users to populate outline window.
- [ ] Let users specify what definitions get shown for standard queries.   


### Maybe features  

- [ ] Generate outline based on tags file.  
- [ ] When using treesitter for outline *and* LSP is available, pop-up documentation for symbol.
