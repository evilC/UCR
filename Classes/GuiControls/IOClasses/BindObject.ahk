; ======================================================================== BINDOBJECT ===============================================================
; A BindObject represents a collection of keys / mouse / joystick buttons, or other inputs
; It only stores the most basic of information - the inputs for a single "Binding"
class BindObject {
	static IOClass := "BindObject"
	static IOType := "AAA"
	
	DeviceID := 0 		; Device ID, eg Stick ID for Joystick input or vGen output
	Binding := 0		; Codes of the input(s) for the Binding. Is an indexed array once set
						; Normally a single element, but for KBM could be up to 4 modifiers plus a key/button
	
	IsBound(){
		return 0
	}
	
	ClearBinding(){
		this.Binding := []
	}
	
	_Serialize(){
		return {Binding: this.Binding, DeviceID: this.DeviceID}
	}
	
	_Deserialize(obj){
		if (ObjHasKey(obj, "DeviceID"))
			this.DeviceID := obj.DeviceID
		if (ObjHasKey(obj, "Binding"))
			this.Binding := obj.Binding
	}
}