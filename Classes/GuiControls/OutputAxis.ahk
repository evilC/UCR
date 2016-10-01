; ======================================================================== OUTPUT AXIS ===============================================================
class OutputAxis extends _UCR.Classes.GuiControls.IOControl {
	static _ControlType := "OutputAxis"
	static _IOClassNames := ["vJoy_Axis_Output", "vXBox_Axis_Output"]
	static _DefaultBanner := "Select an Output Axis"
	static vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	
	;__value := {DeviceID: 0, axis: 0}
	_IOClasses := {}
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
	}
	
	__Delete(){
		OutputDebug % "UCR| OutputAxis " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	_BuildMenu(){
		for i, cls in this._IOClasses {
			cls.AddMenuItems()
		}
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
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
	
	SetControlState(){
		if (this.__value.Binding[1] || this.__value.DeviceID){
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner
		}
		this.SetCueBanner(Text)
		; Tell vGen etc to Acquire sticks
		this.__value.UpdateBinding()
		; Update the Menus etc of all the IOClasses in this control
		for i, cls in this._IOClasses {
			cls.UpdateMenus(this.__value.IOClass)
		}
	}
	
	_ChangedValue(o){

	}
	
}
