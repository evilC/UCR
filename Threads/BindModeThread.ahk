/*
Handles binding of the hotkeys for Bind Mode
Runs as a separate thread to the main application,
so that bind mode keys can be turned on and off quickly with Suspend
*/

class _BindMapper {
	DetectionState := 0
	static IOClasses := {AHK_Common: 0, AHK_KBM_Input: 0, AHK_JoyBtn_Input: 0, AHK_JoyHat_Input: 0}
	__New(CallbackPtr){
		;this.Callback := ObjShare(CallbackPtr)
		this.Callback := CallbackPtr
		; Instantiate each of the IOClasses specified in the IOClasses array
		for name, state in this.IOClasses {
			; Instantiate an instance of a class that is a child class of this one. Thanks to HotkeyIt for this code!
			; Replace each 0 in the array with an instance of the relevant class
			call:=this.base[name]
			this.IOClasses[name] := new call(this.Callback)
			; debugging string
			if (i)
				names .= ", "
			names .= name
			i++
		}
		if (i){
			OutputDebug % "UCR| Input Thread loaded IOClasses: " names
		} else {
			OutputDebug % "UCR| Input Thread WARNING! Loaded No IOClasses!"
		}
		Suspend, On
	}
	
	; A request was received from the main thread to set the Dection state
	SetDetectionState(state){
		if (state == this.DetectionState)
			return
		for name, cls in this.IOClasses {
			cls.SetDetectionState(state)
		}
		this.DetectionState := state
	}

	; ==================================================================================================================

	class AHK_Common {
		__New(callback){
			this.Callback := callback
		}
		
		SetDetectionState(state){
			Suspend, % (state ? "Off", "On")
		}
	}
	
	; ==================================================================================================================
	class AHK_KBM_Input {
		static IOClass := "AHK_KBM_Input"
		DebugMode := 2
		
		__New(callback){
			this.Callback := callback
			this.CreateHotkeys()
		}
		
		; Binds a key to every key on the keyboard and mouse
		; Passes VK codes to GetKeyName() to obtain names for all keys
		; List of VKs: https://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
		; Keys are stored in the settings file by VK number, not by name.
		; AHK returns non-standard names for some VKs, these are patched to Standard values
		; Numpad Enter appears to have no VK, it is synonymous with Enter (VK0xD). Seeing as VKs 0xE to 0xF are Undefined by MSDN, we use 0xE for Numpad Enter.
		CreateHotkeys(){
			static replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 45: "Insert", 46: "Delete"}
			static pfx := "$*"
			static updown := [{e: 1, s: ""}, {e: 0, s: " up"}]
			; Cycle through all keys / mouse buttons
			Loop 256 {
				; Get the key name
				i := A_Index
				code := Format("{:x}", i)
				if (ObjHasKey(replacements, i)){
					n := replacements[i]
				} else {
					n := GetKeyName("vk" code)
				}
				if (n = "")
					continue
				; Down event, then Up event
				Loop 2 {
					blk := this.DebugMode = 2 || (this.DebugMode = 1 && i <= 2) ? "~" : ""
					fn := this.InputEvent.Bind(this, updown[A_Index].e, i)
					hotkey, % pfx blk n updown[A_Index].s, % fn, % "On"
				}
			}
			i := 14, n := "NumpadEnter"	; Use 0xE for Nupad Enter
			Loop 2 {
				blk := this.DebugMode = 2 || (this.DebugMode = 1 && i <= 2) ? "~" : ""
				fn := this.InputEvent.Bind(this, updown[A_Index].e, i)
				hotkey, % pfx blk n updown[A_Index].s, % fn, % "On"
			}
			/*
			; Cycle through all Joystick Buttons
			Loop 8 {
				j := A_Index
				Loop % this.JoystickCaps[j].btns {
					btn := A_Index
					n := j "Joy" A_Index
					fn := this._JoystickButtonDown.Bind(this, 1, 2, btn, j)
					hotkey, % pfx n, % fn, % "On"
				}
			}
			*/
			critical off
		}
		
