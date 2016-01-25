/*
Remaps a physical joystick axis to a pair of button outputs
Requires the StickOps library and the vJoy library
*/
class AxisToButton extends _Plugin {
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
		
		this.AddInputAxis("InputAxis", 0, this.MyInputChangedState.Bind(this), "xm w125")
		Gui, Add, Slider, % "hwndhwnd x+5 yp w100"
		this.hSliderIn := hwnd
		this.AddControl("Invert", 0, "CheckBox", "x+20 yp+3 w30")
		this.AddControl("Deadzone", 0, "Edit", "x+10 yp-3 w30", "20")
		Gui, Add, Text, % "x+0 yp+3", `%
		this.AddOutputButton("OB1", 0, "x+25 yp-2 w150")
		this.AddOutputButton("OB2", 0, "x+5 yp-2 w150")
	}
	
	; The user moved the selected input axis. Manipulate the output buttons accordingly
	MyInputChangedState(value){
		static StickOps := UCR.Libraries.StickOps
		
		GuiControl, , % this.hSliderIn, % value
		
		value := StickOps.AHKToInternal(value)
		if (this.GuiControls.Deadzone.value){
			value := StickOps.Deadzone(value, this.GuiControls.Deadzone.value)
		}
		if (this.GuiControls.Invert.value){
			value := StickOps.Invert(value)
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
			this.OutputButtons["OB" this.LastState].SetState(0)
		
		; Press the new button
		if (new_state != 0)
			this.OutputButtons["OB" new_state].SetState(1)
		
		this.LastState := new_state
	}
}
