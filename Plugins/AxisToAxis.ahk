/*
Remaps a physical joystick axis to a virtual joystick axis
*/
class AxisToAxis extends _Plugin {
	vAxis := 0
	vDevice := 0
	; Set up the GUI to allow the user to select input and output axes
	Init(){
		Gui, Add, Text, % "xm w150 Center", Input Axis
		Gui, Add, Text, % "x+5 yp w100 Center", Input Preview
		Gui, Add, Text, % "x+5 yp w40 Center", Invert
		Gui, Add, Text, % "x+5 yp w150 Center", Output Virtual Axis
		Gui, Add, Text, % "x+5 yp w100 Center", Output Preview
		this.AddInputAxis("InputAxis", 0, this.MyInputChangedState.Bind(this), "xm w150")
		Gui, Add, Slider, % "hwndhwnd x+5 yp w100"
		this.hSliderIn := hwnd
		this.AddControl("Invert", this.MyEditChanged.Bind(this), "CheckBox", "x+20 yp+3 w30")
		this.AddOutputAxis("OutputAxis", this.MyOutputChangedValue.Bind(this), "x+5 w150 yp-3")
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
		GuiControl, , % this.hSliderIn, % value
		if (this.vAxis && this.vDevice){
			if (this.GuiControls.Invert.value){
				value -= 50
				value := value * -1
				value += 50
			}
			GuiControl, , % this.hSliderOut, % value
			value := UCR.Libraries.vJoy.PercentTovJoy(value)
			UCR.Libraries.vJoy.Devices[this.vDevice].SetAxisByIndex(value, this.vAxis)
		}
	}
}