/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Example plugin(s)
*/

UCR.RegisterPlugin("Test")

Class Test extends UCR.Plugin {
	__New(parent){
		static
		base.__New(parent)
		this.h1 := new this.parent.Hotkey(this)
		this.h1.Add("~a",this.test)
		Gui, New
		;Gui, Add, Edit,% "v#" Object(this) " g_UCR_GLabel_Router "
		this.ed := new UCR.GuiControl(this, "Edit", "", "")
		Gui, Show
	}

	Test(){
		soundbeep
	}

	DownEvent(){

	}

	OnChange(){
		;msgbox here
		Tooltip % this.ed.Value
	}
}
