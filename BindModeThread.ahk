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
			if A_Index < 3
				continue	; debugging - do not map LMB, RMB
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
				k := new _Key({Code: i})				
				fn := this.HotkeyEvent.Bind(this, k, updown[A_Index].e)
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
	
	HotkeyEvent(i, e){
		if (!this.HotkeysEnabled)
			return
		ptr := &i
		this.MasterThread.ahkExec("UCR._BindModeHandler._ProcessInput(" ptr "," e ")")
		;this.MasterThread.ahkExec("UCR._BindModeHandler._ProcessInput()")
	}
	
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

; ======================================================================== KEY ===============================================================
; A key represents a single digital input - keybpard key, mouse button, joystick button etc
class _Key {
	Type := 0
	Code := 0
	DeviceID := 0

	_Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
		,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
		,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
		,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	__New(obj){
		this._Deserialize(obj)
	}
	
	IsModifier(){
		if (this.Type = 0 && ObjHasKey(this._Modifiers, this.Code))
			return 1
		return 0
	}
	
	RenderModifier(){
		return this._Modifiers[this.Code].s
	}
	
	_Serialize(){
		return {Type: this.Type, Code: this.Code, DeviceID: this.DeviceID}
	}
	
	_Deserialize(obj){
		for k, v in obj {
			this[k] := v
		}
	}
	
	BuildHumanReadable(){
		if this.Type = 0 {
			code := Format("{:x}", this.Code)
			return GetKeyName("vk" code)
		} else if (this.Type = 1){
			return this.DeviceID "Joy" this.code
		}
	}
}