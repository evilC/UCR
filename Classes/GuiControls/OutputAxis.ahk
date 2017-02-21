; ======================================================================== OUTPUT AXIS ===============================================================
class OutputAxis extends _UCR.Classes.GuiControls.InputAxis {
	static _ControlType := "OutputAxis"
	static _IOClassNames := ["vJoy_Axis_Output", "vXBox_Axis_Output", "TitanOne_Axis_Output"]
	static _Text := "Output"
	
	static vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	
	state := 50	; Default to mid-point on the axis
	
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
	}
	
	__Delete(){
		OutputDebug % "UCR| OutputAxis " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Plugin Authors call this to set the state of the output axis
	Set(state, delay_done := 0){
		if (state > 100)
			state := 100
		else if (state < 0)
			state := 0
		if (UCR._CurrentState == 2 && !delay_done){
			fn := this.Set.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.__value.Set(state)
			this.State := State
		}
		this.OnStateChange(state)
	}
}
