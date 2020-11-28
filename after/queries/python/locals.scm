;;; Custom Queries
; This captures flags under `definition.flag`
; using absl flag format:
; flags.DEFINE_$sometype('flag_name', ...)
(call 
  function: 
  	(attribute
	  attribute: (identifier) @fn_name)
  arguments:
    (argument_list
	  . (string) @definition.flag)
  (#match? @fn_name "^DEFINE_.*")
)
