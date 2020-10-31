# sidekick.nvim
An outline window that's always by your side (except for when it's not).

```
   _____ _     __     __ __ _      __   
  / ___/(_)___/ /__  / //_/(_)____/ /__ 
  \__ \/ / __  / _ \/ ,<  / / ___/ //_/ 
 ___/ / / /_/ /  __/ /| |/ / /__/ ,<    
/____/_/\__,_/\___/_/ |_/_/\___/_/|_|   
=======================================
```

### Roadmap

- [ ] Use treesitter to generate outline for "standard" queries (`queries/$LANG/locals.scm`)  
- [ ] Sort by order or kind.  
- [ ] Use treesitter to generate outline for custom queries (`queries/$LANG/sidekick.scm`)  
- [ ] Generate outline based on LSP.  
- [ ] Pop-up documentation for symbol when using LSP.  
- [ ] After getting experience, re-write most of codebase using an extensible system to allow end users to populate outline window.
- [ ] Let users specify what definitions get shown for standard queries.   


### Maybe features  

- [ ] Generate outline based on tags file.  
- [ ] When using treesitter for outline *and* LSP is available, pop-up documentation for symbol.
