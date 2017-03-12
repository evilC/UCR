/*
Remaps mouse DELTA information (is unconcerned with cursor position, just cares about mouse movement) to joystick output.
Features Absolute and Relative modes
*/
class MouseToButtons extends _UCR.Classes.Plugin {
	Type := "Remapper (Mouse Axis To Buttons)"
	Description := "Converts mouse input delta information into button presses"
	RelativeTimeout := {x: 10, y: 10}
	Timers := {x: 0, y: 0}
	LowButtonStates := {x: 0, y: 0}
	HighButtonStates := {x: 0, y: 0}
	Min := ""
	Max := ""
	
	OutputButtons := {x: {}, y: {}}
	
	Init(){
		title_row := 25
		x_row := 35
		y_row := x_row + 40
		mid_point:= (x_row + (y_row - x_row))
		Gui, Add, GroupBox, % "Center xm ym w60 Section h" y_row+35, % "Centering"
		Gui, Add, Text, % "xs+5 w40 center y" title_row, Timeout
		this.AddControl("Edit", "RelativeTimeout", this.TimeoutChanged.Bind(this, "X"), "xs+5 w40 y" x_row + 10, 300)
		
		Gui, Add, GroupBox, % "Center x80 ym w60 Section h" y_row+35, % "Limits"
		Gui, Add, Text, % "xs+5 w40 center y" title_row, Min
		this.AddControl("Edit", "MinDelta", this.MinChanged.Bind(this), "xs+5 w40 y" x_row + 10, 2)
		
		Gui, Add, Text, % "xs+5 w40 center y" y_row, Max
		this.AddControl("Edit", "MaxDelta", this.MaxChanged.Bind(this), "xs+5 w40 y" y_row + 15, "")
		
		; Mouse Selection
		Gui, Add, GroupBox, % "x150 ym w110 Section h" y_row+35, % "Input"
		this.AddControl("InputDelta", "MD1", 0, this.MouseEvent.Bind(this), "xs+5 w100 y" mid_point - 18 )
		
		; Outputs
		Gui, Add, Text, % "x300 y" x_row+12, X AXIS
		Gui, Add, Text, % "xp y" y_row+12, Y AXIS
		Gui, Add, GroupBox, % "x+5 ym w330 Section h" y_row+35, % "Outputs"
		this.AddControl("OutputButton", "OutputButtonXLow", 0, "xs+5 w125 y" x_row)
		this.AddControl("ButtonPreview", "", 0, this.IOControls.OutputButtonXLow, "x+5 y" x_row + 5, 50)
		this.AddControl("OutputButton", "OutputButtonXHigh", 0, "x+5 y" x_row)
		this.AddControl("ButtonPreview", "", 0, this.IOControls.OutputButtonXHigh, "x+5 y" x_row + 5, 50)

		this.AddControl("OutputButton", "OutputButtonYLow", 0, "xs+5 w125 y" y_row)
		this.AddControl("ButtonPreview", "", 0, this.IOControls.OutputButtonYLow, "x+5 y" y_row + 5, 50)
		this.AddControl("OutputButton", "OutputButtonYHigh", 0, "x+5 w125 yp")
		this.AddControl("ButtonPreview", "", 0, this.IOControls.OutputButtonYHigh, "x+5 y" y_row + 5, 50)
		
		this.OutputButtons["x", "Low"] := this.IOControls.OutputButtonXLow
		this.OutputButtons["x", "High"] := this.IOControls.OutputButtonXHigh
		this.OutputButtons["y", "Low"] := this.IOControls.OutputButtonYLow
		this.OutputButtons["y", "High"] := this.IOControls.OutputButtonYHigh
	}
	
	OnActive(){
		;this.InputDeltas.MouseDelta.Register()
	}
	
	OnInactive(){
		;this.InputDeltas.MouseDelta.UnRegister()
	}
	
	MinChanged(value){
		this.Min := value
	}
	
	MaxChanged(value){
		this.Max := Value
	}
	
	MouseEvent(value){
		static Axes := {x: 1, y: 1}
		;~ static Axes := {x: 1}

		str := ""

		for axis, unused in Axes {
			axis_val := value.axes[axis]
			if (axis_val == "")
				continue
			MouseID := value.MouseID
			
			str .= axis ": " axis_val ", "

			is_in_range := this.IsWithinRange(axis_val, this.Min, this.Max)
			;OutputDebug % "UCR| " axis " value: " axis_val ", in range: " is_in_range ", current Low: " this.LowButtonStates[axis] ", current High: " this.HighButtonStates[axis]
			if (axis_val <= 0){
				if (this.LowButtonStates[axis] && !is_in_range){
					this.LowButtonStates[axis] := 0
					this.OutputButtons[axis, "Low"].Set(0)
					;~ str .= ", Releasing Low " axis
				} else if (!this.LowButtonStates[axis] && is_in_range){
					this.LowButtonStates[axis] := 1
					this.OutputButtons[axis, "Low"].Set(1)
					;~ str .= ", Pressing Low " axis
				}
			}
			if (axis_val >= 0) {
				if (this.HighButtonStates[axis] && !is_in_range){
					this.HighButtonStates[axis] := 0
					this.OutputButtons[axis, "High"].Set(0)
					;~ str .= ", UCR| Releasing High " axis
				} else if (!this.HighButtonStates[axis] && is_in_range){
					this.HighButtonStates[axis] := 1
					this.OutputButtons[axis, "High"].Set(1)
					;~ str .= ", Pressing High " axis
				}
			}
			
			if (axis_val == 0 && this.Timers[axis] != 0){
				fn := this.Timers[axis]
				SetTimer, % fn, Off
				this.Timers[axis] := 0
				;~ str .= ", Stopping " axis " Timer"
			}
			
			;~ ; emulate centering with a timeout
			if (axis_val && this.Timers[axis] == 0){
				;~ str .= ", Starting " axis " Timer"
				axobj := {}
				axobj[axis] := 0
				fn := this.MouseEvent.Bind(this, {axes: axobj, MouseID: MouseID})
				this.Timers[axis] := fn
				SetTimer, % fn, % "-" this.RelativeTimeout[axis]
			}
		}
		;~ OutputDebug % "UCR| Packet: " str
	}
	
	IsWithinRange(value, Min := "", Max := ""){
		if (!value)
			return 0
		av := abs(value)
		return (Min == "" || av >= Min) && (Max == "" || av <= Max)
	}
	
	OnMouseTimeout(){
		this.MouseEvent({x: 0, y: 0})
	}
	
	ModeSelect(value){
		this.Mode := value
	}
	
	; === Relative Mode variable changed
	RelativeScaleChanged(axis, value){
		;this.RelativeScaleFactor[axis] := 100 / value
		this.RelativeScaleFactor[axis] := value
	}
	
	TimeoutChanged(axis, value){
		this.RelativeTimeout[axis] := value
		;this.MouseDelta.SetTimeOut(value)
	}
	
	; === Absolute Mode variable changed
	AbsoluteScaleChanged(axis, value){
		this.AbsoluteScaleFactor[axis] := value
	}
}