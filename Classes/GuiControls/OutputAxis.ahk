; ======================================================================== OUTPUT AXIS ===============================================================
class _OutputAxis extends _BannerMenu {
	static _IOClassNames := ["vJoy_Axis_Output", "vXBox_Axis_Output"]
	static _DefaultBanner := "Select an Output Axis"
	static vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	
	;__value := {DeviceID: 0, axis: 0}
	_BindObjects := {}
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.name := name
		this.ChangeValueCallback := ChangeValueCallback
		
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
		OutputDebug % "UCR| OutputAxis " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	_KillReferences(){
		base._KillReferences()
		this.ChangeValueCallback := ""
	}
	
	; bo is a "Primitive" BindObject
	SetBinding(bo, update := 1){
		;OutputDebug % "UCR| SetBinding: class: " bo.IOClass ", code: " bo.Binding[1] ", wild: " bo.BindOptions.wild
		this._BindObjects[bo.IOClass]._Deserialize(bo)
		this[update ? "value" : "_value"] := this._BindObjects[bo.IOClass]
	}
	
	_BuildMenu(){
		for i, cls in this._BindObjects {
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
		}
		/*
		if (UCR._CurrentState == 2 && !delay_done){
			; In GameBind Mode - delay output.
			; Call this method again, but pass 1 to delay_done
			fn := this.SetState.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.State := state
			if (this.type == 4){
				UCR.Libraries.vJoy.Devices[this.__value.DeviceID].SetAxisByIndex(state, this.__value.Axis)
			} else {
				state := Round(state/327.67)
				UCR.Libraries.Titan.SetAxisByIndex(this.__value.Axis, state)
			}
		}
		*/
	}
	
	SetControlState(){
		if (this.__value.Binding[1] || this.__value.DeviceID){
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner
		}
		this.SetCueBanner(Text)
		; Update the Menus etc of all the IOClasses in this control
		for i, cls in this._BindObjects {
			cls.UpdateMenus(this.__value.IOClass)
		}
		/*
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		this._OptionMap := []
		opts := []
		if (DeviceID){
			; Show Sticks and Axes
			max := 16
			index_offset := 0
			if (!Axis)
				str := "Pick an Axis (Stick " DeviceID ")"
		} else {
			str := "Select an Output Axis"
			max := 10
			index_offset := 8
		}
		Loop % max {
			map_index := A_Index + index_offset
			if (map_index > 8 && map_index <= 16){
				if (!UCR.Libraries.vJoy.Devices[map_index - 8].IsAvailable()){
					continue
				}
			}
			opts.push(this._Options[map_index])
			this._OptionMap.push(map_index)
		}
		if (DeviceID || axis){
			opts.push(this._Options[17])
			this._OptionMap.push(17)
		}
		
		if (DeviceID && Axis){
			if (type == 4){
				str := "vJoy Stick " DeviceID ", Axis " axis " (" this.vJoyAxisList[axis] ")"
			} else {
				str := "Titan Axis " axis
			}
		}
		
		this.SetOptions(opts)
		this.SetCueBanner(str)
		*/
	}
	
	_ChangedValue(o){
		/*
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		
		if (o > 10 && o < 100){
			o -= 10
			DeviceID := 1
			while (o > 10){
				o -= 10
				DeviceID++
			}
			axis := o
			type := 4
		} else if (o > 100 && o < 107){
			o -= 100
			DeviceID := 1
			axis := o
			type := 5
		} else {
			; Clear Selected
			axis := DeviceID := 0
		}
		this.__value.Axis := axis
		this.__value.DeviceID := DeviceID
		this.__value.type := type
		
		this.SetControlState()
		this.value := this.__value
		*/
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
	
}
