/*


*/
class ButtonsToAxis extends _UCR.Classes.Plugin {
	Type := "Remapper (Buttons To Axis)"
	Description := "Remaps two InputButtons to one OutputAxis"
	
	AxisButtonStates := [0,0]
	DeflectionValues := []
	IncrementalMode := 0
	
	Init(){
		iow := 125
		Gui, Add, GroupBox, Center xm ym w270 h70 section, Input Buttons
		Gui, Add, Text, % "Center xs+5 yp+15 w" iow, Low
		Gui, Add, Text, % "Center x+10 w" iow " yp", High
		this.AddControl("InputButton", "IB1", 0, this.ButtonInput.Bind(this, 1), " xs+5 yp+15")
		this.AddControl("InputButton", "IB2", 0, this.ButtonInput.Bind(this, 2), "x+10 yp")

		Gui, Add, GroupBox, Center x285 ym w120 h70 section, Settings
		Gui, Add, Text, % "Center xs+5 yp+15 w110", Deflection `%
		this.AddControl("Edit", "DeflectionAmount", this.DeflectionChanged.Bind(this), "xs+5 w110 yp+15", 100)
		this.AddControl("CheckBox", "IncrementalMode", this.IncrementalModeChanged.Bind(this), "xp y+3", "Incremental Mode")
		
		Gui, Add, GroupBox, Center x410 ym w260 h70 section, Output Axis
		Gui, Add, Text, % "Center xs+5 yp+15 w" iow, Axis
		Gui, Add, Text, % "Center x+0 w" iow " yp", Preview
		this.AddControl("OutputAxis", "OA1", 0, "xs+5 yp+15")
		Gui, Add, Slider, % "hwndhwnd x+0 yp", 50
		this.hSlider := hwnd
	}
	
	DeflectionChanged(pc){
		value := 50 * (pc / 100)
		this.IncrementalDeflectionValues[1] := value * -1
		this.IncrementalDeflectionValues[2] := value
		this.DeflectionValues[1] := UCR.Libraries.StickOps.InternalToAHK(value * -1)
		this.DeflectionValues[2] := UCR.Libraries.StickOps.InternalToAHK(value)
	}
	
	IncrementalModeChanged(state){
		this.IncrementalMode := state
	}
	
	; One of the input buttons was pressed or released
	ButtonInput(direction, value){
		;OutputDebug % "UCR| Axis: " axis ", Direction: " direction ", value: " value
		if (!this.IncrementalMode && this.AxisButtonStates[direction] = value)
			return	; filter repeats if not in Incremental Mode
		
		this.AxisButtonStates[direction] := value
		
		if (this.IncrementalMode){
			; Incremental Mode - alter current axis by deflection value on press
			if (!value)
				return	; Do nothing on release
			out := this.IOControls.OA1.Get() + this.IncrementalDeflectionValues[direction]
		} else {
			; Normal Mode - Set axis to deflection value on press, set to middle on release
			if (this.AxisButtonStates[1] == this.AxisButtonStates[2]){
				out := 50
			} else {
				if (this.AxisButtonStates[1]){
					out := this.DeflectionValues[1]
				} else {
					out := this.DeflectionValues[2]
				}
			}
		}
		this.IOControls.OA1.Set(out)
		GuiControl, , % this.hSlider, % out
	}
}