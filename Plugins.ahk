/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Example plugin(s)
*/

UCR.RegisterPlugin("Test")

Class Test extends UCR_Plugin {
	cls := ""
	desc := "plugin"
	__New(parent){
		base.__New(parent)
	}

	CreateGui(){
		static
		base.CreateGui()

		WIDTH := 300
		HEIGHT := 160
		this.h1 := new this.parent.Hotkey(this)
		
		this.Show("w" WIDTH + 20 " h" HEIGHT + 10)
		this.OnChange()
	}
	
	DownEvent(){
		soundbeep
		;Tooltip % this.h1.CurrentKey " Down"
	}

	UpEvent(){
		soundbeep
		;Tooltip % this.h1.CurrentKey " Up"
	}

	OnChange(){
		;soundbeep
		this.h1.Add(this.BuildPrefixes() this.Input.Value, this.App.Value, this.DownEvent, this.UpEvent, this)
		base.OnChange()
	}
}

UCR.RegisterPlugin("TestB")

Class TestB extends Test {
	cls := "Notepad"
}