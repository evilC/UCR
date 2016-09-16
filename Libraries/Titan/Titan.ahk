;#include Libraries\vjoy\CvJoyInterface.ahk

class Titan {
	Loaded := 0
	Acquired := 0
	
	InputCodes := {PS3: 0x10, XB360: 0x20, Wii: 0x30, PS4: 0x40, XB1: 0x50}
	InputNames := {0x10: "PS3", 0x20: "XB360", 0x30: "Wii", 0x40: "PS4", 0x50: "XB1"}
	OutputCodes := {PS3: 0x1, XB360: 0x2, PS4: 0x3, XB1: 0x4}
	OutputNames := {0x1: "PS3", 0x2: "XB360", 0x3: "PS4", 0x4: "XB1"}
	
	GetButtonNames(){
		names := {}
		for console, unused in this.OutputCodes {
			cls := this[console "_output"]
			max := cls.ButtonMappings.Length()
			if (max){
				names[console] := []
				Loop % max {
					names[console].push(cls.ButtonMappings[A_Index].name)
				}
				;names[console] := cls.ButtonMappings.clone()
			}
		}
		return names
	}
	
	__New(){
		if (!this.hModule := DLLCall("LoadLibrary", "Str", "Resources\gcdapi.dll")){
			return
		}
		
		; Initialize the API
		this.Loaded := DllCall("gcdapi\gcdapi_Load", "char")
		return this
	}
	
	_UCR_LoadLibrary(){
		return this.Loaded
	}
	
	Acquire(){
		; Depending on what device is connected, instantiate the appropriate class
		t := A_TickCount + 2000
		while (A_TickCount < t && (!IsObject(this.Connections := this.GetConnections()))){
			sleep 10
		}
		if (this.Connections == 0){
			return 0
		}
		cls := this.OutputNames[this.Connections.output]
		if (cls){
			this.Acquired := 1
			this.output := new this[cls "_output"]
			return 1
		} else {
			return 0
		}
	}
	
	GetConnections(){
		VarSetCapacity(GCAPI_REPORT , 500)
		if (!DllCall("gcdapi\gcapi_Read", "Ptr", &GCAPI_REPORT, "Char" )){
			return 0
		}
		output := NumGet(GCAPI_REPORT, 0, "char")
		input := NumGet(GCAPI_REPORT, 1, "char")
		return {output: output, input: input}
	}
	
	; Sets a button by Index.
	; Use when you want to press buttons in a device-agnostic manner
	SetButtonByIndex(btn, state){
		if (!this.Acquired){
			if (!this.Acquire())
				return 0
		}
		return this.output.SetButtonByIndex(btn, state)
	}
	
	; Set an Axis position by Index
	; Use when you want to move axes in a device-agnostic manner
	; State is in AHK range: 0...100
	SetAxisByIndex(axis, state){
		if (!this.Acquired){
			if (!this.Acquire())
				return 0
		}
		return this.output.SetAxisByIndex(axis, state)
	}
	
	SetPovDirectionState(index, dir, state){
		if (!this.Acquired){
			if (!this.Acquire())
				return 0
		}
		return this.output.SetPovDirectionState(index, dir, state)
	}
		
	; Class for the XBox 360 type output
	; Derived from the base output class
	class xb360_output extends Titan.output {
		static ButtonMappings := [{name: "A", id: 19}
			, {name: "B", id: 18}
			, {name: "X", id: 20}
			, {name: "Y", id: 17}
			, {name: "LB", id: 6}
			, {name: "RB", id: 3}
			, {}, {}
			, {name: "LS", id: 8}
			, {name: "RS", id: 5}
			, {name: "Back", id: 1}
			, {name: "Start", id: 2}
			, {name: "XBox", id: 0}]
		static AxisIdentifiers   := [11,12, 9,10, 7, 4]
		static POVIdentifiers := [[13,16,14,15]]	; 1 POV, Order is U, R, D, L
		
		static AxisNames := ["LX", "LY", "RX", "RY", "LT", "RT"]
		static AxisIndexes := {LX:1, LY:2, RX:3, RY:4, LT:5, RT:6}
	}

	class xb1_output extends Titan.xb360_output {
		
	}
	
