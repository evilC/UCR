/*
Remaps a physical joystick axis to a virtual joystick axis
Requires the StickOps library and the vJoy library
*/
class AxisToAxis extends _Plugin {
	Type := "Remapper (Axis To Axis)"
	Description := "Maps an axis input to a virtual axis output"
	vAxis := 0
	vDevice := 0
	; Set up the GUI to allow the user to select input and output axes
	Init(){
		Gui, Add, Text, % "xm w125 Center", Input Axis
		Gui, Add, Text, % "x+5 yp w100 Center", Input Preview
		Gui, Add, Text, % "x+5 yp w40 Center", Invert
		Gui, Add, Text, % "x+5 yp w40 Center", Deadzone
		Gui, Add, Text, % "x+5 yp w40 Center", Sensitivity
		Gui, Add, Text, % "x+5 yp w125 Center", Output Virtual Axis
		Gui, Add, Text, % "x+5 yp w100 Center", Output Preview
		
		this.AddInputAxis("InputAxis", 0, this.MyInputChangedState.Bind(this), "xm w125")
		Gui, Add, Slider, % "hwndhwnd x+5 yp w100"
		this.hSliderIn := hwnd
		this.AddControl("Invert", 0, "CheckBox", "x+20 yp+3 w30")
		this.AddControl("Deadzone", 0, "Edit", "x+10 yp-3 w30", "0")
		Gui, Add, Text, % "x+0 yp+3", `%
		this.AddControl("Sensitivity", 0, "Edit", "x+10 yp-3 w30", "100")
		Gui, Add, Text, % "x+0 yp+3", `%
		this.AddOutputAxis("OutputAxis", this.MyOutputChangedValue.Bind(this), "x+15 yp-3 w125")
		Gui, Add, Slider, % "hwndhwnd x+5 yp w100"
		this.hSliderOut := hwnd
	}
	
	; The user changed options - store stick and axis selected for fast retreival
	MyOutputChangedValue(value){
		this.vAxis := value.axis
		this.vDevice := value.DeviceID
	}
	
	; The user moved the selected input axis. Manipulate the output axis accordingly
	MyInputChangedState(value){
		static StickOps := UCR.Libraries.StickOps
		
		GuiControl, , % this.hSliderIn, % value
		value := StickOps.AHKToInternal(value)
		if (this.vAxis && this.vDevice){
			if (this.GuiControls.Deadzone.value){
				value := StickOps.Deadzone(value, this.GuiControls.Deadzone.value)
			}
			if (this.GuiControls.Sensitivity.value){
				value := StickOps.Sensitivity(value, this.GuiControls.Sensitivity.value)
			}
			if (this.GuiControls.Invert.value){
				value := StickOps.Invert(value)
			}
			value := StickOps.InternalToAHK(value)
			GuiControl, , % this.hSliderOut, % value
			value := StickOps.AHKToVjoy(value)
			this.OutputAxes.OutputAxis.SetState(value)
		}
	}
}
