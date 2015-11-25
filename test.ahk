#SingleInstance force
u := new UCR()
return

class UCR {
	__New(){
		gui, show, x0 y0 w200 h200
		filename := A_ScriptDir "\test3.tmp.ahk"
		AddFile(filename, 1)
		PluginInstance := new SomeClass()
	}
}

class _Plugin {
	__New(){
		this.Init()
	}
}

/*
test3.tmp.ahk
class SomeClass {
	__New(){
		msgbox CTOR
	}
	
	Blah(){
		Gui Add, Text,, hello
	}
}
*/
