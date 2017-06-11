; Is an associative array empty?
IsEmptyAssoc(assoc){
	; Lexikos' suggested method
	; If enabled, seems to make vJoy bindings stop working after reloading
	;return assoc.SetCapacity(0) == 0
	return !assoc._NewEnum()[k, v]
}
