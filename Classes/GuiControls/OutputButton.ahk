; ======================================================================== OUTPUT BUTTON ===============================================================
; An Output allows the end user to specify which buttons to press as part of a plugin's functionality
Class _OutputButton extends _InputButton {
	State := 0
	_DefaultBanner := "Select an Output Button"
	_IsOutput := 1
	;_OptionMap := {Select: 1, vJoyButton: 2, Clear: 3}
	JoyMenus := []
	
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
		; Create Select vJoy Button / Hat Select GUI
	}
	
	_BuildMenu(){
		static HatDirections := ["Up", "Right", "Down", "Left"]
		static XBoxButtons := ["A", "B", "X", "Y", "LB", "RB", "LS", "RS", "Back", "Start", "Guide"]
		this.AddMenuItem("Select Keyboard / Mouse Binding", this._ChangedValue.Bind(this, 1))
		menu := this.AddSubMenu("vJoy Stick", "vJoy Stick")
		Loop 8 {
			menu.AddMenuItem(A_Index, this._ChangedValue.Bind(this, 100 + A_Index))
		}
		chunksize := 16
		Loop % round(128 / chunksize) {
			offset := (A_Index-1) * chunksize
			menu := this.AddSubMenu("vJoy Buttons " offset + 1 "-" offset + chunksize, "vJoyBtns" A_Index)
			this.JoyMenus.Push(menu)
			Loop % chunksize {
				btn := A_Index + offset
					menu.AddMenuItem(btn, this._ChangedValue.Bind(this, 1000 + btn))	; Set the callback when selected
			}
		}

		Loop 4 {
			menu := this.AddSubMenu("vJoy Hat " A_Index, "vJoyHat" A_Index)
			offset := (1 + A_Index) * 1000
			this.JoyMenus.Push(menu)
			Loop 4 {
				menu.AddMenuItem(HatDirections[A_Index], this._ChangedValue.Bind(this, offset + A_Index))	; Set the callback when selected
			}
		}
		
		/*
		menu := this.AddSubMenu("vXBox Pad", "vXBoxPad")
		Loop 4 {
			menu.AddMenuItem(A_Index, this._ChangedValue.Bind(this, 200 + A_Index))
		}

		menu := this.AddSubMenu("vXBox Buttons", "vXBoxBtns")
		this.JoyMenus.Push(menu)
		Loop 11 {
			menu.AddMenuItem(XBoxButtons[A_Index] " (" A_Index ")", this._ChangedValue.Bind(this, 6000 + A_Index))
		}
		*/

		this.AddMenuItem("Clear", this._ChangedValue.Bind(this, 2))
	}
	
	; Builds the list of options in the DropDownList
	SetControlState(){
		base.SetControlState()
		joy := (this.__value.Type >= 2 && this.__value.Type <= 6)
		for n, opt in this.JoyMenus {
			opt.SetEnableState(joy)
		}
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
			this.State := state
			max := this.__value.Buttons.Length()
			if (state)
				i := 1
			else
				i := max
			Loop % max{
				key := this.__value.Buttons[i]
				if (key.Type = 2 && key.IsVirtual){
					; Virtual Joystick Button
					UCR.Libraries.vJoy.Devices[key.DeviceID].SetBtn(state, key.code)
				} else if (key.Type >= 3 && key.IsVirtual){
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
				} else {
					; Keyboard / Mouse
					name := key.BuildKeyName()
					Send % "{" name (state ? " Down" : " Up") "}"
				}
				if (state)
					i++
				else
					i--
			}
		}
	}
	
	; An option was selected from the list
	_ChangedValue(o){
		if (o){
			;o := this._CurrentOptionMap[o]
			
			; Option selected from list
			if (o = 1){
				; Bind
				UCR._RequestBinding(this)
				return
			} else if (o = 2){
				; Clear Binding
				mod := {Buttons: [], type: 0}
			} else if (o > 100 && o < 109) {
				; Stick ID
				o -= 100
				reopen := 0
				if (this.__value.type >= 2 && this.__value.type <= 6){
					; stick already selected
					bo := this.__value.clone()
				} else {
					reopen := 1
					bo := new _BindObject()
					bo.Type := 2
					btn := new _Button()
					btn.Type := 2
					btn.IsVirtual := 1
					bo.Buttons.push(btn)
				}
				
				bo.Buttons[1].DeviceID := o
				this._value := bo
				; Re-open the menu if we just changed to stick
				if (reopen)
					this.OpenMenu()
			} else if (o > 1000 && o < 1129){
				o -= 1000
				bo := this.__value.clone()
				bo.Buttons[1].code := o
				bo.Buttons[1].type := 2
				bo.Type := 2
				this._value := bo
			} else if (o > 2000 && o < 6000){
				o -= 2000
				hat := 1
				while (o > 1000){
					o -= 1000
					hat++
				}
				bo := this.__value.clone()
				bo.Buttons[1].code := o
				bo.Buttons[1].type := 2 + hat
				bo.Type := 2 + hat
				this._value := bo
			}
			if (IsObject(mod)){
				UCR._RequestBinding(this, mod)
				return
			}
		}
	}
	
	_Deserialize(obj){
		; Trigger _value setter to set gui state but not fire change event
		this._value := new _BindObject(obj)
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
		;~ this.ChangeValueCallback := ""
		;~ this.ChangeStateCallback := ""
	}
}
