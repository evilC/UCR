; ======================================================================== OUTPUT AXIS ===============================================================
class OutputAxis extends _UCR.Classes.GuiControls.InputAxis {
	static _ControlType := "OutputAxis"
	static _IOClassNames := ["vJoy_Axis_Output", "vXBox_Axis_Output"]
	static _Text := "Output"

	static vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
	}
	
	__Delete(){
		OutputDebug % "UCR| OutputAxis " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Plugin Authors call this to set the state of the output axis
	Set(state, delay_done := 0){
		if (UCR._CurrentState == 2 && !delay_done){
			fn := this.SetState.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.__value.Set(state)
			this.State := State
		}
	}
}
