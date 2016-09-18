class AHK_KBM_Common extends _BindObject {
	static IsInitialized := 1
	static IsAvailable := 1
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
}

class AHK_KBM_Input extends AHK_KBM_Common {
	static IOClass := "AHK_KBM_Input"
	static OutputType := "AHK_KBM_Output"
	
	_CurrentBinding := 0
	static _Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
	,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
	,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
	,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	; THREAD COMMANDS
	UpdateBinding(){
		if (this._CurrentBinding != 0){
			this.RemoveHotkey()
		}
		keyname := this.BuildHotkeyString()
		if (keyname){
			fn := this.KeyEvent.Bind(this, 1)
			hotkey, % keyname, % fn, On
			fn := this.KeyEvent.Bind(this, 0)
			hotkey, % keyname " up", % fn, On
			OutputDebug % "UCR| Added hotkey " keyname
			this._CurrentBinding := keyname
		}
	}
	
	RemoveHotkey(){
		hotkey, % this._CurrentBinding, UCR_DUMMY_LABEL
		hotkey, % this._CurrentBinding, Off
		hotkey, % this._CurrentBinding " up", UCR_DUMMY_LABEL
		hotkey, % this._CurrentBinding " up", Off
		this._CurrentBinding := 0
	}
	
	KeyEvent(e){
		; ToDo: Parent will not exist in thread!
		
		OutputDebug % "UCR| KEY EVENT"
		this.ParentControl.ChangeStateCallback.Call(e)
		;msgbox % "Hotkey pressed - " this.ParentControl.Parentplugin.id
	}
	; == END OF THREAD COMMANDS
	
	_Delete(){
		this.RemoveHotkey()
	}
	
	__Delete(){
		OutputDebug % "UCR| AHK_KBM_Input Freed"
	}
}

class AHK_KBM_Output extends AHK_KBM_Common {
	static IOType := 1
	static IOClass := "AHK_KBM_Output"

	SetState(state){
		tooltip % "UCR| SetState: " state
	}
	
	AddMenuItems(){
		this.ParentControl.AddMenuItem("Select Keyboard / Mouse Binding...", "AHK_KBM_Output", this._ChangedValue.Bind(this, 1))
	}
	
	_ChangedValue(val){
		UCR._RequestBinding(this.ParentControl)
	}
}

class AHK_Joy_Buttons extends _BindObject {
	static IOClass := "AHK_Joy_Buttons"

	static IsInitialized := 1

	_CurrentBinding := 0
	
	UpdateBinding(){
		if (this._CurrentBinding != 0)
			this.RemoveHotkey()
		fn := this.ButtonEvent.Bind(this, 1)
		keyname := this.DeviceID "joy" this.Binding[1]
		hotkey, % keyname, % fn, On
		this._CurrentBinding := keyname
	}
	
	RemoveHotkey(){
		hotkey, % this.DeviceID "joy" this.Binding[1], UCR_DUMMY_LABEL
		hotkey, % this.DeviceID "joy" this.Binding[1], Off
		this._CurrentBinding := 0
	}
	
	_Delete(){
		this.RemoveHotkey()
	}
	
	BuildHumanReadable(){
		return "Joystick " this.DeviceID " Button " this.Binding[1]
	}
	
	ButtonEvent(e){
		this.ParentControl.ChangeStateCallback.Call(e)
	}
}

class AHK_Joy_Axes extends _BindObject {
	static IOClass := "AHK_Joy_Axes"
	
}