/*


*/
class ButtonsToAxis extends _UCR.Classes.Plugin {
	Type := "Remapper (Buttons To Axis)"
	Description := "Remaps two InputButtons to one OutputAxis"
	
	AxisButtonStates := [0,0]
	DeflectionValues := []
	
	Init(){
		iow := 125
		Gui, Add, GroupBox, Center xm ym w270 h70 section, Input Buttons
		Gui, Add, Text, % "Center xs+5 yp+15 w" iow, Low
		Gui, Add, Text, % "Center x+10 w" iow " yp", High
		this.AddControl("InputButton", "IB1", 0, this.ButtonInput.Bind(this, 1), " xs+5 yp+15")
		this.AddControl("InputButton", "IB2", 0, this.ButtonInput.Bind(this, 2), "x+10 yp")

		Gui, Add, GroupBox, Center x290 ym w100 h70 section, Settings
		Gui, Add, Text, % "Center xs+5 yp+25 w90", Deflection `%
		this.AddControl("Edit", "DeflectionAmount", this.DeflectionChanged.Bind(this), "xs+5 w90 yp+15", 100)
		
		Gui, Add, GroupBox, Center x400 ym w270 h70 section, Output Axis
		Gui, Add, Text, % "Center xs+5 yp+15 w" iow, Axis
		Gui, Add, Text, % "Center x+10 w" iow " yp", Preview
		this.AddControl("OutputAxis", "OA1", 0, "xs+5 yp+15")
		Gui, Add, Slider, % "hwndhwnd x+10 yp", 50
		this.hSlider := hwnd
	}
	
	DeflectionChanged(pc){
		value := 50 * (pc / 100)
		this.DeflectionValues[1] := UCR.Libraries.StickOps.InternalToAHK(value * -1)
		this.DeflectionValues[2] := UCR.Libraries.StickOps.InternalToAHK(value)
	}
	
	; One of the input buttons was pressed or released
	ButtonInput(direction, value){
		;OutputDebug % "UCR| Axis: " axis ", Direction: " direction ", value: " value
		if (this.AxisButtonStates[direction] = value)
			return	; filter repeats
		
		this.AxisButtonStates[direction] := value

		if (this.AxisButtonStates[1] == this.AxisButtonStates[2]){
			out := 50
		} else {
			if (this.AxisButtonStates[1]){
				out := this.DeflectionValues[1]
			} else {
				out := this.DeflectionValues[2]
			}
		}
		this.IOControls.OA1.Set(out)
		GuiControl, , % this.hSlider, % out
	}
}