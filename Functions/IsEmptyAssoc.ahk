; Is an associative array empty?
IsEmptyAssoc(assoc){
	return assoc.SetCapacity(0) == 0
	;return !assoc._NewEnum()[k, v]
}
