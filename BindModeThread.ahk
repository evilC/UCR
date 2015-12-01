/*
Handles binding of the hotkeys for Bind Mode
Runs as a separate thread to the main application,
so that bind mode keys can be turned on and off quickly with Suspend
*/
#Persistent
BindMapper := new _BindMapper()
autoexecute_done := 1
#NoTrayIcon

class _BindMapper {
	DebugMode := 2	; 0 = block all, 1 = dont block LMB / RMB, 2 = no blocking
	HotkeysEnabled := 0
	__New(){
		this.MasterThread := AhkExported()
		
		; Make sure hotkeys are suspended before creating them,
		; so they are not active while they are being declared
		this.SetHotkeyState(0)
		this.CreateHotkeys()
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
				fn := this.HotkeyEvent.Bind(this, updown[A_Index].e, 0, i, 0)
				hotkey, % pfx blk n updown[A_Index].s, % fn, % "On"
			}
		}
		; Cycle through all Joystick Buttons
		Loop 8 {
			j := A_Index
			Loop 32 {
				btn := A_Index
				n := j "Joy" A_Index
				fn := this._JoystickButtonDown.Bind(this, 1, 1, btn, j)
				hotkey, % pfx n, % fn, % "On"
			}
		}
		critical off
	}
	
	HotkeyEvent(e, type, code, deviceid){
		if (!this.HotkeysEnabled)
			return
		ptr := &i
		this.MasterThread.ahkExec("UCR._BindModeHandler._ProcessInput(" e "," type "," code "," deviceid ")")
		;this.MasterThread.ahkExec("UCR._BindModeHandler._ProcessInput()")
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
	
	SetHotkeyState(state){
		if (state){
			Suspend, Off
		} else {
			Suspend, On
		}
		this.HotkeysEnabled := state
	}
}