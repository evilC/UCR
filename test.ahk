gui, add, checkbox, vcb gOptionChanged
gui, show

Return

optionchanged:
	GuiControlGet,cb
	;gui,submit, NoHide
	tooltip % cb