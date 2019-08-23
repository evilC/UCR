class ButtonsToMouse extends _UCR.Classes.Plugin {
	Type := "Remapper (Buttons To Mouse)"
	Description := "Maps two input buttons to a mouse axis"
	
	AxisStates := {x: 0, y: 0}
	MouseIsMoving := 0
	InputStates := {-1: 0, 1: 0}
	
	; Set up the GUI
	Init(){
		Gui, Add, Text, % "xm w155 Center", Input Button Low
		Gui, Add, Text, % "x+5 w155 Center", Input Button High
		Gui, Add, Text, % "x+5 w50 Center", Mouse`nAxis
		Gui, Add, Text, % "x+5 w50 Center", Mouse`nMove Min
		Gui, Add, Text, % "x+5 w50 Center", Multiply`ntime (ms)
		Gui, Add, Text, % "x+5 w50 Center", Multiply`namount
		Gui, Add, Text, % "x+5 w50 Center", Mouse`nMove Max
		this.AddControl("InputButton", "IB1", 0, this.MyInputChangedState.Bind(this, -1), "xm w125")
		this.AddControl("ButtonPreview", "", 0, this.IOControls.IB1, "x+5 yp+5", 50)
		this.AddControl("InputButton", "IB2", 0, this.MyInputChangedState.Bind(this, 1), "x+5 yp-5 w125")
		this.AddControl("ButtonPreview", "", 0, this.IOControls.IB2, "x+5 yp+5", 50)
		
		this.AddControl("DDL", "MouseAxis", 0, "x+5 yp+3 w50", "X||Y")
		this.AddControl("Edit", "MouseMoveMin", 0, "x+5 yp w50", "1")
		this.AddControl("Edit", "MultiplyTime", 0, "x+5 yp w50", "0")
		this.AddControl("Edit", "MultiplyAmount", 0, "x+5 yp w50", "2")
		this.AddControl("Edit", "MouseMoveMax", 0, "x+5 yp w50", "20")
		
		this.MoveMouseFn := this.MoveMouse.Bind(this)
		this.MultiplyFn := this.MultiplyMove.Bind(this)
	}
	
	MyInputChangedState(dir, value){
		if (this.InputStates[dir] == value) ; Always enforce repeat suppression
			return
		this.InputStates[dir] := value
		val := this.GuiControls.MouseMoveMin.Get() * dir
		
		if ((this.InputStates[-1] == 0 && this.InputStates[1] == 0) || (this.InputStates[-1] == 1 && this.InputStates[1] == 1)){
			; Neither button held or both buttons held - no movement
			this.AxisStates := {x: 0, y: 0}
			mouse_should_be_moving := 0
		} else {
			; Only one direction held
			if (this.GuiControls.MouseAxis.Get() == "X"){
				this.AxisStates.X := val
				this.AxisStates.Y := 0
			} else {
				this.AxisStates.X := 0
				this.AxisStates.Y := val
			}
			mouse_should_be_moving := 1
		}
		
		moveFn := this.MoveMouseFn
		multiplyFn := this.MultiplyFn
		
		; Start or stop the timer as appropriate
		if (this.MouseIsMoving && !mouse_should_be_moving){
			this.MouseIsMoving := 0
			SetTimer, % moveFn, Off
			SetTimer, % multiplyFn, Off
		} else if (mouse_should_be_moving && !this.MouseIsMoving){
			this.MouseIsMoving := 1
			SetTimer, % moveFn, 10
			multiplyTime := this.GuiControls.MultiplyTime.Get()
			if (multiplyTime != 0){
				SetTimer, % multiplyFn, % multiplyTime
			}
		}
	}
	
	MoveMouse(){
		DllCall("mouse_event", uint, 1, int, this.AxisStates.X, int, this.AxisStates.Y, uint, 0, int, 0)
	}
	
	MultiplyMove(){
		ax := this.GuiControls.MouseAxis.Get()
		old := this.AxisStates[ax]
		max := this.GuiControls.MouseMoveMax.Get()
		if (Abs(old) == max)
			return
		sgn := this.Sgn(old)
		mult := this.GuiControls.MultiplyAmount.Get()
		val := old * mult
		if (Abs(val) > max){
			val := sgn * max
		}
		this.AxisStates[ax] := val
	}
	
	Sgn(val){
		if (val > 0)
			return 1
		if val < 0
			return -1
		return 0
	}
}
