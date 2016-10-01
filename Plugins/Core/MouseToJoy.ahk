/*
Remaps mouse DELTA information (is unconcerned with cursor position, just cares about mouse movement) to joystick output.
Features Absolute and Relative modes
*/
class MouseToJoy extends _UCR.Classes.Plugin {
	Type := "Remapper (Mouse Axis To Joystick Axis)"
	Description := "Converts mouse input delta information into two joystick axes"
	AbsoluteScaleFactor := {x: 10, y: 10}
	AbsoluteTimeout := {x: 10, y: 10}
	RelativeTimeout := {x: 10, y: 10}
	RelativeScaleFactor := {x: 1, y: 1}
	Mode := 2	; 1 = Absolute, 2 = Relative
	SeenMice := {}
	CurrX := 0
	CurrY := 0
	TimerX := 0
	TimerY := 0
	
	Init(){
		title_row := 25
		x_row := 45
		y_row := x_row + 25
		Gui, Add, Text, % "xm y" x_row+3, X AXIS
		Gui, Add, Text, % "xm y" y_row+3, Y AXIS
		
		; Absolute mode
		Gui, Add, GroupBox, % "x50 ym w125 Section h" y_row+25, % "Absolute Mode"
		Gui, Add, Text, % "xs+5 y" title_row, Scale Factor
		this.AddControl("Edit", "AbsoluteScaleX", this.AbsoluteScaleChanged.Bind(this, "X"), "x70 w30 y" x_row, 10)
		;~ Gui, Add, Button, % "x+5 yp hwndhwnd", Calibrate
		;~ fn := this.Calibrate.Bind(this, "X")
		;~ GuiControl +g, % hwnd, % fn
		Gui, Add, Text, % "x120 w40 center y" title_row-5, Timeout
		this.AddControl("Edit", "AbsoluteTimeout", this.TimeoutChanged.Bind(this, "X"), "x120 w40 y" x_row - 10, 50)
		
		Gui, Add, Text, % "x120 w40 center y" y_row - 10, Threshold
		this.AddControl("Edit", "AbsoluteThreshold", this.TimeoutChanged.Bind(this, "X"), "x120 w40 y" y_row + 5, 2)
		
		this.AddControl("Edit", "AbsoluteScaleY", this.AbsoluteScaleChanged.Bind(this, "Y"), "x70 w30 y" y_row, 10)
		;~ Gui, Add, Button, % "x+5 yp hwndhwnd", Calibrate
		;~ fn := this.Calibrate.Bind(this, "Y")
		;~ GuiControl +g, % hwnd, % fn
		;this.AddControl("AbsoluteTimeoutY", this.TimeoutChanged.Bind(this, "Y"), "x120 w40 y" y_row, 50)
		
		; Relative Mode
		Gui, Add, GroupBox, % "x185 ym w115 Section h" y_row+25, % "Relative Mode"
		;Gui, Add, Text, % "x200 w40 center y" title_row, Timeout
		;this.AddControl("RelativeTimeoutX", this.TimeoutChanged.Bind(this, 2, "X"), "x200 w40 y" x_row, 10)
		;this.AddControl("RelativeTimeoutY", this.TimeoutChanged.Bind(this, 2, "Y"), "x200 w40 y" y_row, 10)
		Gui, Add, Text, % "xs+5 center y" title_row, Scale Factor
		this.AddControl("Edit", "RelativeScaleFactorX", this.RelativeScaleChanged.Bind(this, "X"), "xs+5 w45 y" x_row, 1)
		this.AddControl("Edit", "RelativeScaleFactorY", this.RelativeScaleChanged.Bind(this, "Y"), "xs+5 w45 y" y_row, 1)
		
		; Tweaks
		Gui, Add, Text, % "x+25 w20 center y" title_row, Invert
		this.AddControl("CheckBox", "InvertX", 0, "xp+5 y" x_row+3, "", 0)
		this.AddControl("CheckBox", "InvertY", 0, "xp y" y_row+3, "", 0)
		
		; Mouse Selection
		Gui, Add, GroupBox, % "x305 ym w105 Section h" y_row+25, % "Multi-Mouse"
		Gui, Add, Text, % "xs+5 Center w90 y" title_row - 5, Mouse Picker
		Gui, Add, DDL, hwndhSelectMouse xs+5 yp+15 w90, Any||
		fn := this.MouseSelectChanged.Bind(this)
		this.MouseSelectChangedFn := fn
		GuiControl, +g, % hSelectMouse, % fn
		this.hSelectMouse := hSelectMouse
		
		Gui, Add, Text, % "xs+5 Center w90 y+2", Current Mouse
		this.AddControl("Edit", "MouseID", 0, "xs+5 y+2 w90", "")
		
		; Outputs
		this.AddControl("OutputAxis", "OutputAxisX", 0, "x420 w125 y" x_row)
		this.AddControl("OutputAxis", "OutputAxisY", 0, "x420 w125 y" y_row)
		Gui, Add, Slider, % "hwndhwnd x550 y" x_row
		this.hSliderX := hwnd
		Gui, Add, Slider, % "hwndhwnd x550 y" y_row
		this.hSliderY := hwnd
		
		;this.AddControl("AbsoluteRadio", 0, "Radio", "x150 ym",, 1)
		;this.AddControl("RelativeRadio", 0, "Radio", "x270 ym",, 0)
		this.AddControl("DDL", "ModeSelect", this.ModeSelect.Bind(this), "x575 w100 ym AltSubmit", "Mode: Absolute||Mode: Relative")
		
		this.AddControl("InputDelta", "MD1", 0, this.MouseEvent.Bind(this), "xm w200")
		
		;this.MouseTimeoutFn := this.OnMouseTimeout.Bind(this)
		;this.MouseTimeoutFn := this.MouseEvent.Bind(this, {x: 0, y: 0})
	}
	
