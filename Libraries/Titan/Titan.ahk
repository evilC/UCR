;#include Libraries\vjoy\CvJoyInterface.ahk

class Titan {
	Loaded := 0
	Acquired := 0
	
	InputCodes := {ps3: 0x10, xb360: 0x20, wii: 0x30, ps4: 0x40, xb1: 0x50}
	InputNames := {0x10: "ps3", 0x20: "xb360", 0x30: "wii", 0x40: "ps4", 0x50: "xb1"}
	OutputCodes := {ps3: 0x1, xb360: 0x2, ps4: 0x3, xb1: 0x4}
	OutputNames := {0x1: "ps3", 0x2: "xb360", 0x3: "ps4", 0x4: "xb1"}
	
	__New(){
		this.hModule := DLLCall("LoadLibrary", "Str", "Resources\gcdapi.dll")
		if (!this.hModule){
			return
		}
		
		; Initialize the API
		ret := DllCall("gcdapi\gcdapi_Load", "char")
		
		; Ensure that the API is responding - sometimes we seem to have to wait to get connection info
		;t := A_TickCount + 2000
		;while (A_TickCount < t && (!IsObject(this.Connections := this.GetConnections()))){
		;	sleep 10
		;}
		;if (this.Connections == 0){
		;	return
		;}
		
		this.Loaded := ret
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
		this.output.SetAxisByIndex(axis, state)
		return 1
	}
	
	; Sets POV from a value you would get by reading a hat switch using GetKeyState()
	SetPovAHK(index, state){
		if (!this.Acquired){
			if (!this.Acquire())
				return 0
		}
		this.output.SetPovAHK(index, state)
	}
		
	; Class for the XBox 360 type output
	; Derived from the base output class
	class xb360_output extends Titan.output {
		; Button Indexes are same as DI button indexes. XBox button is 11
		;                             1  2  3  4  5  6  7  8  9 10 11
		static ButtonIdentifiers := [19,18,20,17, 6, 3, 1, 2, 8, 5, 0]
		static AxisIdentifiers   := [11,12, 9,10, 7, 4]
		static POVIdentifiers := [[13,16,14,15]]	; 1 POV, Order is U, R, D, L
		
		static ButtonNames := ["A", "B", "X", "Y", "LB", "RB", "Back", "Start", "LS", "RS", "Xbox"]
		static ButtonIndexes := {A:1, B:2, X:3, Y:4, LB:5, RB:6, Back:7, Start:8, LS:9, RS:10, XBox:11}
		static AxisNames := ["LX", "LY", "RX", "RY", "LT", "RT"]
		static AxisIndexes := {LX:1, LY:2, RX:3, RY:4, LT:5, RT:6}
	}

	class ps3_output extends Titan.output {
		; Button Indexes are same as DI button indexes when using a PS3 PC adapter
		; I got the indexes from here: http://forum.unity3d.com/threads/ps3-button-map.89288/
		; Shifted to 1-based not 0-based
		;                             1  2  3  4  5  6  7  8  9 10 11 12
		static ButtonIdentifiers := [17,18,19,20, 7, 4, 6, 3, 1, 2, 8, 5]
		static AxisIdentifiers   := [11,12,9,10]
		static POVIdentifiers := [[13,16,14,15]]	; 1 POV, Order is U, R, D, L
		
		static ButtonNames := ["Triangle", "Circle", "Cross", "Square", "L2", "R2", "L1", "R1", "Select", "Start", "LS", "RS"]
		static ButtonIndexes := {Triangle:1, Circle:2, Cross:3, Square:4, L2:5, R2:6, L1:7, R1:8, Select:9, Start:10, LS:11, RS: 12}
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
		POVArray := []
		__New(){
			this.POVCount := this.POVIdentifiers.Length()
			Loop % this.POVCount {
				this.POVArray.Push(new this.POV(this, this.POVIdentifiers[A_Index]))
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
			if (btn > 10){
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
		
		; Sets state of POVs (D-Pads).
		; Index is POV number - This will probably be 1
		; State is -1 for center, 1 for north, 2 for ne, 3 for e, 4 for se etc...
		; If mapping from a physical POV read via GetKeyState(), divide by 4500 (unless it's -1)
		SetPovAngle(index, state){
			if (!this.Acquired){
				if (!this.Acquire())
					return 0
			}
			this.POVArray[index].SetState(state)
		}
		
		; Sets POV from a value you would get by reading a hat switch using GetKeyState()
		SetPovAHK(index, state){
			if (state != -1){
				state := round(state/4500)
			}
			this.POVArray[index].SetState(state)
		}
		
		Class POV {
			static StateMap := {-1:[],0:[1],1:[1,2],2:[2],3:[2,3],4:[3],5:[3,4],6:[4],7:[4,1]}
			CurrentAngle := -1
			__New(parent, Identifiers){
				this.parent := parent
				this.Identifiers := Identifiers
			}
			
			SetState(state){
				if (state != this.CurrentAngle){
					new_buttons := this.StateMap[state]
					if (this.CurrentAngle != -1){
						old_buttons := this.StateMap[this.CurrentAngle]
						Loop % old_buttons.Length(){
							dir := old_buttons[A_Index]
							if dir not in new_buttons
							{
								this.parent.SetIdentifier(this.Identifiers[dir], 0)
							}
						}
					}
					Loop % new_buttons.Length(){
						dir := new_buttons[A_Index]
						this.parent.SetIdentifier(this.Identifiers[dir], 100)
					}
					this.CurrentAngle := state
					this.parent.Write()
				}
			}
		}
	}
}