		InputEvent(e, i){
			;tooltip % "code: " i ", e: " e
			this.Callback.Call(e, i, 0, this.IOClass)
		}
	}
	
	; ==================================================================================================================
	class AHK_JoyBtn_Input {
		static IOClass := "AHK_JoyBtn_Input"
		DebugMode := 1
		JoystickCaps := []
		
		__New(callback){
			this.Callback := callback
			this.CreateHotkeys()
		}
		
		; Binds a key to every key on the keyboard and mouse
		; Passes VK codes to GetKeyName() to obtain names for all keys
		; List of VKs: https://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
		; Keys are stored in the settings file by VK number, not by name.
		; AHK returns non-standard names for some VKs, these are patched to Standard values
		; Numpad Enter appears to have no VK, it is synonymous with Enter (VK0xD). Seeing as VKs 0xE to 0xF are Undefined by MSDN, we use 0xE for Numpad Enter.
		CreateHotkeys(){
			static updown := [{e: 1, s: ""}, {e: 0, s: " up"}]
			this.GetJoystickCaps()
			Loop 8 {
				j := A_Index
				Loop % this.JoystickCaps[j].btns {
					btn := A_Index
					n := j "Joy" A_Index
					fn := this.InputEvent.Bind(this, 1, btn, j)
					hotkey, % n, % fn, % "On"
					fn := this.InputEvent.Bind(this, 0, btn, j)
					hotkey, % n " up", % fn, % "On"
				}
			}
		}
		
		GetJoystickCaps(){
			Loop 8 {
				cap := {}
				cap.btns := GetKeyState(A_Index "JoyButtons")
				this.JoystickCaps.push(cap)
			}
		}
		
		InputEvent(e, i, deviceid){
			this.Callback.Call(e, i, deviceid, this.IOClass)
		}
	}

}

	
/*
	; Binds a key to every key on the keyboard and mouse
	; Passes VK codes to GetKeyName() to obtain names for all keys
	; List of VKs: https://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
	; Keys are stored in the settings file by VK number, not by name.
	; AHK returns non-standard names for some VKs, these are patched to Standard values
	; Numpad Enter appears to have no VK, it is synonymous with Enter (VK0xD). Seeing as VKs 0xE to 0xF are Undefined by MSDN, we use 0xE for Numpad Enter.
	CreateHotkeys(){
		static replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 45: "Insert", 46: "Delete"}
		static pfx := "$*"
		static updown := [{e: 1, s: ""}, {e: 0, s: " up"}]
		; Cycle through all keys / mouse buttons
		Loop 256 {
			; Get the key name
			i := A_Index
			code := Format("{:x}", i)
			if (ObjHasKey(replacements, i)){
				n := replacements[i]
			} else {
				n := GetKeyName("vk" code)
			}
			if (n = "")
				continue
			; Down event, then Up event
			Loop 2 {
				blk := this.DebugMode = 2 || (this.DebugMode = 1 && i <= 2) ? "~" : ""
				fn := this.HotkeyEvent.Bind(this, updown[A_Index].e, 1, i, 0)
				hotkey, % pfx blk n updown[A_Index].s, % fn, % "On"
			}
		}
		i := 14, n := "NumpadEnter"	; Use 0xE for Nupad Enter
		Loop 2 {
			blk := this.DebugMode = 2 || (this.DebugMode = 1 && i <= 2) ? "~" : ""
			fn := this.HotkeyEvent.Bind(this, updown[A_Index].e, 1, i, 0)
			hotkey, % pfx blk n updown[A_Index].s, % fn, % "On"
		}
		; Cycle through all Joystick Buttons
		Loop 8 {
			j := A_Index
			Loop % this.JoystickCaps[j].btns {
				btn := A_Index
				n := j "Joy" A_Index
				fn := this._JoystickButtonDown.Bind(this, 1, 2, btn, j)
				hotkey, % pfx n, % fn, % "On"
			}
		}
		critical off
	}
*/

