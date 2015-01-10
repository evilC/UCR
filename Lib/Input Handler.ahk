Class _UCR_C_InputHandler extends _UCR_C_Window {
	_RegisteredBindings := []
	BindMode := 0
	BindCallback := ""
	
	__New(parent){
		base.__New(parent)
		this.InputState := new this.CISC(this)
		this.BindMode := 0	; BindMode 1 = pass all up events to parent
	}

	; An InputHandler's GUI is the pop-up binding instructions
	CreateGui(){
		; override default base
		prompt := "Please press the desired key combination.`n`n"
		prompt .= "Supports most keyboard keys and all mouse buttons. Also Ctrl, Alt, Shift, Win as modifiers or individual keys.`n"
		;prompt .= "Joystick buttons are also supported, but currently not with modifiers.`n"
		prompt .= "`nHit Escape to cancel."
		prompt .= "`nHold Escape to clear a binding."
		Gui, New, % "HwndGuiHwnd -Border +AlwaysOnTop"
		this.hwnd := GuiHwnd
		Gui, % this.hwnd ":Add", Text, % "Center" , % prompt		
	}
	
	; Registers a hotkey for a callback
	RegisterBinding(key_obj, callback){
		;this._RegisteredBindings[key].Insert({modifiers: modifiers, app: app})
		this._RegisteredBindings.Insert({state: key_obj, callback: callback})
		
	}
	
	CheckBindings(){
		if (this.BindMode){
			;if (!keyobj.event){
				; On keyup event, exit BindMode
				this.BindMode := 0
				;BlockInput, MouseMoveOff
				Gui, % this.hwnd ":Hide"
				this.BindCallback.InputBound(this.InputState)
			;}
			; Bind Mode - fire on up event for all keys
		}
		Loop % this._RegisteredBindings.MaxIndex(){
			; Check for any matching combinations for this key
			if (this.InputState.CheckInputState(this._RegisteredBindings[A_Index].state)){
				this._RegisteredBindings[A_Index].callback()
			}
		}
	}

	; Called by a hotkey object to obtain a binding.
	EnableBindMode(obj){
		; Create the Bind GUI
		this.BindCallback := obj
		this.BindMode := 1
		this.Show()
		; ToDo: Need some way of blocking input in bind mode.
		; Disable mouse move, hide pointer, move cursor to ?hidden? ?offscreen? edit box so they don't get a "ding" when they hit a key?
		
		;BlockInput, MouseMove
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
			if (this.BindMode && !flags){
				; If in BindMode, fire CheckBindings before setting key to up state
				; That way, the ISC holds the state to be bound
				this.CheckBindings()
			}
			; Set the state of the ISC
			This.InputState.Keyboard[s] := flags
			WinGetClass, app, A
			
			Gui, ListView, % this.parent.LVInputEvents
			LV_Add(, s, "Keyboard", This.InputState.Keyboard[s])
			
			if (!this.BindMode){
				this.CheckBindings()
			}
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
	
	; ISC - Input State Class
	; An object which holds the state of all inputs and allows you to query them
	Class CISC {
		__New(parent){
			this.parent := parent
			this.root := this.parent.root
			
			this.Keyboard := new this.CKeyboard(this)
			
		}

		; Checks an object against current state to check to see if it is true
		CheckInputState(input_obj){
			; Check keyboard
			
			if (IsObject(input_obj) && ObjHasKey(input_obj, "keyboard")){
				if (!this.Keyboard.CheckInputState(input_obj.keyboard)){
					return 0
				}
			}
			return 1
		}

		; Converts input state to a human-readable form
		; ToDo: Improve.
		Render(obj){
			s := ""
			c := 0
			for key, value in obj.keyboard {
				if ( key != "States" && value){
					if (c){
						s .= " + "
					}
					s .= key
					c++
				}
			}
			return s
		}

		Class CKeyboard {
			States := {}
			
			__Get(aName){
				return this.States[aName] ? this.States[aName] : 0
			}
			
			__Set(aName, aValue){
				if (aName != "States"){
					this.States[aName] := aValue
					; When either l/r modifier goes down, set value of unified modifier
					; eg if lctrl goes down, set ctrl to on as well
					/*
					if (aName = "lctrl"){
						if (aValue = 1){
							this.States["ctrl"] := 1
						} else {
							if (!this.States["rctrl"]){
								; if right version is not down
								this.States["ctrl"] := 0
							}
						}
					}
					*/
				}
			}
			
			CheckInputState(input_obj){
				count := 0
				for key, value in input_obj {
					msgbox % "key: " key ", value: " value " - db: " this.States[key]
					count++
					if (this.States[key] != value){
						return 0
					}
				}
				; Only return 1 if we actially matched something
				return (count > 0)
			}
			
		}

	}
}
