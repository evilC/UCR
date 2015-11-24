#SingleInstance force
u := new UCR()
return

class UCR {
	__New(){
		;filename := A_ScriptDir "\test2.tmp.ahk"
		filename := A_ScriptDir "\Plugins\TestPlugin1.ahk"
		FileRead,plugincode,% filename
		RegExMatch(plugincode,"i)class\s+(\w+)\s+extends\s+_Plugin",classname)
		AddFile(filename, 1)

		PluginInstance := new %classname1%()
	}
}

class _Plugin {
	__New(){
		this.Init()
	}
}

