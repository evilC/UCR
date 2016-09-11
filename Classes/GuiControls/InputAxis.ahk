; ======================================================================== INPUT AXIS ===============================================================
class _InputAxis extends _BannerMenu {
	AHKAxisList := ["X","Y","Z","R","U","V"]
	vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	__value := new _Axis()
	_OptionMap := []
	
	State := -1
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.name := name
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
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
		Loop 8 {
			ji := GetKeyState( A_Index "JoyInfo")
			if (!ji)
				continue
			offset := A_Index * 10
			menu := this.AddSubMenu("Stick " A_index, "Stick" A_index)
			Loop 6 {
				str := this.AHKAxisList[A_Index]
				if (this.AHKAxisList[A_Index] != this.vJoyAxisList[A_Index]){
					str .= " / " this.vJoyAxisList[A_Index]
				}
				menu.AddMenuItem(A_Index " (" str ")", this._ChangedValue.Bind(this, offset + A_Index))
			}
		}
		this.AddMenuItem("Clear", this._ChangedValue.Bind(this, 2))
	}
	
	; The Axis Select DDL changed value
	_ChangedValue(o){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		
		if (o > 10){
			o -= 10
			DeviceID := 1
			while (o > 10){
				DeviceID++
				o -= 10
			}
			axis := o
		} else if (o == 2){
			; Clear Selected
			axis := DeviceID := 0
		}
		this.__value.Axis := axis
		this.__value.DeviceID := DeviceID
		this.SetControlState()
		this.value := this.__value
		UCR.RequestAxisBinding(this)
	}
	
	; All Input types should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		UCR.RequestAxisBinding(this)
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
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
			str := "Select an Input Axis"
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
			this.SetControlState()
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
