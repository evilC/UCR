; ======================================================================== OUTPUT AXIS ===============================================================
class _OutputAxis extends _BannerCombo {
	;__value := {DeviceID: 0, axis: 0}
	__value := new _Axis()
	vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ID := UCR.CreateGUID()
		this.ChangeValueCallback := ChangeValueCallback
		
		this._Options := []
		Loop 8 {
			this._Options.push("Axis " A_Index " (" this.vJoyAxisList[A_Index] ")" )
		}
		Loop 8 {
			this._Options.push("vJoy Stick " A_Index )
		}
		this._Options.push("Clear Binding")
		this.SetComboState()
	}
	
	; Plugin Authors call this to set the state of the output axis
	SetState(state, delay_done := 0){
		if (UCR._CurrentState == 2 && !delay_done){
			; In GameBind Mode - delay output.
			; Call this method again, but pass 1 to delay_done
			fn := this.SetState.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.State := state
			UCR.Libraries.vJoy.Devices[this.__value.DeviceID].SetAxisByIndex(state, this.__value.Axis)
			;UCR.Libraries.vJoy.SetAxis(state, this.__value.DeviceID, this.__value.Axis)
		}
	}
	
	SetComboState(){
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
			str := "Pick a virtual Stick"
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
		
		if (DeviceID && Axis)
			str := "Stick " DeviceID ", Axis " axis " (" this.vJoyAxisList[axis] ")"
		
		this.SetOptions(opts)
		this.SetCueBanner(str)
	}
	
	_ChangedValue(o){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		
		; Resolve result of selection to index of full option list
		o := this._OptionMap[o]
		
		if (o <= 8){
			; Axis Selected
			axis := o
		} else if (o <= 16){
			; Stick Selected
			o -= 8
			DeviceID := o
		} else {
			; Clear Selected
			axis := DeviceID := 0
		}
		this.__value.Axis := axis
		this.__value.DeviceID := DeviceID
		
		this.SetComboState()
		this.value := this.__value
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
	}
	
}
