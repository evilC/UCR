class RawInput_Mouse_Delta extends _UCR.Classes.IOClasses.IOClassBase {
	static IOClass := "RawInput_Mouse_Delta"
	
	static IsInitialized := 1
	static IsAvailable := 1
	
	;~ _Serialize(){
		;~ return {Binding: this.Binding, DeviceID: this.DeviceID}
	;~ }
	
	;~ _Deserialize(obj){
		;~ if (ObjHasKey(obj, "DeviceID"))
			;~ this.DeviceID := obj.DeviceID
		;~ if (ObjHasKey(obj, "Binding"))
			;~ this.Binding := obj.Binding
	;~ }
}