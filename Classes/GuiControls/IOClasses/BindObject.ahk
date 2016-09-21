; ======================================================================== BINDOBJECT ===============================================================
; A BindObject represents a collection of keys / mouse / joystick buttons
class _BindObject {
	static IOClass := 0
	static IOType := 0		; 0 for Input, 1 for Output
	;DeviceType := 0	; Type of the Device - eg KBM (Keyboard/Mouse), Joystick etc. Meaning varies with IOType
	;DeviceSubType := 0	; Device Sub-Type, eg vGen DeviceType has vJoy/vXbox Sub-Types
	DeviceID := 0 		; Device ID, eg Stick ID for Joystick input or vGen output
	Binding := []		; Codes of the input(s) for the Binding.
					; Normally a single element, but for KBM could be up to 4 modifiers plus a key/button
	BindOptions := {}	; Options for Binding - eg wild / block for KBM

	static IsInitialized := 0
	static IsAvailable := 0

	__New(parent, obj := 0){
		this.ParentControl := parent
		if (obj == 0){
			obj := {}
		}
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
	
	UpdateMenus(cls){
	}

	_Deserialize(obj){
		for k, v in obj {
			this[k] := v
		}
	}
}