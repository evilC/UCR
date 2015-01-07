Class _UCR_C_InputHandler extends _UCR_C_Common {
	ProcessMessage(wParam, lParam, msg, hwnd){
		global II_DEVTYPE, RIM_TYPEMOUSE, II_MSE_BUTTONFLAGS
		global RI_MOUSE_LEFT_BUTTON_DOWN, RI_MOUSE_LEFT_BUTTON_UP, RI_MOUSE_RIGHT_BUTTON_DOWN, RI_MOUSE_RIGHT_BUTTON_UP, RI_MOUSE_MIDDLE_BUTTON_DOWN, RI_MOUSE_MIDDLE_BUTTON_UP, RI_MOUSE_BUTTON_4_DOWN, RI_MOUSE_BUTTON_4_UP, RI_MOUSE_BUTTON_5_DOWN, RI_MOUSE_BUTTON_5_UP, RI_MOUSE_WHEEL
		global RIM_TYPEKEYBOARD, II_KBD_VKEY, II_KBD_FLAGS, II_KBD_MAKECODE
		global RIM_TYPEHID, II_DEVHANDLE, 
		
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
					if (!HideLeftMouse){
						;LV_ADD(,"Mouse", "", "Left Button", "Down")
					}
				}
				If (flags & RI_MOUSE_LEFT_BUTTON_UP){
					if (!HideLeftMouse){
						;LV_ADD(,"Mouse", "", "Left Button", "Up")
					}
				}
				If (flags & RI_MOUSE_RIGHT_BUTTON_DOWN){
					if (!HideRightMouse){
						;LV_ADD(,"Mouse", "", "Right Button", "Down")
					}
				}
				If (flags & RI_MOUSE_RIGHT_BUTTON_UP){
					if (!HideRightMouse){
						;LV_ADD(,"Mouse", "", "Right Button", "Up")
					}
				}
				If (flags & RI_MOUSE_MIDDLE_BUTTON_DOWN){
					;LV_ADD(,"Mouse", "", "Middle Button", "Down")
					soundbeep
				}
				If (flags & RI_MOUSE_MIDDLE_BUTTON_UP){
					;LV_ADD(,"Mouse", "", "Middle Button", "Up")
				}
				If (flags & RI_MOUSE_BUTTON_4_DOWN) {
					;LV_ADD(,"Mouse", "", "XButton1", "Down")
				}
				If (flags & RI_MOUSE_BUTTON_4_UP) {
					;LV_ADD(,"Mouse", "", "XButton1", "Up")
				}
				If (flags & RI_MOUSE_BUTTON_5_DOWN) {
					;LV_ADD(,"Mouse", "", "XButton2", "Down")
				}
				If (flags & RI_MOUSE_BUTTON_5_UP) {
					;LV_ADD(,"Mouse", "", "XButton2", "Up")
				}
				If (flags & RI_MOUSE_WHEEL) {
					waswheel := 1
					if (!HideMouseWheel){
						;LV_ADD(,"Mouse", "", "Wheel", Round(AHKHID_GetInputInfo(lParam, II_MSE_BUTTONDATA) / 120))
					}
				}
				waslogged := 1
			}
		} Else If (r = RIM_TYPEKEYBOARD) {
			; keyboard input ======================
			vk := AHKHID_GetInputInfo(lParam, II_KBD_VKEY)
			keyname := GetKeyName("vk" this.ToHex(vk,2))
			flags := AHKHID_GetInputInfo(lParam, II_KBD_FLAGS)
			makecode := AHKHID_GetInputInfo(lParam, II_KBD_MAKECODE)
			s := ""
			if (vk == 17) {
				; Control
				if (flags < 2){
					; LControl
					s := "Left "
				} else {
					; RControl
					s := "Right "
					flags -= 2
				
				}
				; One of the control keys
			} else if (vk == 18) {
				; Alt
				if (flags < 2){
					; LAlt
					s := "Left "
				} else {
					; RAlt
					s := "Right "
					flags -= 3	; RALT REPORTS DIFFERENTLY!
				
				}
			} else if (vk == 16){
				; Shift
				if (makecode == 42){
					; LShift
					s := "Left "
				} else {
					; RShift
					s := "Right "
				}
			} else if (vk == 91 || vk == 92) {
				; Windows key
				flags -= 2
				if (makecode == 91){
					; LWin
					s := "Left "
				} else {
					; RWin
					s := "Right "
				}
			}
			;s .= keyname
			;waslogged := 1
			;LV_ADD(,"Keyboard", "", s, (flags ? "Up" : "Down") )
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
				
				; Add to log
				;LV_ADD(,"Joystick", joysticks[name].human_name, "", Bin2Hex(&uData, r))
			}
		}
	}

}