	class ps3_output extends Titan.output {
		static ButtonMappings := [{name: "Cross", id: 19}
			, {name: "Circle", id: 18}
			, {name: "Square", id: 20}
			, {name: "Triangle", id: 17}
			, {name: "L1", id: 6}
			, {name: "R1", id: 3}
			, {name: "L2", id: 7}
			, {name: "R2", id: 4}
			, {name: "LS", id: 8}
			, {name: "RS", id: 5}
			, {name: "Select", id: 1}
			, {name: "Start", id: 2}
			, {name: "Playstation", id: 0}]
		static AxisIdentifiers   := [11,12,9,10]
		static POVIdentifiers := [[13,16,14,15]]	; 1 POV, Order is U, R, D, L
		
		static AxisNames := ["LX", "LY", "RX", "RY"]
		static AxisIndexes := {LX:1, LY:2, RX:3, RY:4}
	}
	
	class ps4_output extends Titan.ps3_output {
		static ButtonMappings := [{name: "Cross", id: 19}
			, {name: "Circle", id: 18}
			, {name: "Square", id: 20}
			, {name: "Triangle", id: 17}
			, {name: "L1", id: 6}
			, {name: "R1", id: 3}
			, {name: "L2", id: 7}
			, {name: "R2", id: 4}
			, {name: "LS", id: 8}
			, {name: "RS", id: 5}
			, {name: "Share", id: 1}
			, {name: "Options", id: 2}
			, {name: "Playstation", id: 0}]
		static AxisNames := ["LX", "LY", "RX", "RY"]
		static AxisIndexes := {LX:1, LY:2, RX:3, RY:4}
	}
	
	; A base class for the various supported output controllers to derive from
	; Override the indicated class properties to configure the class for that controller type
	class output {
		static ButtonMappings := []
		; =========== Derive Class and Override these properties =============
		; Maps Axes to Identifiers
		; 1st element in array defines Identifier of Axis 1, 2nd element is Identifier of Axis 2, etc...
		static AxisIdentifiers := []
		; Maps POV directions to Identifiers. Array of Arrays. Order is U, R, D, L
		static POVIdentifiers := []
		
		; Lookup for Axis Index -> Name
		static AxisNames := ["LX", "LY", "RX", "RY", "LT", "RT"]
		; Lookup for Axis Name -> Index
		static AxisIndexes := {LX:1, LY:2, RX:3,RY:4,LT:5,RT:6}
		; ========== End of configuration section  ==========================
		WriteArray := {}	; Holds the Identifier Array
		PovStates := []
		__New(){
			this.POVCount := this.POVIdentifiers.Length()
			Loop % this.POVCount {
				this.PovStates[A_Index] := [0,0,0,0]
			}
			; Set Capacity for Write Array, and get a pointer to it
			this.WriteArray.SetCapacity("GCINPUT", 36)
			this.WriteArray.Ptr := this.WriteArray.GetAddress("GCINPUT")
			; Initialize the Write Array to all Zeros
			this.Reset()
		}
		
		; Resets all Identifiers in the WriteArray to 0
		Reset(){
			DllCall("RtlFillMemory", "Ptr", this.WriteArray.Ptr, "Ptr", 36, "Char",0 ) ; Zero fill memory
		}
		
		; Sets the value of one of the identifiers
		SetIdentifier(index, state){
			NumPut(state, this.WriteArray.Ptr, index, "char")
		}
		
		; Passes the WriteArray to the API
		Write(){
			ret := DllCall("gcdapi\gcapi_Write", "uint", this.WriteArray.Ptr, "char")
		}
		
		; Sets a button by Index.
		; Use when you want to press buttons in a device-agnostic manner
		SetButtonByIndex(btn, state){
			if (btn > this.ButtonMappings.Length()){ ;*[UCR]
				return 0
			}
			;this.SetIdentifier(this.ButtonIdentifiers[btn], state * 100)
			this.SetIdentifier(this.ButtonMappings[btn, "id"], state * 100)
			this.Write()
			return 1
		}
		
		; Set an Axis position by Index
		; Use when you want to move axes in a device-agnostic manner
		; State is in AHK range: 0...100
		SetAxisByIndex(axis, state){
			if (axis > 6){
				return 0
			}
			state := (state * 2) - 100
			this.SetIdentifier(this.AxisIdentifiers[axis], state)
			this.Write()
			return 1
		}
		
		; Sets a pov direction on or off
		SetPovDirectionState(index, dir, state){
			state_entry := this.PovStates[index, dir]
			if (state_entry != state){
				this.PovStates[index, dir] := state
				id := this.POVIdentifiers[index, dir]
				this.SetIdentifier(id, state * 100)
			}
			this.Write()
		}
	}
}