	OnActive(){
		;this.InputDeltas.MouseDelta.Register()
	}
	
	OnInactive(){
		;this.InputDeltas.MouseDelta.UnRegister()
	}
	
	; Plugin was deleted - stop watching mouse
	OnDelete(){
		;this.MouseDelta.UnRegister()
		;this.MouseDelta := ""
	}
	
	MouseSelectChanged(){
		GuiControlGet, val,, % this.hSelectMouse
		if (val == "Any" || val == 0){
			val := ""
		}
		this.GuiControls.MouseID.Set(val)
		GuiControl, , % this.GuiControls.MouseID.hwnd, % val
	}
	
	;~ Calibrate(axis){
		;~ static state := 0
		;~ if (axis = "x"){
			
		;~ } else {
			
		;~ }
	;~ }
	
	;MouseEvent(x := 0, y := 0){
	MouseEvent(value){
		; The "Range" for a given axis is -50 to +50
		try {
			x := value.axes.x, y := value.axes.y, ax := Abs(x), ay := Abs(y), MouseID := value.MouseID, dox := (x != ""), doy := (y != "")
		} catch {
			; M2J sometimes seems to crash eg when switching from a profile with M2J to a profile without
			; This seems to fix it, but this should probably be properly investigated.
			return
		}
		m_id := this.GuiControls.MouseID.Get()
		if (m_id && m_id != value.MouseID)
			return
		if (this.Mode = 1){
			; Absolute
			threshold := this.GuiControls.AbsoluteThreshold.Get()
			if (dox && ax && ax <= threshold)
				dox := 0
			if (doy && ay && ay <= threshold)
				doy := 0
			if (dox){
				this.CurrX := x * this.AbsoluteScaleFactor.X
			}
			if (doy){
				this.CurrY := y * this.AbsoluteScaleFactor.Y
			}
		} else {
			; Relative
			if (dox){
				if (this.GuiControls.InvertX.Get())
					x *= -1
				this.CurrX += ( x * this.RelativeScaleFactor.X )
				if (this.CurrX > 50)
					this.CurrX := 50
				else if (this.CurrX < -50)
					this.CurrX := -50
			}
			
			if (doy){
				if (this.GuiControls.InvertY.Get())
					y *= -1
				this.CurrY += ( y * this.RelativeScaleFactor.Y )
				if (this.CurrY > 50)
					this.CurrY := 50
				else if (this.CurrY < -50)
					this.CurrY := -50
			}
		}

		if (dox){
			;OutputDebug, % "UCR| x: " this.CurrX " (" UCR.Libraries.StickOps.InternalToAHK(this.CurrX) "), y: " this.CurrY
			ox := this.IOControls.OutputAxisX.GetBinding()
			if (ox.DeviceID && ox.Binding[1]){
				cx := UCR.Libraries.StickOps.InternalToAHK(this.CurrX)
				this.IOControls.OutputAxisX.Set(cx)
				GuiControl, , % this.hSliderX, % cx
			}
		}
		
		if (doy){
			oy := this.IOControls.OutputAxisY.GetBinding()
			if (oy.DeviceID && oy.Binding[1]){
				cy := UCR.Libraries.StickOps.InternalToAHK(this.CurrY)
				this.IOControls.OutputAxisY.Set(cy)
				GuiControl, , % this.hSliderY, % cy
			}
		}
		if (!ObjHasKey(this.SeenMice, MouseID)){
			this.SeenMice[MouseID] := 1
			GuiControl, , % this.hSelectMouse, % MouseID
		}
		
		; In Absolute mode, emulate centering with a timeout
		if (this.Mode = 1){
			if (dox && x != 0){
				if (this.TimerX != 0){
					fn := this.TimerX
					SetTimer, % fn, Off
				}
				fn := this.MouseEvent.Bind(this, {axes: {x: 0}, MouseID: MouseID})
				this.TimerX := fn
				SetTimer, % fn, % "-" this.GuiControls.AbsoluteTimeout.Get()
			}
			if (doy && y != 0){
				if (this.TimerY != 0){
					fn := this.TimerY
					SetTimer, % fn, Off
				}
				fn := this.MouseEvent.Bind(this, {axes: {y: 0}, MouseID: MouseID})
				this.TimerY := fn
				SetTimer, % fn, % "-" this.GuiControls.AbsoluteTimeout.Get()
			}
		}
	}
	
	OnMouseTimeout(){
		this.MouseEvent({x: 0, y: 0})
	}
	
	ModeSelect(value){
		this.Mode := value
	}
	
	; === Absolute Mode variable changed
	AbsoluteScaleChanged(axis, value){
		;this.AbsoluteScaleFactor[axis] := 100 / value
		this.AbsoluteScaleFactor[axis] := value
	}
	
	TimeoutChanged(axis, value){
		this.AbsoluteTimeout[axis] := value
		;this.MouseDelta.SetTimeOut(value)
	}
	
	; === Relative Mode variable changed
	RelativeScaleChanged(axis, value){
		this.RelativeScaleFactor[axis] := value
	}
}