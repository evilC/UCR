/*


*/
class ButtonToAxis extends _Plugin {
	Type := "Remapper (Button To Axis)"
	Description := "Remaps up to four button inputs (eg WSAD, a stick POV hat) to two virtual joystick axes"
	
	AxisButtonStates := {x: [0,0], y: [0,0]}
	
	Init(){
		iw := 125
		ow := 125
		c1 := 5
		c2 := c1 + iw + 5
		c3 := c2 + iw + 5
		c4 := c3 + iw + 35
		c5 := c4 + ow + 5
		Gui, Add, Text, % "center x" c1 " w" (c3 + iw) - c1, Input Buttons
		Gui, Add, Text, % "center yp x" c4 " w" ow, Output Axes
		Gui, Add, Text, % "center yp x" c5 " w" ow, Axis Preview
		
		this.AddInputButton("Up", 0, this.AxisInput.Bind(this, "y", 1), " x" c2 " w" iw)
		this.AddOutputAxis("OutputAxisX", 0, "x" c4 " w" ow " yp")
		Gui, Add, Slider, % "hwndhwnd x" c5 " yp", 50
		this.hSliderX := hwnd
		Gui, Add, Text, % "yp+3 w10 x" c4 - 15, X
		
		this.AddInputButton("Left", 0, this.AxisInput.Bind(this, "x", 1), "x" c1 " w" iw)
		this.AddInputButton("Down", 0, this.AxisInput.Bind(this, "y", 2), "x" c2 " yp w" iw)
		this.AddInputButton("Right", 0, this.AxisInput.Bind(this, "x", 2), "x" c3 " yp w" iw)
		this.AddOutputAxis("OutputAxisY", 0, "x" c4 " w" ow " yp")
		Gui, Add, Slider, % "hwndhwnd x" c5 " yp", 50
		this.hSliderY := hwnd
		Gui, Add, Text, % "yp+3 w10 x" c4 - 15, Y

	}
	
	; One of the input buttons was pressed or released
	AxisInput(axis, direction, value){
		static StickOps := UCR.Libraries.StickOps
		;static axis_lookup := {x: "OutputAxisX", y: "OutputAxisY"}
		
		OutputDebug % "Axis: " axis ", Direction: " direction ", value: " value
		if (this.AxisButtonStates[axis, direction] = value)
			return	; filter repeats
		
		this.AxisButtonStates[axis, direction] := value

		if (this.AxisButtonStates[axis].1 == this.AxisButtonStates[axis].2){
			out := 0
		} else {
			if (this.AxisButtonStates[axis].1){
				out := -50
			} else {
				out := 50
			}
		}
		this.OutputAxes["OutputAxis" axis].SetState(StickOps.InternalToVjoy(out))
		GuiControl, , % this["hSlider" axis], % StickOps.InternalToAHK(out)
	}
}