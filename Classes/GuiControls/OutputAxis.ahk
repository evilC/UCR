; ======================================================================== OUTPUT AXIS ===============================================================
class OutputAxis extends _UCR._ControlClasses.GuiControls.IOControl {
	static _ControlType := "OutputAxis"
	static _IOClassNames := ["vJoy_Axis_Output", "vXBox_Axis_Output"]
	static _DefaultBanner := "Select an Output Axis"
	static vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	
	;__value := {DeviceID: 0, axis: 0}
	_IOClasses := {}
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.name := name
		this.ChangeValueCallback := ChangeValueCallback
		
		for i, name in this._IOClassNames {
			;this._IOClasses[name] := new %name%(this)
			call:= _UCR._ControlClasses.IOClasses[name]
			this._IOClasses[name] := new call(this)

			if (!this._IOClasses.IsInitialized) {
				this._IOClasses[name]._Init()
			}
		}
		
		this._BuildMenu()
		this.SetControlState()
	}
	
	__Delete(){
		OutputDebug % "UCR| OutputAxis " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	_KillReferences(){
		base._KillReferences()
		this.ChangeValueCallback := ""
	}
	
	; bo is a "Primitive" BindObject
	SetBinding(bo, update_ini := 1){
		;OutputDebug % "UCR| SetBinding: class: " bo.IOClass ", code: " bo.Binding[1] ", wild: " bo.BindOptions.wild
		this._IOClasses[bo.IOClass]._Deserialize(bo)
		this.Set(this._IOClasses[bo.IOClass], update_ini)
	}
	
	_BuildMenu(){
		for i, cls in this._IOClasses {
			cls.AddMenuItems()
		}
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
	}
	
	; Plugin Authors call this to set the state of the output axis
	SetState(state, delay_done := 0){
		if (UCR._CurrentState == 2 && !delay_done){
			fn := this.SetState.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.__value.SetState(state)
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
