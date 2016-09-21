; ======================================================================== INPUT AXIS ===============================================================
class _InputAxis extends _BannerMenu {
	AHKAxisList := ["X","Y","Z","R","U","V"]
	vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	__value := new _Axis()
	_OptionMap := []
	State := -1
	
	_BindTypes := {AHK_Joy_Axes: "AHK_Joy_Axes"}
	_IOClassNames := ["AHK_Joy_Axes"]
	_BindObjects := {}
	
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
		/*
		Loop 8 {
			ji := GetKeyState( A_Index "JoyInfo")
			if (!ji)
				continue
			offset := A_Index * 10
			if (UCR.UserSettings.GuiControls.ShowJoystickNames){
				name := " (" DllCall("JoystickOEMName\joystick_OEM_name", double,A_Index, "CDECL AStr") ")"
			}
			menu := this.AddSubMenu("Stick " A_index name, "Stick" A_index)
			Loop 6 {
				str := this.AHKAxisList[A_Index]
				if (this.AHKAxisList[A_Index] != this.vJoyAxisList[A_Index]){
					str .= " / " this.vJoyAxisList[A_Index]
				}
				menu.AddMenuItem(A_Index " (" str ")", A_Index, this._ChangedValue.Bind(this, offset + A_Index))
			}
		}
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
		*/
	}
	
	_ChangedValue(o){

	}
	
	; bo is a "Primitive" BindObject
	SetBinding(bo){
		if (!bo.DeviceID)
			bo.Delete("DeviceID")
		this._BindObjects[bo.IOClass]._Deserialize(bo)
		this.value := this._BindObjects[bo.IOClass]
		OutputDebug % "UCR| SetBinding: class: " bo.IOClass ", code: " this._BindObjects[bo.IOClass].Binding[1] ", Device: " this._BindObjects[bo.IOClass].DeviceID
		;if (this__value.Binding[1] && this.__value.DeviceID){
			UCR._RequestBinding(this)
		;}
	}
	
	; All Input types should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		;UCR.RequestAxisBinding(this)
		;UCR.RequestBinding(this)
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
		if (this.__value.DeviceID || this.__value.Binding[1]){
			this.SetCueBanner(this.__value.BuildHumanReadable())
		} else {
			this.SetCueBanner("Select an Input Axis")
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
		; Trigger _value setter to set gui state but not fire change event
		;this._value := new _BindObject(obj)
		cls := obj.IOClass
		this._value := new %cls%(this, obj)
		; Register hotkey on load
		;UCR._InputHandler.SetButtonBinding(this)
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
