class RawInput_Mouse_Delta extends _UCR.Classes.IOClasses.IOClassBase {
	static IOClass := "RawInput_Mouse_Delta"
	static IsInitialized := 1
	static IsAvailable := 1
	
	BuildHumanReadable(){
		if (this.DeviceID == -1 && this.Binding[1]){
			return "Any Mouse"
		}
		
		if (this.DeviceID && this.Binding[1]){
			return this.DeviceID
		}
		
		return "Unknown Mouse"
	}
}