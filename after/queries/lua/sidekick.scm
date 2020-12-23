; handles: module_name.method = function
; OR module_name['method'] = function
((variable_declaration
  (variable_declarator) @definition.method
    (function_definition)) @scope)

((function
   (function_name
     (identifier) @definition.associated
	 (method) @definition.method)) @scope)

[
((local_variable_declaration
  (variable_declarator
      (identifier) @definition.function)
	    (function_definition)) @scope)
(function_definition) @scope
]

; busted "describe" and "it"
((function_call
  (identifier) @describe_name
  (arguments
    (string) @definition.busted_describe )
  ) @scope
  (#match? @describe_name "describe")
)

((function_call
  (identifier) @it_name
  (arguments
    (string) @definition.busted_it )
  ) @scope
  (#match? @it_name "it")
)
