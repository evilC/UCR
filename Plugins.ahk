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
		new UCR.GuiControl(this, "Text", "xm ym", "Key")
		this.Input := new UCR.GuiControl(this, "Edit", "x80 yp-3 Section")
		new UCR.GuiControl(this, "Text", "xm", "ahk_class")
		this.App := new UCR.GuiControl(this, "Edit" , "xs yp-3")
		this.Show()
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
		Tooltip % this.App.Value
		this.h1.Add(this.Input.Value, this.App.Value, this.DownEvent, this.UpEvent, this)
		base.OnChange()
	}
}

UCR.RegisterPlugin("TestB")

Class TestB extends Test {
}