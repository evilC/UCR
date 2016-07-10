; ======================================================================== INPUT AXIS ===============================================================
class _InputAxis extends _BannerCombo {
	AHKAxisList := ["X","Y","Z","R","U","V"]
	__value := new _Axis()
	_OptionMap := []
	
	State := -1
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
		this._Options := []
		Loop 6 {
			this._Options.push("Axis " A_Index " (" this.AHKAxisList[A_Index] ")" )
		}
		Loop 8 {
			;this._Options.push("Stick " A_Index )
			;~ this._Options.push(A_Index ": " DllCall("JoystickOEMName\joystick_OEM_name", double,A_Index, "CDECL AStr"))
			this._Options.push(A_Index ": " joystick_OEM_name(A_Index))
		}
		this._Options.push("Clear Binding")
		this.SetComboState()
	}
	
	; The Axis Select DDL changed value
	_ChangedValue(o){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		
		; Resolve result of selection to index of full option list
		o := this._OptionMap[o]
		
		if (o <= 6){
			; Axis Selected
			axis := o
		} else if (o <= 14){
			; Stick Selected
			o -= 6
			DeviceID := o
		} else {
			; Clear Selected
			axis := DeviceID := 0
		}
		this.__value.Axis := axis
		this.__value.DeviceID := DeviceID
		this.SetComboState()
		this.value := this.__value
		UCR.RequestAxisBinding(this)
	}
	
	; All Input types should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		UCR.RequestAxisBinding(this)
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetComboState(){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		this._OptionMap := []
		opts := []
		if (DeviceID){
			; Show Sticks and Axes
			max := 14
			index_offset := 0
			if (!Axis)
				str := "Pick an Axis (Stick " DeviceID ")"
		} else {
			str := "Pick a Stick"
			max := 8
			index_offset := 6
		}
		Loop % max {
			map_index := A_Index + index_offset
			if ((map_index > 6 && map_index <= 14))
				joyinfo := GetKeyState( map_index - 6 "JoyInfo")
			else
				joyinfo := 0
			if ((map_index > 6 && map_index <= 14) && !JoyInfo)
				continue
			opts.push(this._Options[map_index])
			this._OptionMap.push(map_index)
		}
		if (DeviceID || axis){
			opts.push(this._Options[15])
			this._OptionMap.push(15)
		}
		
		if (DeviceID && Axis)
			str := "Stick " DeviceID ", Axis " axis " (" this.AHKAxisList[axis] ")"
		
		this.SetOptions(opts)
		this.SetCueBanner(str)
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
			this.SetComboState()
			if (IsObject(this.ChangeValueCallback)){
				this.ChangeValueCallback.Call(this.__value)
			}
		}
	}
	
	_Serialize(){
		obj := {value: this._value}
		return obj
	}
	
	_Deserialize(obj){
		this._value := obj.value
		;UCR.RequestAxisBinding(this)
	}
}
