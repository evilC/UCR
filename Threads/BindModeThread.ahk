/*
Handles binding of the hotkeys for Bind Mode
Runs as a separate thread to the main application,
so that bind mode keys can be turned on and off quickly with Suspend
*/
#Persistent
#NoTrayIcon
autoexecute_done := 1

class _BindMapper {
	DebugMode := 2	; 0 = block all, 1 = dont block LMB / RMB, 2 = no blocking
	HotkeysEnabled := 0
	AllowJoystick := 1		; When detecting an output, we want to ignore all joystick buttons
	PovStrings := ["1JoyPOV", "2JoyPOV", "3JoyPOV", "4JoyPOV", "5JoyPOV", "6JoyPOV" ,"7JoyPOV" ,"8JoyPOV"]
	PovMap := [[0,0,0,0], [1,0,0,0], [1,1,0,0] , [0,1,0,0], [0,1,1,0], [0,0,1,0], [0,0,1,1], [0,0,0,1], [1,0,0,1]]
	PovStateBase := [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	JoystickCaps := []
	
	__New(CallbackPtr){
		this.Callback := ObjShare(CallbackPtr)
		this.MasterThread := AhkExported()
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
	
	CreateHotkeys(){
		static pfx := "$*"
		static updown := [{e: 1, s: ""}, {e: 0, s: " up"}]
		; Cycle through all keys / mouse buttons
		Loop 256 {
			; Get the key name
			i := A_Index
			code := Format("{:x}", A_Index)
			n := GetKeyName("vk" code)
			if (n = "")
				continue
			; Down event, then Up event
			Loop 2 {
				blk := this.DebugMode = 2 || (this.DebugMode = 1 && i <= 2) ? "~" : ""
				fn := this.HotkeyEvent.Bind(this, updown[A_Index].e, 1, i, 0)
				hotkey, % pfx blk n updown[A_Index].s, % fn, % "On"
			}
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