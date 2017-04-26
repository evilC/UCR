/*


*/
class ButtonsToAxis extends _UCR.Classes.Plugin {
	Type := "Remapper (Buttons To Axis)"
	Description := "Remaps two InputButtons to one OutputAxis"
	
	AxisButtonStates := [0,0]
	DeflectionValues := []
	IncrementalMode := 0
	MidPoint := 50
	
	Init(){
		iow := 125
		Gui, Add, GroupBox, Center xm ym w270 h85 section, Input Buttons
		Gui, Add, Text, % "Center xs+5 yp+30 w" iow, Low
		Gui, Add, Text, % "Center x+10 w" iow " yp", High
		this.AddControl("InputButton", "IB1", 0, this.ButtonInput.Bind(this, 1), " xs+5 yp+15")
		this.AddControl("ButtonPreviewThin", "", 0, this.IOControls.IB1, "x+0 yp")
		this.AddControl("InputButton", "IB2", 0, this.ButtonInput.Bind(this, 2), "x+5 yp")
		this.AddControl("ButtonPreviewThin", "", 0, this.IOControls.IB2, "x+0 yp")

		Gui, Add, GroupBox, Center x285 ym w120 h85 section, Settings
		Gui, Add, Text, % "Center xs+5 yp+15 w110", Deflection `%
		Gui, Add, Text, % "Center xs+5 yp+15 w30", Low
		Gui, Add, Text, % "Center x+5 yp w30", Mid
		Gui, Add, Text, % "Center x+5 yp w30", High
		this.AddControl("Edit", "DeflectionLow", this.DeflectionChanged.Bind(this, 1), "xs+5 w30 yp+15", 0)
		this.AddControl("Edit", "DeflectionMid", this.DeflectionChanged.Bind(this, 0), "x+5 w30 yp", 50)
		this.AddControl("Edit", "DeflectionHigh", this.DeflectionChanged.Bind(this, 2), "x+5 w30 yp", 100)
		this.AddControl("CheckBox", "IncrementalMode", this.IncrementalModeChanged.Bind(this), "xs+5 y+3", "Incremental Mode")
		
		Gui, Add, GroupBox, Center x410 ym w260 h85 section, Output Axis
		Gui, Add, Text, % "Center xs+5 yp+30 w" iow, Axis
		Gui, Add, Text, % "Center x+0 w" iow " yp", Preview
		this.AddControl("OutputAxis", "OA1", 0, "xs+5 yp+15")
		this.AddControl("AxisPreview", "", 0, this.IOControls.OA1, "x+0 yp", 50)
	}
	
	OnActive(){
		if (!this.IncrementalMode){
			this.SetState(this.MidPoint)
		}
	}
	
	DeflectionChanged(dir, pc){
		static sgn := [-1,1]
		if (dir){
			this.DeflectionValues[dir] := pc
			this.IncrementalDeflectionValues[dir] := pc * sgn[dir]
		} else {
			; Set mid-point
			this.MidPoint := pc
		}
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
				out := this.MidPoint
			} else {
				if (this.AxisButtonStates[1]){
					out := this.DeflectionValues[1]
				} else {
					out := this.DeflectionValues[2]
				}
			}
		}
		this.SetState(out)
	}
	
	SetState(out){
		this.IOControls.OA1.Set(out)
	}
}