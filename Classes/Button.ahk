; ======================================================================== BUTTON ===============================================================
; Represents a single digital input / output - keyboard key, mouse button, (virtual) joystick button or hat direction
class _Button {
	; 0 = Unset, 1 = Key / Mouse
	; 2 = vJoy button, 3 = vJoy hat 1, 4 = vJoy hat 2, 5 = vJoy hat 3, 6 = vJoy hat 4
	; 7 = vXBox button, 8 = vXBox hat
	; 9 = Titan button, 10 = Titan hat
	Type := 0
	Code := 0
	DeviceID := 0
	UID := ""
	IsVirtual := 0		; Set to 1 for vJoy stick buttons / hats
	
	_Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
	,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
	,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
	,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})
	
	__New(obj){
		this._Deserialize(obj)
	}
	
	; Returns true if this Button is a modifier key on the keyboard
	IsModifier(){
		if (this.Type = 1 && ObjHasKey(this._Modifiers, this.Code))
			return 1
		return 0
	}
	
	; Renders the keycode of a Modifier to it's AHK Hotkey symbol (eg 162 for LCTRL to ^)
	RenderModifier(){
		return this._Modifiers[this.Code].s
	}
	
	; Builds the AHK key name
	BuildKeyName(){
		static replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 45: "Insert", 46: "Delete"}
		static additions := {14: "NumpadEnter"}
		if this.Type = 1 {
			if (ObjHasKey(replacements, this.Code)){
				return replacements[this.Code]
			} else if (ObjHasKey(additions, this.Code)){
				return additions[this.Code]
			} else {
				code := Format("{:x}", this.Code)
				return GetKeyName("vk" code)
			}
		} else if (this.Type = 2){
			return this.DeviceID "Joy" this.code
		} else if (this.Type > 2 && this.Type < 7){
			return this.DeviceID "JoyPov"
		}
	}
	
	; Builds a human readable version of the key name (Mainly for joysticks)
	BuildHumanReadable(){
		static hat_directions := ["Up", "Right", "Down", "Left"]
		if (this.Type = 1) {
			return this.BuildKeyName()
		} else if (this.Type = 2){
			if (this.code)
				return (this.IsVirtual ? "Virtual " : "") "Stick " this.DeviceID ", Button " this.code
			else
				return (this.IsVirtual ? "Virtual " : "") "Stick " this.DeviceID ", No Button Selected"
		} else if (this.Type > 2 && this.Type < 7){
			return (this.IsVirtual ? "Virtual " : "") "Stick " this.DeviceID ", Hat " this.Type - 2 " " hat_directions[this.code]
		} else if (this.Type == 9){
			return "Titan Button " this.code
		} else if (this.Type == 10){
			return "Titan Hat " hat_directions[this.code]
		}
	}
	
	_Serialize(){
		return {Type: this.Type, Code: this.Code, DeviceID: this.DeviceID, UID: this.UID, IsVirtual: this.IsVirtual}
	}
	
	_Deserialize(obj){
		for k, v in obj {
			this[k] := v
		}
	}
}