/*
;#Persistent
;#NoTrayIcon
;autoexecute_done := 1

class _BindMapper {
	DebugMode := 2	; 0 = block all, 1 = dont block LMB / RMB, 2 = no blocking
	HotkeysEnabled := 0
	AllowJoystick := 1		; When detecting an output, we want to ignore all joystick buttons
	PovStrings := ["1JoyPOV", "2JoyPOV", "3JoyPOV", "4JoyPOV", "5JoyPOV", "6JoyPOV" ,"7JoyPOV" ,"8JoyPOV"]
	PovMap := [[0,0,0,0], [1,0,0,0], [1,1,0,0] , [0,1,0,0], [0,1,1,0], [0,0,1,0], [0,0,1,1], [0,0,0,1], [1,0,0,1]]
	PovStateBase := [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	JoystickCaps := []
	
	__New(CallbackPtr){
		;this.Callback := ObjShare(CallbackPtr)
		this.Callback := CallbackPtr
		this.GetJoystickCaps()
		
		; Make sure hotkeys are suspended before creating them,
		; so they are not active while they are being declared
		this.SetHotkeyState(0)
		this.CreateHotkeys()
	}
	
	GetJoystickCaps(){
		Loop 8 {
			cap := {}
			info := GetKeyState(A_Index "JoyInfo")
			if (InStr(info, "p"))
				cap.pov := 1
			else
				cap.pov := 0
			cap.btns := GetKeyState(A_Index "JoyButtons")
			this.JoystickCaps.push(cap)
		}
	}
	
	; Binds a key to every key on the keyboard and mouse
	; Passes VK codes to GetKeyName() to obtain names for all keys
	; List of VKs: https://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
	; Keys are stored in the settings file by VK number, not by name.
	; AHK returns non-standard names for some VKs, these are patched to Standard values
	; Numpad Enter appears to have no VK, it is synonymous with Enter (VK0xD). Seeing as VKs 0xE to 0xF are Undefined by MSDN, we use 0xE for Numpad Enter.
	CreateHotkeys(){
		static replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 45: "Insert", 46: "Delete"}
		static pfx := "$*"
		static updown := [{e: 1, s: ""}, {e: 0, s: " up"}]
		; Cycle through all keys / mouse buttons
		Loop 256 {
			; Get the key name
			i := A_Index
			code := Format("{:x}", i)
			if (ObjHasKey(replacements, i)){
				n := replacements[i]
			} else {
				n := GetKeyName("vk" code)
			}
			if (n = "")
				continue
			; Down event, then Up event
			Loop 2 {
				blk := this.DebugMode = 2 || (this.DebugMode = 1 && i <= 2) ? "~" : ""
				fn := this.HotkeyEvent.Bind(this, updown[A_Index].e, 1, i, 0)
				hotkey, % pfx blk n updown[A_Index].s, % fn, % "On"
			}
		}
		i := 14, n := "NumpadEnter"	; Use 0xE for Nupad Enter
		Loop 2 {
			blk := this.DebugMode = 2 || (this.DebugMode = 1 && i <= 2) ? "~" : ""
			fn := this.HotkeyEvent.Bind(this, updown[A_Index].e, 1, i, 0)
			hotkey, % pfx blk n updown[A_Index].s, % fn, % "On"
		}
		; Cycle through all Joystick Buttons
		Loop 8 {
			j := A_Index
			Loop % this.JoystickCaps[j].btns {
				btn := A_Index
				n := j "Joy" A_Index
				fn := this._JoystickButtonDown.Bind(this, 1, 2, btn, j)
				hotkey, % pfx n, % fn, % "On"
			}
		}
		critical off
	}
	
	; Rename - handles buttons also
	HotkeyEvent(e, type, code, deviceid){
		if (!this.HotkeysEnabled || (type > 1 && !this.AllowJoystick))
			return
		this.Callback.Call(e,type,code,deviceid)
	}
	
	; Simulate proper joystick button up events
	_JoystickButtonDown(e, type, code, deviceid){
		this.HotkeyEvent(e, type, code, deviceid)
		str := deviceid "Joy" code
		while (GetKeyState(str)){
			Sleep 10
		}
		this.HotkeyEvent(0, type, code, deviceid)
	}
	
	SetHotkeyState(state, enablejoysticks := 1){
		;OutputDebug % "UCR| SetHotkeyState"
		if (state){
			if (enablejoysticks)
				this.SetHatWatchState(1)
			Suspend, Off
		} else {
			if (enablejoysticks)
				this.SetHatWatchState(0)
			Suspend, On
		}
		this.HotkeysEnabled := state
		this.AllowJoystick := enablejoysticks
	}
	
	SetHatWatchState(state){
		fn := this.HatWatcher.Bind(this)
		if (state){
			this.PovStates := this.PovStateBase.Clone()
			SetTimer, % fn, 10
		} else {
			SetTimer, % fn, Off
		}
	}
	
	HatWatcher(){
		Loop 8 {
			if (this.JoystickCaps[j].pov == 0)
				continue
			joyid := A_Index
			pov := GetKeyState(this.PovStrings[joyid])
			if (pov = pov_states[joyid]){
				; do not process stick if nothing changed
				continue
			}
			if (pov = -1){
				state := 1
			} else {
				state := round(pov / 4500) + 2
			}
			
			Loop 4 {
				if (this.PovStates[joyid, A_Index] != this.PovMap[state, A_Index]){
					this.HotkeyEvent(this.PovMap[state, A_Index], 3, A_Index, joyid)
					;this._Callback.({Type: "h", Code: A_Index, joyid: joyid, event: pov_direction_map[state, A_Index], uid: joyid "h" A_Index})
					;ToolTip % pov_direction_names[A_Index] " - " this.PovMap[state, A_Index]
				}
			}
			pov_states[joyid] := pov
			this.PovStates[joyid] := this.PovMap[state]
		}
	}
}
*/