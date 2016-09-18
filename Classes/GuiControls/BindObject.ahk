; ======================================================================== BINDOBJECT ===============================================================
; A BindObject represents a collection of keys / mouse / joystick buttons
class _BindObject {
	/*
	; 0 = Unset, 1 = Key / Mouse
	; 2 = vJoy button, 3 = vJoy hat 1, 4 = vJoy hat 2, 5 = vJoy hat 3, 6 = vJoy hat 4
	; 7 = vXBox button, 8 = vXBox hat
	; 9 = Titan button, 10 = Titan hat
	Type := 0
	Buttons := []
	Wild := 0
	Block := 0
	Suppress := 0
	*/
	IOClass := 0
	IOType := 0		; 0 for Input, 1 for Output
	;DeviceType := 0	; Type of the Device - eg KBM (Keyboard/Mouse), Joystick etc. Meaning varies with IOType
	;DeviceSubType := 0	; Device Sub-Type, eg vGen DeviceType has vJoy/vXbox Sub-Types
	DeviceID := 0 		; Device ID, eg Stick ID for Joystick input or vGen output
	Binding := []		; Codes of the input(s) for the Binding.
					; Normally a single element, but for KBM could be up to 4 modifiers plus a key/button
	BindOptions := {}	; Options for Binding - eg wild / block for KBM

	__New(obj){
		this._Deserialize(obj)
	}
	
	_Serialize(){
		/*
		obj := {Buttons: [], Wild: this.Wild, Block: this.Block, Suppress: this.Suppress, Type: this.Type}
		Loop % this.Buttons.length(){
			obj.Buttons.push(this.Buttons[A_Index]._Serialize())
		}
		return obj
		*/
		return {Binding: this.Binding, BindOptions: this.BindOptions
		;	, IOType: this.IOType, DeviceType: this.DeviceType, DeviceSubType: this.DeviceSubType, DeviceID: this.DeviceID}
			, IOType: this.IOType, IOClass: this.IOClass, DeviceID: this.DeviceID}

	}
	
	_Deserialize(obj){
		for k, v in obj {
			this[k] := v
		}
	}
}

class AHK_KBM_Input extends _BindObject {
	IOClass := "AHK_KBM_Input"
	
	_CurrentBinding := 0
	_Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
	,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
	,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
	,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	UpdateBinding(){
		if (this._CurrentBinding != 0){ ;*[UCR]
			this.RemoveHotkey()
		}
		fn := this.KeyPressed.Bind(this)
		keyname := this.BuildHotkeyString()
		hotkey, % keyname, % fn
		this._CurrentBinding := keyname
	}
	
	RemoveHotkey(){
		try {
			hotkey, % this._CurrentBinding, UCR_DUMMY_LABEL
			hotkey, % this._CurrentBinding, Off
		}
		try {
			hotkey, % this._CurrentBinding " up", UCR_DUMMY_LABEL
			hotkey, % this._CurrentBinding " up", Off
		}
		this._CurrentBinding := 0
	}
	
	KeyPressed(){
		msgbox Hotkey pressed
	}

	; Builds a human-readable form of the BindObject
	BuildHumanReadable(){
		max := this.Binding.length()
		str := ""
		Loop % max {
			str .= this.BuildKeyName(this.Binding[A_Index])
			if (A_Index != max)
				str .= " + "
		}
		return str
	}
	
	; Builds an AHK hotkey string (eg ~^a) from a BindObject
	BuildHotkeyString(){
		bo := this.Binding
		if (!bo.Length())
			return ""
		str := ""
		if (this.BindOptions.Wild)
			str .= "*"
		if (!this.BindOptions.Block)
			str .= "~"
		max := bo.Length()
		Loop % max {
			key := bo[A_Index]
			if (A_Index = max){
				islast := 1
				nextkey := 0
			} else {
				islast := 0
				nextkey := bo[A_Index+1]
			}
			if (this.IsModifier(key) && (max > A_Index)){
				str .= this.RenderModifier(key)
			} else {
				str .= this.BuildKeyName(key)
			}
		}
		return str
	}
	
	; Builds the AHK key name
	BuildKeyName(code){
		static replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 45: "Insert", 46: "Delete"}
		static additions := {14: "NumpadEnter"}
		if (ObjHasKey(replacements, code)){
			return replacements[code]
		} else if (ObjHasKey(additions, code)){
			return additions[code]
		} else {
			return GetKeyName("vk" Format("{:x}", code))
		}
	}
	
	; Returns true if this Button is a modifier key on the keyboard
	IsModifier(code){
		return ObjHasKey(this._Modifiers, code)
	}
	
	; Renders the keycode of a Modifier to it's AHK Hotkey symbol (eg 162 for LCTRL to ^)
	RenderModifier(code){
		return this._Modifiers[code].s
	}
	
	_Delete(){
		this.RemoveHotkey()
	}
	
	__Delete(){
		OutputDebug % "UCR| AHK_KBM_Input Freed"
	}
}

class AHK_Joy_Input extends _BindObject {
	IOClass := "AHK_Joy_Input"
	
	RemoveHotkey(){
		
	}
	
	BuildHumanReadable(){
		return "Joystick " this.DeviceID " Button " this.Binding[1]
	}
	
	UpdateBinding(){
		fn := this.ButtonPressed.Bind(this)
		hotkey, % this.DeviceID "joy" this.Binding[1], % fn
	}
	
	ButtonPressed(){
		msgbox JoyButton Pressed
	}
}