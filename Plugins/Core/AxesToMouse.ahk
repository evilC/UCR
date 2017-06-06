/*
Merges two physical axes into one virtual axis
Requires the StickOps library and the vJoy library
*/
class AxesToMouse extends _UCR.Classes.Plugin {
	Type := "Remapper (Axes To Mouse)"
	Description := "Maps two input axes to mouse output"
	
	AxisStates := [0,0]
	MouseIsMoving := 0
	
	; Set up the GUI to allow the user to select input and output axes
	Init(){
		Gui, Add, Text, % "xm w125 Center", Input Axis 1
		Gui, Add, Text, % "x+5 w125 Center", Input Axis 2
		this.AddControl("InputAxis", "InputAxis1", 0, this.MyInputChangedState.Bind(this, 1), "xm w125")
		this.AddControl("InputAxis", "InputAxis2", 0, this.MyInputChangedState.Bind(this, 2), "Section x+5 w125")
		
		Gui, Add, Text, % "xm w125 Center", Input 1 Preview
		Gui, Add, Text, % "x+5 yp w125 Center", Input 2 Preview
		this.AddControl("AxisPreview", "", 0, this.IOControls.InputAxis1, "xm w125", 50)
		this.AddControl("AxisPreview", "", 0, this.IOControls.InputAxis2, "x+5 yp w125", 50)
		Gui, Add, Text, % "x50", Invert
		this.AddControl("CheckBox", "Invert1", this.MyEditChanged.Bind(this), "x+5 yp")
		
		Gui, Add, Text, % "x180 yp", Invert
		this.AddControl("CheckBox", "Invert2", this.MyEditChanged.Bind(this), "x+5 yp")
		
		Gui, Add, Text, % "x270 y40 w50 Center", Deadzone
		Gui, Add, Text, % "x+5 yp w50 Center", Sensitivity
		
		this.AddControl("Edit", "Deadzone", this.MyEditChanged.Bind(this), "x270 yp+20 w30", "15")
		Gui, Add, Text, % "x+0 yp+3", `%
		this.AddControl("Edit", "Sensitivity", this.MyEditChanged.Bind(this), "x+15 yp-3 w30", "100")
		Gui, Add, Text, % "x+0 yp+3", `%
		
		this.MoveMouseFn := this.MoveMouse.Bind(this)
	}
	
	; The user moved the selected input axis. Manipulate the output axis accordingly
	MyInputChangedState(axis, value){
		value := UCR.Libraries.StickOps.AHKToInternal(value)
		
		; Apply input axis inversions
		if (inv := this.GuiControls["Invert" axis].Get()){
			value := UCR.Libraries.StickOps.Invert(value)
		}
		
		; Apply deadzone
		if (dz := this.GuiControls.Deadzone.Get()){
			value := UCR.Libraries.StickOps.Deadzone(value, dz)
		}
		
		; Adjust sensitivity
		if (dz := this.GuiControls.Sensitivity.Get()){
			value := UCR.Libraries.StickOps.Sensitivity(value, dz)
		}
		
		; Store new value for the changed axis in array
		this.AxisStates[axis]  := value
		
		fn := this.MoveMouseFn
		
		; Start or stop the timer as appropriate
		mouse_should_be_moving := this.AxisStates[1] || this.AxisStates[2]
		if (this.MouseIsMoving && !mouse_should_be_moving){
			this.MouseIsMoving := 0
			SetTimer, % fn, Off
		} else if (mouse_should_be_moving && !this.MouseIsMoving){
			this.MouseIsMoving := 1
			SetTimer, % fn, 10
		}
	}
	
	MoveMouse(){
		DllCall("mouse_event", uint, 1, int, this.AxisStates[1], int, this.AxisStates[2], uint, 0, int, 0)
	}
}
