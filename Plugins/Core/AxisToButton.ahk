/*
Remaps a physical joystick axis to a pair of button outputs
Requires the StickOps library and the vJoy library
*/
class AxisToButton extends _UCR.Classes.Plugin {
	Type := "Remapper (Axis To Button)"
	Description := "Maps a joystick axis input to a pair of button outputs"
	LastState := 0
	; Set up the GUI to allow the user to select inputs and outputs
	Init(){
		Gui, Add, Text, % "xm w125 Center", Input Axis
		Gui, Add, Text, % "x+5 yp w100 Center", Input Preview
		Gui, Add, Text, % "x+5 yp w40 Center", Invert
		Gui, Add, Text, % "x+5 yp w40 Center", Deadzone
		Gui, Add, Text, % "x+25 yp w150 Center", Output Button 1
		Gui, Add, Text, % "x+5 yp w150 Center", Output Button 2
		
		this.AddControl("InputAxis", "InputAxis", 0, this.MyInputChangedState.Bind(this), "xm w125")
		Gui, Add, Slider, % "hwndhwnd x+5 yp w100"
		this.hSliderIn := hwnd
		this.AddControl("CheckBox", "Invert", 0, "x+20 yp+3 w30")
		this.AddControl("Edit", "Deadzone", 0, "x+10 yp-3 w30", "20")
		Gui, Add, Text, % "x+0 yp+3", `%
		this.AddControl("OutputButton", "OB1", 0, "x+25 yp-2 w150")
		this.AddControl("OutputButton", "OB2", 0, "x+5 yp-2 w150")
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
