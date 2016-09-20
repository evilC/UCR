; ToDo - Rename to IOControlClasses ?
; AHK IOClasses
; These classes handle most of the functionality of a GUIControl's appearance while bound to one of these IOClasses

; These IOClasses are for input detection methods that AHK supports natively
; ie the Hotkey command and GetKeystate for input and SendXXXX etc for Output

; Common functions for AHK Keyboard and Mouse GuiControls
class AHK_KBM_Common extends _BindObject {
	static IsInitialized := 1
	static IsAvailable := 1
	
	static _Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
	,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
	,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
	,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

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

; IOClass for AHK Keyboard and Mouse Input GuiControls
class AHK_KBM_Input extends AHK_KBM_Common {
	static IOClass := "AHK_KBM_Input"
	static OutputType := "AHK_KBM_Output"
	
	_CurrentBinding := 0

	_Delete(){
		this.RemoveBinding()
	}
	
	__Delete(){
		OutputDebug % "UCR| AHK_KBM_Input Freed"
	}
}

; IOClass for AHK Keyboard and Mouse Output GuiControls
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

; IOClass for AHK Joystick Button Input GuiControls
class AHK_Joy_Buttons extends _BindObject {
	static IOClass := "AHK_Joy_Buttons"
	static IsInitialized := 1

	_CurrentBinding := 0
	
	_Delete(){
		this.RemoveBinding()
	}
	
	BuildHumanReadable(){
		return "Stick " this.DeviceID " Button " this.Binding[1]
	}
	
	ButtonEvent(e){
		this.ParentControl.ChangeStateCallback.Call(e)
	}
}

; IOClass for AHK Joystick Axis Input GuiControls
class AHK_Joy_Axes extends _BindObject {
	static IOClass := "AHK_Joy_Axes"
	static IsInitialized := 1
	
	AddMenuItems(){
		menu := this.ParentControl.AddSubMenu("Stick", "AHKStick")
		Loop 8 {
			menu.AddMenuItem(A_Index, A_Index, this._ChangedValue.Bind(this, A_Index))
		}
		menu := this.ParentControl.AddSubMenu("Buttons " offset + 1 "-" offset + chunksize, "AHKBtns" A_Index)
		this._JoyMenus.Push(menu)
		Loop 6 {
			menu.AddMenuItem(A_Index, A_Index, this._ChangedValue.Bind(this, 100 + A_Index))	; Set the callback when selected
		}
	}
	
	_ChangedValue(o){
		if (o < 9){
			; Stick ID
			;this.DeviceID := o
		} else if (o > 100 && o < 107){
			; Axis ID
			o -= 100
			;this.Binding[1] := o
		}
		;msgbox % o
		;if (this.DeviceID && this.Binding[1])
		;UCR._RequestBinding(this.ParentControl)
	}
}

; IOClass for AHK Joystick Hat Input GuiControls
class AHK_Joy_Hats extends _BindObject {
	static IOClass := "AHK_Joy_Hats"
	static IsInitialized := 1
	
	; Builds a human-readable form of the BindObject
	BuildHumanReadable(){
		static hat_directions := ["Up", "Right", "Down", "Left"]
		return "Stick " this.DeviceID ", Hat " hat_directions[this.Binding[1]]
	}
}