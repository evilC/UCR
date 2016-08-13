; ======================================================================== OUTPUT BUTTON ===============================================================
; An Output allows the end user to specify which buttons to press as part of a plugin's functionality
Class _OutputButton extends _InputButton {
	_DefaultBanner := "Drop down the list to select an Output"
	_IsOutput := 1
	_OptionMap := {Select: 1, vJoyButton: 2, Clear: 3}
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
		; Create Select vJoy Button / Hat Select GUI
		Gui, new, HwndHwnd
		Gui -Border
		this.hVjoySelect := hwnd
		Gui, Add, Text, w50 xm Center, vJoy Stick
		Gui, Add, Text, w50 xp+55 Center, Button
		Gui, Add, Text, w50 xp+55 Center, Hat
		Gui, Add, ListBox, R11 xm w50 AltSubmit HwndHwnd , None||1|2|3|4|5|6|7|8
		this.hVjoyDevice := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "dev")
		GuiControl +g, % hwnd, % fn
		Gui, Add, ListBox, R11 w50 xp+55 AltSubmit HwndHwnd , None||01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|39|40|41|42|43|44|45|46|47|48|49|50|51|52|53|54|55|56|57|58|59|60|61|62|63|64|65|66|67|68|69|70|71|72|73|74|75|76|77|78|79|80|81|82|83|84|85|86|87|88|89|90|91|92|93|94|95|96|97|98|99|100|101|102|103|104|105|106|107|108|109|110|111|112|113|114|115|116|117|118|119|120|121|122|123|124|125|126|127|128|
		this.hVJoyButton := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "but")
		GuiControl +g, % hwnd, % fn
		Gui, Add, ListBox, R5 w50 xp+55 AltSubmit HwndHwnd , None||Hat 1|Hat 2|Hat 3|Hat 4
		this.hVJoyHatNumber := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "hn")
		GuiControl +g, % hwnd, % fn
		Gui, Add, ListBox, R5 w50 xp y+9 AltSubmit HwndHwnd , None||Up|Right|Down|Left
		this.hVJoyHatDir := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "hd")
		GuiControl +g, % hwnd, % fn
		Gui, Add, Button, xm w75 Center HwndHwnd, Cancel
		this.hVJoyCancel := hwnd
		fn := this.vJoyInputCancelled.Bind(this)
		GuiControl +g, % this.hVJoyCancel, % fn
		Gui, Add, Button, xp+85 w75 Center HwndHwnd, Ok
		this.hVjoyOK := hwnd
		fn := this.vJoyOutputSelected.Bind(this)
		GuiControl +g, % this.hVjoyOK, % fn
	}
	
	; Builds the list of options in the DropDownList
	_BuildOptions(){
		opts := []
		this._CurrentOptionMap := [this._OptionMap["Select"]]
		opts.push("Select New Keyboard / Mouse Output")
		this._CurrentOptionMap.push(this._OptionMap["vJoyButton"])
		opts.push("Select New vJoy Button / Hat")
		this._CurrentOptionMap.push(this._OptionMap["Clear"])
		opts.push("Clear Output")
		this.SetOptions(opts)
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
			o := this._CurrentOptionMap[o]
			
			; Option selected from list
			if (o = 1){
				; Bind
				UCR._RequestBinding(this)
				return
			} else if (o = 2){
				; vJoy
				this._SelectvJoy()
			} else if (o = 3){
				; Clear Binding
				mod := {Buttons: []}
			} else {
				; not one of the options from the list, user must have typed in box
				return
			}
			if (IsObject(mod)){
				UCR._RequestBinding(this, mod)
				return
			}
		}
	}
	
	; Present a menu to allow the user to select vJoy output
	_SelectvJoy(){
		Gui, % this.hVjoySelect ":Show"
		UCR.MoveWindowToCenterOfGui(this.hVjoySelect)
		dev := this.__value.Buttons[1].DeviceId + 1
		GuiControl, % this.hVjoySelect ":Choose", % this.hVjoyDevice, % dev
		if (this.__value.Buttons[1].Type >= 3){
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatNumber, % this.__value.Buttons[1].Type - 1
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatDir, % this.__value.Buttons[1].code + 1
		} else {
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyButton, % this.__value.Buttons[1].code + 1
		}
	}
	
	vJoyOptionSelected(what){
		GuiControlGet, dev, % this.hVjoySelect ":" , % this.hVjoyDevice
		dev--
		GuiControlGet, but, % this.hVjoySelect ":" , % this.hVJoyButton
		but--
		GuiControlGet, hn, % this.hVjoySelect ":" , % this.hVJoyHatNumber
		hn--
		GuiControlGet, hd, % this.hVjoySelect ":" , % this.hVJoyHatDir
		hd--
		if (what = "but" && but){
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatNumber, 1
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatDir, 1
		} else if (what != "dev" && %what%){
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyButton, 1
		}
	}
	
	vJoyOutputSelected(){
		Gui, % this.hVjoySelect ":Submit"
		GuiControlGet, device, % this.hVjoySelect ":" , % this.hVjoyDevice
		device--
		GuiControlGet, button, % this.hVjoySelect ":" , % this.hVJoyButton
		button--
		GuiControlGet, hn, % this.hVjoySelect ":" , % this.hVJoyHatNumber
		hn--
		GuiControlGet, hd, % this.hVjoySelect ":" , % this.hVJoyHatDir
		hd--
		
		bo := new _BindObject()
		
		if (device && button){
			t := 2
		} else if (device && hn && hd) {
			t := 2 + hn
		} else {
			return
		}
		bo.Type := t
		
		key := new _Button()
		key.DeviceID := device
		if (t = 2)
			key.code := button
		else
			key.code := hd
		key.IsVirtual := 1
		key.Type := t
		
		bo.Buttons := [key]
		this.value := bo
	}
	
	vJoyInputCancelled(){
		Gui, % this.hVjoySelect ":Submit"
	}
	
	_Deserialize(obj){
		; Trigger _value setter to set gui state but not fire change event
		this._value := new _BindObject(obj)
	}
	
	_RequestBinding(){
		; override base and do nothing
	}
	
	__Delete(){
		OutputDebug % "UCR| Output " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		base._KillReferences()
		;~ GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		;~ this.ChangeValueCallback := ""
		;~ this.ChangeStateCallback := ""
	}
}
