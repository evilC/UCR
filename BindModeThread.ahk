#Persistent
BindMapper := new _BindMapper()
autoexecute_done := 1

class _BindMapper {
	DebugMode := 2
	HotkeysEnabled := 0
	__New(){
		this.MasterThread := AhkExported()

		this.SetHotkeyState(0)
		this.CreateHotkeys()
		;this.SetHotkeyState(1)
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
				;fn := this.HotkeyEvent.Bind(this, {type: 0, code: i, deviceid: 0}, updown[A_Index].e)
				;k := new _Key({Code: i})				
				;fn := this.HotkeyEvent.Bind(this, k, updown[A_Index].e)
				fn := this.HotkeyEvent.Bind(this, updown[A_Index].e, 0, i, 0)
				hotkey, % pfx blk n updown[A_Index].s, % fn, % "On"
			}
		}
		;~ ; Cycle through all Joystick Buttons
		;~ Loop 8 {
			;~ j := A_Index
			;~ Loop 32 {
				;~ btn := A_Index
				;~ n := j "Joy" A_Index
				;~ ;k := new _Key({Code: btn, Type: 1, DeviceID: j})
				;~ ;fn := this._JoystickButtonDown.Bind(this, k)
				;~ fn := this._JoystickButtonDown.Bind(this, {type: 1, code: btn, deviceid: j}, 1)
				;~ hotkey, % pfx n, % fn, % "On"
			;~ }
		;~ }
		critical off
	}
	
	HotkeyEvent(e, type, code, deviceid){
		if (!this.HotkeysEnabled)
			return
		ptr := &i
		this.MasterThread.ahkExec("UCR._BindModeHandler._ProcessInput(" e "," type "," code "," deviceid ")")
		;this.MasterThread.ahkExec("UCR._BindModeHandler._ProcessInput()")
	}
	
	;~ HotkeyEvent(i, e){
		;~ if (!this.HotkeysEnabled)
			;~ return
		;~ ptr := &i
		;~ this.MasterThread.ahkExec("UCR._BindModeHandler._ProcessInput(" ptr "," e ")")
		;~ ;this.MasterThread.ahkExec("UCR._BindModeHandler._ProcessInput()")
	;~ }
	
	_JoystickButtonDown(i, e){
		this.HotkeyEvent(i, e)
		str := i.deviceid "Joy" i.code
		while (GetKeyState(str)){
			Sleep 10
		}
		this.HotkeyEvent(i, 0)
	}
	
	SetHotkeyState(state){
		if (state){
			Suspend, Off
		} else {
			Suspend, On
		}
		this.HotkeysEnabled := state
	}
	
	test(){
		msgbox test
	}
}