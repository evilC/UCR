/*
Remaps mouse DELTA information (is unconcerned with cursor position, just cares about mouse movement) to joystick output.
Features Absolute and Relative modes
*/
class MouseToButtons extends _UCR.Classes.Plugin {
	Type := "Remapper (Mouse Axis To Buttons)"
	Description := "Converts mouse input delta information into button presses"
	RelativeTimeout := 10
	StateChangeTime := 50
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
		Gui, Add, GroupBox, % "Center xm ym w90 Section h" y_row+35, % "Timing"
		Gui, Add, Text, % "xs+5 center y" title_row, Center Timeout
		this.AddControl("Edit", "RelativeTimeout", this.TimeoutChanged.Bind(this), "xs+5 w40 y" x_row + 10, 300)
		Gui, Add, Text, % "x+5 yp+5 ", ms
		
		Gui, Add, Text, % "xs+5 center y+5", State Change
		this.AddControl("Edit", "StateChangeTime", this.StateChangeTimeChanged.Bind(this), "xs+5 w40 y+5", 300)
		Gui, Add, Text, % "x+5 yp+5 ", ms
		
		Gui, Add, GroupBox, % "Center x110 ym w60 Section h" y_row+35, % "Limits"
		Gui, Add, Text, % "xs+5 w40 center y" title_row, Min
		this.AddControl("Edit", "MinDelta", this.MinChanged.Bind(this), "xs+5 w40 y" x_row + 10, 2)
		
		Gui, Add, Text, % "xs+5 w40 center y" y_row, Max
		this.AddControl("Edit", "MaxDelta", this.MaxChanged.Bind(this), "xs+5 w40 y" y_row + 15, "")
		
		; Mouse Selection
		Gui, Add, GroupBox, % "x180 ym w110 Section h" y_row+35, % "Input"
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
		
		this.OutputButtons["x", "Low"] := new this.StateChangeSlower(0, this.StateChangeTime, this.SetButtonState.Bind(this, "OutputButtonXLow"))
		this.OutputButtons["x", "High"] := new this.StateChangeSlower(0, this.StateChangeTime, this.SetButtonState.Bind(this, "OutputButtonXHigh"))
		this.OutputButtons["y", "Low"] := new this.StateChangeSlower(0, this.StateChangeTime, this.SetButtonState.Bind(this, "OutputButtonYLow"))
		this.OutputButtons["y", "High"] := new this.StateChangeSlower(0, this.StateChangeTime, this.SetButtonState.Bind(this, "OutputButtonYHigh"))
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
	
	StateChangeTimeChanged(value){
		static Axes := {x: 1, y: 1}
		this.StateChangeTime := value
		for axis in axes {
			this.OutputButtons[axis].Low.SetDuration(value)
			this.OutputButtons[axis].High.SetDuration(value)
		}
	}
	
	MouseEvent(value){
		static Axes := {x: 1, y: 1}
		;~ static Axes := {x: 1}
		;~ static Axes := {y: 1}

		str := ""

		for axis, unused in Axes {
			axis_val := value.axes[axis]
			if (axis_val == "")
				continue
			MouseID := value.MouseID
			
			;~ str .= axis ": " axis_val ", "

			is_in_range := this.IsWithinRange(axis_val, this.Min, this.Max)
			;OutputDebug % "UCR| " axis " value: " axis_val ", in range: " is_in_range ", current Low: " this.LowButtonStates[axis] ", current High: " this.HighButtonStates[axis]
			if (axis_val <= 0){
				if (this.LowButtonStates[axis] && !is_in_range){
					this.LowButtonStates[axis] := 0
					this.OutputButtons[axis, "Low"].ChangeState(0)
					;~ str .= ", Releasing Low " axis
				} else if (!this.LowButtonStates[axis] && is_in_range){
					this.LowButtonStates[axis] := 1
					this.OutputButtons[axis, "Low"].ChangeState(1)
					;~ str .= ", Pressing Low " axis
				}
			}
			if (axis_val >= 0) {
				if (this.HighButtonStates[axis] && !is_in_range){
					this.HighButtonStates[axis] := 0
					this.OutputButtons[axis, "High"].ChangeState(0)
					;~ str .= ", Releasing High " axis
				} else if (!this.HighButtonStates[axis] && is_in_range){
					this.HighButtonStates[axis] := 1
					this.OutputButtons[axis, "High"].ChangeState(1)
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
				;~ str .= ", Starting " axis " Timer - " this.RelativeTimeout
				axobj := {}
				axobj[axis] := 0
				fn := this.MouseEvent.Bind(this, {axes: axobj, MouseID: MouseID})
				this.Timers[axis] := fn
				SetTimer, % fn, % "-" this.RelativeTimeout
			}
		}
		;~ OutputDebug % "UCR| Packet: " str
	}

	SetButtonState(ob, value){
		this.IOControls[ob].Set(value)
	}
	
	Class StateChangeSlower{
		__New(state, dur, callback){
			this.TimerRunning := 0
			this.ChangeStateFn := this._ChangeState.Bind(this)
			this.Callback := callback
			this.State := state
			this.SetDuration(dur)
		}
		
		SetDuration(dur){
			this.DurStr := "-" dur
		}
		
		; Change of state requested
		ChangeState(state){
			fn := this.ChangeStateFn
			if (this.State == state){
				; Requested change to current state
				if (this.TimerRunning){
					; We are currently trying to change out of this state, so cancel request
					SetTimer, % fn, Off
					this.TimerRunning := 0
				}
				return
			} else if (this.TimerRunning){
				; We are already tring to change to this state, do nothing
				return
			}
			; If we managed to get this far, we want to change to a different state, and the timer is not running
			this.TimerRunning := 1
			SetTimer, % fn, % this.DurStr
		}
		
		; Actually changes state
		_ChangeState(){
			this.TimerRunning := 0
			this.State := !this.State
			this.Callback.Call(this.state)
		}
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
	
	TimeoutChanged(value){
		this.RelativeTimeout := value
		;this.MouseDelta.SetTimeOut(value)
	}
	
	; === Absolute Mode variable changed
	AbsoluteScaleChanged(axis, value){
		this.AbsoluteScaleFactor[axis] := value
	}
}