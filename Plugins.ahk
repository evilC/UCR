/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Example plugin(s)
*/

UCR.RegisterPlugin("Test")

Class Test extends UCR.Plugin {
	__New(parent){
		base.__New(parent)
	}

	CreateGui(){
		static
		base.CreateGui()

		this.h1 := new this.parent.Hotkey(this)
		this.ed := new UCR.GuiControl(this, "Edit")
		this.Show()
		this.OnChange()
	}

	DownEvent(){
		soundbeep
		Tooltip % this.h1.CurrentKey " Down"
	}

	UpEvent(){
		soundbeep
		Tooltip % this.h1.CurrentKey " Up"
	}

	OnChange(){
		;Tooltip % this.ed.Value
		this.h1.Add(this.ed.Value, this.DownEvent, this.UpEvent, this)
		base.OnChange()
	}
}
