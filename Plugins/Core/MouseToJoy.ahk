class MouseToJoy extends _Plugin {
	Type := "Mouse Axis To Joystick Axis"
	Description := "Converts mouse input delta information into two joystick axes"
	AbsoluteThresholdFactor := {x: 10, y: 10}
	AbsoluteTimeout := {x: 10, y: 10}
	RelativeTimeout := {x: 10, y: 10}
	RelativeScaleFactor := {x: 1, y: 1}
	Mode := 2	; 1 = Absolute, 2 = Relative
	
	Init(){
		title_row := 25
		x_row := 45
		y_row := x_row + 25
		;Gui, Add, Text, y+5 , Absolute Mode threshold
		Gui, Add, Text, % "xm y" x_row+3, X AXIS
		Gui, Add, Text, % "xm y" y_row+3, Y AXIS
		
		; Absolute mode
		Gui, Add, GroupBox, % "x50 ym w125 h" y_row+25, % "Absolute Mode"
		Gui, Add, Text, % "x60 y" title_row, Threshold
		this.AddControl("AbsoluteThresholdX", this.ThresholdChanged.Bind(this, "X"), "Edit", "x70 w30 y" x_row, 10)
		;~ Gui, Add, Button, % "x+5 yp hwndhwnd", Calibrate
		;~ fn := this.Calibrate.Bind(this, "X")
		;~ GuiControl +g, % hwnd, % fn
		Gui, Add, Text, % "x120 w40 center y" title_row, Timeout
		this.AddControl("AbsoluteTimeoutX", this.TimeoutChanged.Bind(this, "X"), "Edit", "x120 w40 y" x_row, 10)
		
		this.AddControl("AbsoluteThresholdY", this.ThresholdChanged.Bind(this, "Y"), "Edit", "x70 w30 y" y_row, 10)
		;~ Gui, Add, Button, % "x+5 yp hwndhwnd", Calibrate
		;~ fn := this.Calibrate.Bind(this, "Y")
		;~ GuiControl +g, % hwnd, % fn
		this.AddControl("AbsoluteTimeoutY", this.TimeoutChanged.Bind(this, "Y"), "Edit", "x120 w40 y" y_row, 10)
		
		; Relative Mode
		Gui, Add, GroupBox, % "x185 ym w200 h" y_row+25, % "Relative Mode"
		;Gui, Add, Text, % "x200 w40 center y" title_row, Timeout
		;this.AddControl("RelativeTimeoutX", this.TimeoutChanged.Bind(this, 2, "X"), "Edit", "x200 w40 y" x_row, 10)
		;this.AddControl("RelativeTimeoutY", this.TimeoutChanged.Bind(this, 2, "Y"), "Edit", "x200 w40 y" y_row, 10)
		Gui, Add, Text, % "x200 w40 center y" title_row-5, Scale Factor
		this.AddControl("RelativeScaleFactorX", this.ScaleFactorChanged.Bind(this, "X"), "Edit", "x200 w40 y" x_row, 1)
		this.AddControl("RelativeScaleFactorY", this.ScaleFactorChanged.Bind(this, "Y"), "Edit", "x200 w40 y" y_row, 1)
		
		; Outputs
		this.AddOutputAxis("OutputAxisX", 0, "x420 w125 y" x_row)
		this.AddOutputAxis("OutputAxisY", 0, "x420 w125 y" y_row)
		Gui, Add, Slider, % "hwndhwnd x550 y" x_row
		this.hSliderX := hwnd
		Gui, Add, Slider, % "hwndhwnd x550 y" y_row
		this.hSliderY := hwnd
		
		;this.AddControl("AbsoluteRadio", 0, "Radio", "x150 ym",, 1)
		;this.AddControl("RelativeRadio", 0, "Radio", "x270 ym",, 0)
		this.AddControl("ModeSelect", this.ModeSelect.Bind(this), "DDL", "x575 w100 ym AltSubmit", "Mode: Absolute||Mode: Relative")
		this.MouseDelta := new UCR.MouseDelta(this.MouseEvent.Bind(this))
	}
	
	OnActive(){
		this.MouseDelta.Register()
	}
	
	OnInactive(){
		this.MouseDelta.UnRegister()
	}
	
	;~ Calibrate(axis){
		;~ static state := 0
		;~ if (axis = "x"){
			
		;~ } else {
			
		;~ }
	;~ }
	
	MouseEvent(x := 0, y := 0){
		; The "Range" for a given axis is -50 to +50
		static curr_x := 0, curr_y := 0
		static StickOps := UCR.Libraries.StickOps
		
		if (this.Mode = 1){
			curr_x := x * this.AbsoluteThresholdFactor.X
			curr_y := y * this.AbsoluteThresholdFactor.Y
		} else {
			curr_x += ( x * this.RelativeScaleFactor.X )
			if (curr_x > 50)
				curr_x := 50
			else if (curr_x < -50)
				curr_x := -50
			curr_y += ( y * this.RelativeScaleFactor.Y )
			if (curr_y > 50)
				curr_y := 50
			else if (curr_y < -50)
				curr_y := -50
		}
		;OutputDebug, % "x: " curr_x " (" StickOps.InternalToAHK(curr_x) "), y: " curr_y
		this.OutputAxes.OutputAxisX.SetState(StickOps.InternalToVjoy(curr_x))
		this.OutputAxes.OutputAxisY.SetState(StickOps.InternalToVjoy(curr_y))
		GuiControl, , % this.hSliderX, % StickOps.InternalToAHK(curr_x)
		GuiControl, , % this.hSliderY, % StickOps.InternalToAHK(curr_y)
	}
	
	ModeSelect(value){
		this.Mode := value
	}
	
	; === Absolute Mode variable changed
	ThresholdChanged(axis, value){
		this.AbsoluteThresholdFactor[axis] := 100 / value
	}
	
	TimeoutChanged(axis, value){
		this.AbsoluteTimeout[axis] := value
		this.MouseDelta.SetTimeOut(value)
	}
	
	; === Relative Mode variable changed
	ScaleFactorChanged(axis, value){
		this.RelativeScaleFactor[axis] := value
	}
}