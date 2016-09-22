; ======================================================================== INPUT AXIS ===============================================================
class _InputAxis extends _BannerMenu {
	static AHKAxisList := ["X","Y","Z","R","U","V"]
	static vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	static _BindTypes := {AHK_JoyAxis_Input: "AHK_JoyAxis_Input"}
	static _IOClassNames := ["AHK_JoyAxis_Input"]
	
	_OptionMap := []
	State := -1
	_BindObjects := {}
	__value := 0
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.name := name
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
		UCR._RegisterGuiControl(this)

		for i, name in this._IOClassNames {
			this._BindObjects[name] := new %name%(this)
			if (!this._BindObjects.IsInitialized) {
				this._BindObjects[name]._Init()
			}
		}
		
		this._BuildMenu()
		this.SetControlState()
	}
	
	__Delete(){
		OutputDebug % "UCR| InputAxis " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	_KillReferences(){
		base._KillReferences()
		this.ChangeValueCallback := ""
		this.ChangeStateCallback := ""
	}
	
	_BuildMenu(){
		for i, cls in this._BindObjects {
			cls.AddMenuItems()
		}
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
	}
	
	_ChangedValue(o){
		if (o == 2){
			this.__value.Binding := []
			this.__value.DeviceID := 0
			this.SetBinding(this.__value)
		}
	}
	
	; bo is a "Primitive" BindObject
	SetBinding(bo, update := 1){
		this._BindObjects[bo.IOClass]._Deserialize(bo)
		this[update ? "value" : "_value"] := this._BindObjects[bo.IOClass]
		
		; If both value and device are set, or neither are set, then update the binding
		; ToDo - add in the condition that the binding must have also changed
		if ((this.__value.Binding[1] && this.__value.DeviceID) || (!this.__value.Binding[1] && !this.__value.DeviceID)){
			UCR._RequestBinding(this)
		}
	}
	
	; All Input types should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		;UCR.RequestAxisBinding(this)
		UCR._RequestBinding(this)
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
		if (this.__value.DeviceID || this.__value.Binding[1]){
			this.SetCueBanner(this.__value.BuildHumanReadable())
		} else {
			this.SetCueBanner("Select an Input Axis")
		}
		for i, cls in this._BindObjects {
			cls.UpdateMenus(this.__value.IOClass)
		}
	}
	
	; Get / Set of .value
	value[]{
		; Read of current contents of GuiControl
		get {
			return this.__value
		}
		
		; When the user types something in a guicontrol, this gets called
		; Fire _ControlChanged on parent so new setting can be saved
		set {
			this._value := value
			OutputDebug % "UCR| GuiControl " this.Name " called ParentPlugin._ControlChanged()"
			this.ParentPlugin._ControlChanged(this)
		}
	}
	
	; Get / Set of ._value
	_value[]{
		; this will probably not get called
		get {
			return this.__value
		}
		; Update contents of GuiControl, but do not fire _ControlChanged
		; Parent has told child state to be in, child does not need to notify parent of change in state
		set {
			this.__value := value
			this.SetControlState()
			if (IsObject(this.ChangeValueCallback)){
				this.ChangeValueCallback.Call(this.__value)
			}
		}
	}
	
	_Serialize(){
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Pass 0 to SetBinding so we don't save while we are loading
		this.SetBinding(obj, 0)
	}

	/*
	_Serialize(){
		obj := {value: this._value}
		return obj
	}
	
	_Deserialize(obj){
		this._value := obj.value
		;UCR.RequestAxisBinding(this)
	}
	*/
}
