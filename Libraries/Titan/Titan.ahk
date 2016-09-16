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
			if (cls.ButtonNames.Length()){
				names[console] := cls.ButtonNames.clone()
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
		;this.POVArray[index].SetState(state)
	}
		
	; Class for the XBox 360 type output
	; Derived from the base output class
	class xb360_output extends Titan.output {
		;                             1  2  3  4  5  6  7  8  9 10 11 12 13 14
		;static ButtonIdentifiers := [19,18,20,17, 6, 3, 1, 2, 8, 5, 0]
		static ButtonIdentifiers := [19,18,20,17, 6, 3, "", "", 8, 5, 1, 2, 0]
		static AxisIdentifiers   := [11,12, 9,10, 7, 4]
		static POVIdentifiers := [[13,16,14,15]]	; 1 POV, Order is U, R, D, L
		
		static ButtonNames := ["A", "B", "X", "Y", "LB", "RB", "", "", "LS", "RS", "Back", "Start", "Xbox"]
		static ButtonIndexes := {A:1, B:2, X:3, Y:4, LB:5, RB:6, Back:11, Start:12, LS:9, RS:10, XBox:13}
		static AxisNames := ["LX", "LY", "RX", "RY", "LT", "RT"]
		static AxisIndexes := {LX:1, LY:2, RX:3, RY:4, LT:5, RT:6}
	}

	class xb1_output extends Titan.xb360_output {
		
	}
	
	class ps3_output extends Titan.output {
		;                             1  2  3  4  5  6  7  8  9 10 11 12
		static ButtonIdentifiers := [19,18,20,17, 6, 3, 7 ,4, 8, 5, 1, 2, 0]
		static AxisIdentifiers   := [11,12,9,10]
		static POVIdentifiers := [[13,16,14,15]]	; 1 POV, Order is U, R, D, L
		
		static ButtonNames := ["Cross", "Circle", "Square", "Triangle", "L1", "R1", "L2", "R2", "LS", "RS", "Select", "Start", "Playstation"]
		static ButtonIndexes := {Triangle:4, Circle:2, Cross:1, Square:3, L2:7, R2:8, L1:5, R1:6, Select:11, Start:12, LS:9, RS: 10}
		static AxisNames := ["LX", "LY", "RX", "RY"]
		static AxisIndexes := {LX:1, LY:2, RX:3, RY:4}
	}
	
	class ps4_output extends Titan.ps3_output {
		static ButtonNames := ["Cross", "Circle", "Square", "Triangle", "L1", "R1", "L2", "R2", "LS", "RS", "Share", "Options", "Playstation"]
		static ButtonIndexes := {Triangle:4, Circle:2, Cross:1, Square:3, L2:7, R2:8, L1:5, R1:6, Share:11, Options:12, LS:9, RS: 10}
		static AxisNames := ["LX", "LY", "RX", "RY"]
		static AxisIndexes := {LX:1, LY:2, RX:3, RY:4}
	}
	
	; A base class for the various supported output controllers to derive from
	; Override the indicated class properties to configure the class for that controller type
	class output {
		; =========== Derive Class and Override these properties =============
		; Maps Buttons to Identifiers.
		; 1st element in array defines Identifier of Button 1, 2nd element is Identifier of Button 2, etc...
		static ButtonIdentifiers := []
		; Maps Axes to Identifiers
		; 1st element in array defines Identifier of Axis 1, 2nd element is Identifier of Axis 2, etc...
		static AxisIdentifiers := []
		; Maps POV directions to Identifiers. Array of Arrays. Order is U, R, D, L
		static POVIdentifiers := []
		
		 ; Lookup for Button Indexes -> Name
		 ; Example : {0:"XBox", 1:"A", 2:"B", 3:"X", 4:"Y", 5:"LB", 6:"RB", 7:"Back", 8:"Start", 9:"LS", 10:"RS" }
		static ButtonNames := {}
		; Lookup for Name -> Button Index
		; Example: {XBox:0, A:1, B:2, X:3, Y:4, LB:5, RB:6, Back:7, Start:8, LS:9, RS:10}
		static ButtonIndexes := {}
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
			if (btn > this.ButtonNames.Length()){
				return 0
			}
			this.SetIdentifier(this.ButtonIdentifiers[btn], state * 100)
			this.Write()
			return 1
		}
		
		; Set a button by name.
		; Possible names will vary depding on which type of controller is active
		; The various controller types (eg xbox, ps) will derive from this class...
		; ... and have different values for ButtonIndexes etc
		SetButtonByName(btn, state){
			if (ObjHasKey(this.ButtonIndexes, btn)){
				return this.SetButtonByIndex(this.ButtonIndexes[btn], state)
			} else {
				return 0
			}
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
		
		; Set an Axis position by name
		; As with buttons, AxisIndexes will vary depending with derived class
		; State is in AHK range: 0...100
		SetAxisByName(axis, state){
			if (ObjHasKey(this.AxisIndexes, axis)){
				return this.SetAxisByIndex(this.AxisIndexes[axis], state)
			} else {
				return 0
			}
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