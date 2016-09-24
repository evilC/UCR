; ======================================================================== OUTPUT BUTTON ===============================================================
; An Output allows the end user to specify which buttons to press as part of a plugin's functionality
Class OutputButton extends InputButton {
	static _ControlType := "OutputButton"
	static _DefaultBanner := "Select an Output Button"
	static _IsOutput := 1
	static _BindTypes := {AHK_Common: 0, AHK_KBM_Input: "AHK_KBM_Output"}
	static _IOClassNames := ["AHK_KBM_Output", "vJoy_Button_Output", "vJoy_Hat_Output", "vXBox_Button_Output", "vXBox_Hat_Output"]

	State := 0
	JoyMenus := []
	
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
		; Create Select vJoy Button / Hat Select GUI
	}
	
	_BuildMenu(){
		this.AddMenuItem("Select Keyboard / Mouse Binding...", "AHK_KBM_Output", this._ChangedValue.Bind(this, 1))
		for i, cls in this._IOClasses {
			cls.AddMenuItems()
		}
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))

	}
	
	; Builds the list of options in the DropDownList
	SetControlState(){
		base.SetControlState()
		; Tell vGen etc to Acquire sticks
		this.__value.UpdateBinding()
		; Update the Menus etc of all the IOClasses in this control
		for i, cls in this._IOClasses {
			cls.UpdateMenus(this.__value.IOClass)
		}
		;joy := (this.__value.Type >= 2 && this.__value.Type <= 6)
		;for n, opt in this.JoyMenus {
		;	opt.SetEnableState(joy)
		;}
	}
	
	; Used by script authors to set the state of this output
	SetState(state, delay_done := 0){
		static PovMap := {0: {x:0, y:0}, 1: {x: 0, y: 1}, 2: {x: 1, y: 0}, 3: {x: 0, y: 2}, 4: {x: 2, y: 0}}
		static PovAngles := {0: {0:-1, 1:0, 2:18000}, 1:{0:9000, 1:4500, 2:13500}, 2:{0:27000, 1:31500, 2:22500}}
		static Axes := ["x", "y"]
		if (UCR._CurrentState == 2 && !delay_done){
			fn := this.SetState.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.__value.SetState(state)
			this.State := state
			/*
			this.State := state
			max := this.__value.Buttons.Length()
			if (state)
				i := 1
			else
				i := max
			Loop % max{
				key := this.__value.Buttons[i]
				if key.Type == 1 {
					; Keyboard / Mouse
					name := key.BuildKeyName()
					Send % "{" name (state ? " Down" : " Up") "}"
				} else if (key.Type = 2 && key.IsVirtual){
					; Virtual Joystick Button
					UCR.Libraries.vJoy.Devices[key.DeviceID].SetBtn(state, key.code)
				} else if (key.Type > 2 && key.Type < 7 && key.IsVirtual){
					; Virtual Joystick POV Hat
					device := UCR.Libraries.vJoy.Devices[key.DeviceID]
					if (!IsObject(device.PovState))
						device.PovState := {x: 0, y: 0}
					if (state)
						new_state := PovMap[key.code].clone()
					else
						new_state := PovMap[0].clone()
					
					this_angle := PovMap[key.code]
					Loop 2 {
						ax := Axes[A_Index]
						if (this_angle[ax]){
							if (device.PovState[ax] && device.PovState[ax] != new_state[ax])
								new_state[ax] := 0
						} else {
							; this key does not control this axis, look at device.PovState for value
							new_state[ax] := device.PovState[ax]
						}
					}
					device.SetContPov(PovAngles[new_state.x,new_state.y], key.Type - 2)
					device.PovState := new_state
				} else if (key.Type == 9 && key.IsVirtual){
					; Titan Button
					UCR.Libraries.Titan.SetButtonByIndex(key.code, state)
				} else if key.Type == 10 {
					; Titan Hat
					; ToDo: This probably won't work for hat to hat mapping.
					; Need to be able to toggle on/off cardinals
					;if (state)
					;	angle := (key.code-1)*2
					;else
					;	angle := -1
					;UCR.Libraries.Titan.SetPOVAngle(1, angle)
					UCR.Libraries.Titan.SetPovDirectionState(1, key.code, state)
					
					Send % "{" name (state ? " Down" : " Up") "}"
				} else {
					return 0
				}
				if (state)
					i++
				else
					i--
			}
			*/
		}
	}
	
	; An option was selected from one of the Menus that this class controls
	; Menus in this GUIControl may be handled in an IOClass
	_ChangedValue(o){
		if (o){
			if (o = 1){
				; Bind
				;UCR._RequestBinding(this)
				UCR.RequestBindMode(this._BindTypes, this._BindModeEnded.Bind(this)) ;*[UCR]
				return
			} else if (o = 2){
				; Clear Binding
				this.value._UnRegister()
				this.__value.Binding := []
				this.__value.DeviceID := 0
				this.SetBinding(this.__value)
			}
		}
	}
	
	; Bind Mode has ended.
	; A "Primitive" BindObject will be passed, along with the IOClass of the detected input.
	; The Primitive contains just the Binding property and optionally the DeviceID property.
	_BindModeEnded(bo){
		this.SetBinding(bo)
	}
	
	; bo is a "Primitive" BindObject
	SetBinding(bo, update := 1){
		;OutputDebug % "UCR| SetBinding: class: " bo.IOClass ", code: " bo.Binding[1] ", wild: " bo.BindOptions.wild
		this._IOClasses[bo.IOClass]._Deserialize(bo)
		this[update ? "value" : "_value"] := this._IOClasses[bo.IOClass]
	}

	_RequestBinding(){
		; override base and do nothing
	}
	
	__Delete(){
		OutputDebug % "UCR| OutputButton " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		base._KillReferences()
		this.JoyMenus := []
		;~ GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
	}
}
