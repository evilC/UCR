Class _UCR_C_InputHandler extends _UCR_C_Common {
	_StateKeyboard := {}
	_RegisteredCallbacks := {}
	
	__New(parent){
		base.__New(parent)
		this.BindMode := 0	; BindMode 1 = pass all up events to parent
	}

	__Get(aName, key){
		if (aName = "StateKeyboard"){
			value := this._StateKeyboard[key] ? 1 : 0
			;msgbox % "__GET: " aName " - " key " = " value
			return value
		}
	}
	
	__Set(aName, key, value){
		if (aName = "StateKeyboard"){
			;msgbox % "__SET: " aName " - " key " = " value
			; Filter out repeats
			if (this._StateKeyboard[key] != value){
				this._StateKeyboard[key] := value
				Gui, % this.parent.Hwnd ":Default"
				Gui, ListView, % this.parent.LVInputEvents
				LV_Add(, key, "Keyboard", this._StateKeyboard[key] ? "Down" : "Up")
			}
			return value	; do not set StateKeyboard 
		}
	}

	; Registers a hotkey for a callback
	RegisterHotkey(keyobj, callback){
		; keyobj := {key: "a", ctrl: 1}
	}
	
	ProcessMessage(wParam, lParam, msg, hwnd){
		global II_DEVTYPE, RIM_TYPEMOUSE, II_MSE_BUTTONFLAGS
		global RI_MOUSE_LEFT_BUTTON_DOWN, RI_MOUSE_LEFT_BUTTON_UP, RI_MOUSE_RIGHT_BUTTON_DOWN, RI_MOUSE_RIGHT_BUTTON_UP, RI_MOUSE_MIDDLE_BUTTON_DOWN, RI_MOUSE_MIDDLE_BUTTON_UP, RI_MOUSE_BUTTON_4_DOWN, RI_MOUSE_BUTTON_4_UP, RI_MOUSE_BUTTON_5_DOWN, RI_MOUSE_BUTTON_5_UP, RI_MOUSE_WHEEL
		global RIM_TYPEKEYBOARD, II_KBD_VKEY, II_KBD_FLAGS, II_KBD_MAKECODE
		global RIM_TYPEHID, II_DEVHANDLE
		
		Critical
		r := AHKHID_GetInputInfo(lParam, II_DEVTYPE)
		If (r = RIM_TYPEMOUSE) {
			; Mouse Input ==============
			; Filter mouse movement
			flags := AHKHID_GetInputInfo(lParam, II_MSE_BUTTONFLAGS)
			if (flags){
				; IMPORTANT NOTE!
				; EVENT COULD CONTAIN MORE THAN ONE BUTTON CHANGE!!!
				;Get flags and add to listbox
				s := ""
				If (flags & RI_MOUSE_LEFT_BUTTON_DOWN){
					
				}
				If (flags & RI_MOUSE_LEFT_BUTTON_UP){
					
				}
				If (flags & RI_MOUSE_RIGHT_BUTTON_DOWN){
					
				}
				If (flags & RI_MOUSE_RIGHT_BUTTON_UP){
					
				}
				If (flags & RI_MOUSE_MIDDLE_BUTTON_DOWN){
					soundbeep
				}
				If (flags & RI_MOUSE_MIDDLE_BUTTON_UP){
					
				}
				If (flags & RI_MOUSE_BUTTON_4_DOWN) {
					
				}
				If (flags & RI_MOUSE_BUTTON_4_UP) {
					
				}
				If (flags & RI_MOUSE_BUTTON_5_DOWN) {
					
				}
				If (flags & RI_MOUSE_BUTTON_5_UP) {
					
				}
				If (flags & RI_MOUSE_WHEEL) {
					
				}
			}
		} Else If (r = RIM_TYPEKEYBOARD) {
			; keyboard input ======================
			vk := AHKHID_GetInputInfo(lParam, II_KBD_VKEY)
			keyname := GetKeyName("vk" this.ToHex(vk,2))
			;msgbox % keyname
			flags := AHKHID_GetInputInfo(lParam, II_KBD_FLAGS)
			makecode := AHKHID_GetInputInfo(lParam, II_KBD_MAKECODE)
			s := ""
			if (vk == 17) {
				; Control
				if (flags < 2){
					; LControl
					s := "L"
				} else {
					; RControl
					s := "R"
					flags -= 2
				
				}
				; One of the control keys
			} else if (vk == 18) {
				; Alt
				if (flags < 2){
					; LAlt
					s := "L"
				} else {
					; RAlt
					s := "R"
					flags -= 3	; RALT REPORTS DIFFERENTLY!
				
				}
			} else if (vk == 16){
				; Shift
				if (makecode == 42){
					; LShift
					s := "L"
				} else {
					; RShift
					s := "R"
				}
			} else if (vk == 91 || vk == 92) {
				; Windows key
				flags -= 2
				if (makecode == 91){
					; LWin
					s := "L"
				} else {
					; RWin
					s := "R"
				}
			}
			s .= keyname
			flags := !flags
			this.StateKeyboard[s] := flags
		} Else If (r = RIM_TYPEHID) {
			; Stick Input ==============
			; reference material: http://www.codeproject.com/Articles/185522/Using-the-Raw-Input-API-to-Process-Joystick-Input
			h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE )
			name := AHKHID_GetDevName(h,1)
			if (name == StickID){
				r := AHKHID_GetInputData(lParam, uData)
				waslogged := 1
				; Why does this not work?? Neet to pull RIDI_PREPARSEDDATA
				;d := AHKHID_GetPreParsedData(h, uData)
				
			}
		}
	}

}