/*
Remaps a physical joystick axis to a pair of button outputs
Requires the StickOps library and the vJoy library
*/
class AxisToButtons extends _UCR.Classes.Plugin {
	Type := "Remapper (Axis To Buttons)"
	Description := "Maps a joystick axis input to a pair of button outputs"
	LastState := 0
	; Set up the GUI to allow the user to select inputs and outputs
	Init(){
		iow := 125
		Gui, Add, GroupBox, Center xm ym w280 h70 section, Input Axis
		Gui, Add, Text, % "Center xs+5 yp+15 w" iow, Axis
		Gui, Add, Text, % "Center x+10 w" 99 " ys+15", Preview
		this.AddControl("InputAxis", "InputAxis", 0, this.MyInputChangedState.Bind(this), "xs+5 yp+15")
		Gui, Add, Slider, % "hwndhwnd x+10 yp+5 w" iow, 50
		this.hSliderIn := hwnd

		Gui, Add, GroupBox, Center x295 ym w100 h70 section, Settings
		Gui, Add, Text, % "Center xs+5 yp+20", Invert
		Gui, Add, Text, % "Center x+5 yp", Deadzone`%
		this.AddControl("CheckBox", "Invert", 0, "xs+15 yp+20")
		this.AddControl("Edit", "Deadzone", 0, "x+5 yp-3 w30", "20")
		
		Gui, Add, GroupBox, Center x400 ym w270 h70 section, Output Buttons
		Gui, Add, Text, % "Center xs+5 yp+15 w" iow, Low
		Gui, Add, Text, % "Center x+10 w" iow " yp", High
		this.AddControl("OutputButton", "OB1", 0, "xs+5 yp+15")
		this.AddControl("OutputButton", "OB2", 0, "x+5 yp")
	}
	
	; The user moved the selected input axis. Manipulate the output buttons accordingly
	MyInputChangedState(value){
		GuiControl, , % this.hSliderIn, % value
		
		value := UCR.Libraries.StickOps.AHKToInternal(value)
		dz := this.GuiControls.Deadzone.Get()
		if (dz){
			value := UCR.Libraries.StickOps.Deadzone(value, dz)
		}
		if (this.GuiControls.Invert.Get()){
			value := UCR.Libraries.StickOps.Invert(value)
		}
		
		if (value < 0)
			new_state := 1
		else if (value > 0)
			new_state := 2
		else
			new_state := 0
		
		;OutputDebug % "value: " value ", LastState: " this.LastState ", new_state: " new_state

		if (new_state == this.LastState)
			return
		
		; Release the old button
		if (this.LastState != 0)
			this.IOControls["OB" this.LastState].Set(0)
		
		; Press the new button
		if (new_state != 0)
			this.IOControls["OB" new_state].Set(1)
		
		this.LastState := new_state
	}
}
