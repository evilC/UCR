/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Example plugin(s)
*/

UCR.RegisterPlugin("Test")

Class Test extends UCR.Plugin {
	desc := "plugin"
	__New(parent){
		base.__New(parent)
	}

	CreateGui(){
		static
		base.CreateGui()

		WIDTH := 250
		HEIGHT := 160
		this.h1 := new this.parent.Hotkey(this)
		new UCR.GuiControl(this, "Text", "xm ym", "Key")
		this.Input := new UCR.GuiControl(this, "Edit", "w" WIDTH - 60 " x80 yp-3 Section" )
		new UCR.GuiControl(this, "Text", "xm", "ahk_class")
		this.App := new UCR.GuiControl(this, "Edit" , "w" WIDTH - 60 " xs yp-3")
		new UCR.GuiControl(this, "Text", "xm w" WIDTH " Center", "Modifiers")
		
		this.PassThru := new UCR.GuiControl(this, "CheckBox", "x20 yp+30 section")
		this.Wild := new UCR.GuiControl(this, "CheckBox", "yp+20")
		this.Dollar := new UCR.GuiControl(this, "CheckBox", "yp+20")
		
		new UCR.GuiControl(this, "Text", "xp+30 ys", "`~ Pass Through", "Pass Through")
		new UCR.GuiControl(this, "Text", "yp+20", "* Wild", "Wild")
		new UCR.GuiControl(this, "Text", "yp+20", "$ Send doesnt trigger", "Dollar")
		
		this.Alt := new UCR.GuiControl(this, "CheckBox", "x200 ys section")
		this.Ctrl := new UCR.GuiControl(this, "CheckBox", "yp+20")
		this.Shift := new UCR.GuiControl(this, "CheckBox", "yp+20")
		this.Win := new UCR.GuiControl(this, "CheckBox", "yp+20")
		
		new UCR.GuiControl(this, "Text", "xp+30 ys", "! Alt", "Alt")
		new UCR.GuiControl(this, "Text", "yp+20", "^ Ctrl", "Ctrl")
		new UCR.GuiControl(this, "Text", "yp+20", "+ Shift", "Shift")
		new UCR.GuiControl(this, "Text", "yp+20", "# Win")
		
		this.Show("w" WIDTH + 30 " h" HEIGHT + 10)
		this.OnChange()
	}
	
	BuildPrefixes(){
		ret := ""
		ret .= this.PassThru.Value ? "~" : ""
		ret .= this.Wild.Value ? "*" : ""
		ret .= this.Dollar.Value ? "$" : ""
		ret .= this.Alt.Value ? "!" : ""
		ret .= this.Ctrl.Value ? "^" : ""
		ret .= this.Shift.Value ? "+" : ""
		ret .= this.Win.Value ? "#" : ""
		return ret
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
}