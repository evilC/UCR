class ButtonToButtonPr extends _UCR.Classes.Plugin {
	Type := "Remapper (Button To Button - Press / Release)"
	Description := "Remap press or release of input to press and release of output"
	Mode := 1	; 1 = Press, 0 = Release
	; The Init() method of a plugin is called when one is added. Use it to create your Gui etc
	Init(){
		; Create the GUI
		Gui, Add, GroupBox, Center xm ym w170 h60 section, Input Button
		this.AddControl("InputButton", "IB1", 0, this.MyHkChangedState.Bind(this), "xs+5 ys+20")
		this.AddControl("ButtonPreview", "", 0, this.IOControls.IB1, "x+5 yp+5")
		;Gui, Add, Text, y+10, % "Remap"
		Gui, Add, GroupBox, Center x190 ym w170 h60 section, Output Button
		this.AddControl("OutputButton", "OB1", 0, "xs+5 ys+20")
		this.AddControl("ButtonPreview", "", 0, this.IOControls.OB1, "x+5 yp+5")
		
		Gui, Add, GroupBox, Center x370 ym w220 h60 section, Settings
		Gui, Add, Text, xs+5 ys+30 w130 Center, % "Send press and release on"
		this.AddControl("DDL", "Pr", this.ModeSelect.Bind(this), "x+5 yp-3 w75 AltSubmit", "Press||Release")
	}
	
	; Called when the hotkey changes state (key is pressed or released)
	MyHkChangedState(e){
		if (this.Mode == e){
			;~ Tooltip % e
			this.IOControls.OB1.Set(1)
			Sleep 50
			this.IOControls.OB1.Set(0)
		}
	}
	
	ModeSelect(value){
		this.Mode := ( value == 1 ? 1 : 0)
	}
}
