class TitanOne_Output extends _UCR.Classes.IOClasses.IOClassBase {
	static IOType := 2
	static IsInitialized := 0
	static IsAvailable := 0
	static _hModule := 0
	
	static InputCodes := {PS3: 0x10, XB360: 0x20, Wii: 0x30, PS4: 0x40, XB1: 0x50}
	static InputNames := {0x10: "PS3", 0x20: "XB360", 0x30: "Wii", 0x40: "PS4", 0x50: "XB1", 0x60: "Switch"}
	static OutputCodes := {PS3: 0x1, XB360: 0x2, PS4: 0x3, XB1: 0x4, Switch: 0x5}
	static OutputNames := {0x1: "PS3", 0x2: "XB360", 0x3: "PS4", 0x4: "XB1", 0x5: "Switch"}
	static OutputOrder := ["XB360", "XB1", "PS3", "PS4", "Switch"]
	
	static ButtonMappings := {}
	static AxisMappings := {}
	; Maps Hat directions to Identifiers. Array of Arrays. Order is U, R, D, L
	static HatMappings := [13,16,14,15]	; 1 POV, Order is U, R, D, L
	
	static UCRMenuOutput := {}

	static Connections := 0	; Type of input + output that the Titan is currently set to.
							; Has Input + Output properties. Each will be one of the OutputNames (eg "XB360").
	static WriteArray := {}	; Holds the Identifier Array
	
	; All class properties that need to be common across all variants of this IOClass are stored on the base class
	static BaseClass := _UCR.Classes.IOClasses.TitanOne_Output
	
	_Init(){
		if (this.BaseClass.IsInitialized)
			return
		OutputDebug % "UCR| Initializing Titan One API"
		this.BaseClass.UCRMenuEntry := UCR.IOClassMenu.AddSubMenu("Titan One", "TitanOne")
		this.BaseClass.UCRMenuEntry.AddMenuItem("Show &Titan One Log...", "ShowTitanOneLog", this.ShowLog.Bind(this))
		this.BaseClass.UCRMenuEntry.AddMenuItem("Refresh Connected Devices", "RefreshConnections", this.Acquire.Bind(this))
		menu := this.BaseClass.UCRMenuEntry.AddSubMenu("Connected Output Device", "CurrentOutputDevice")
		for i, name in this.OutputOrder {
			item := menu.AddMenuItem(name, name, 0)
			item.Disable()
			this.BaseClass.UCRMenuOutput[name] := item
		}

		loaded := this._LoadLibrary()
		; Set Capacity for Write Array, and get a pointer to it
		this.BaseClass.WriteArray.SetCapacity("GCINPUT", 36)
		this.BaseClass.WriteArray.Ptr := this.BaseClass.WriteArray.GetAddress("GCINPUT")
		; Initialize the Write Array to all Zeros
		this.Reset()

		this.BaseClass.ButtonMappings.XB360 := [{name: "A", id: 19}
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
		this.BaseClass.ButtonMappings.XB1 := this.BaseClass.ButtonMappings.XB360
		this.BaseClass.ButtonMappings.PS3 := [{name: "Cross", id: 19}
			, {name: "Circle", id: 18}
			, {name: "Square", id: 20}
			, {name: "Triangle", id: 17}
			, {name: "L1", id: 6}
			, {name: "R1", id: 3}
			, {name: "L2", id: 7}
			, {name: "R2", id: 4}
			, {name: "L3", id: 8}
			, {name: "R3", id: 5}
			, {name: "Select", id: 1}
			, {name: "Start", id: 2}
			, {name: "Playstation", id: 0}]
		this.BaseClass.ButtonMappings.PS4 := [{name: "Cross", id: 19}
			, {name: "Circle", id: 18}
			, {name: "Square", id: 20}
			, {name: "Triangle", id: 17}
			, {name: "L1", id: 6}
			, {name: "R1", id: 3}
			, {name: "L2", id: 7}
			, {name: "R2", id: 4}
			, {name: "L3", id: 8}
			, {name: "R3", id: 5}
			, {name: "Share", id: 1}
			, {name: "Options", id: 2}
			, {name: "Playstation", id: 0}
			, {name: "Touch", id: 27}]
		
		; Nintendo Switch Start
		this.BaseClass.ButtonMappings.Switch := [{name: "A", id: 19}
			, {name: "B", id: 18}
			, {name: "X", id: 20}
			, {name: "Y", id: 17}
			, {name: "LB", id: 6}
			, {name: "RB", id: 3}
			, {}, {}
			, {name: "LS", id: 8}
			, {name: "RS", id: 5}
			, {name: "Minus", id: 1}
			, {name: "Plus", id: 2}
			, {name: "Home", id: 0}]
		
		this.BaseClass.AxisMappings.Switch := [{name: "LX", id: 11}
			,{name: "LY", id: 12, AxisType: 0}
			,{name: "RX", id: 9, AxisType: 0}
			,{name: "RY", id: 10, AxisType: 0}
			,{name: "LT", id: 7, AxisType: 1}
			,{name: "RT", id: 4, AxisType: 1}]
		; Nintendo Switch End
		
		this.BaseClass.AxisMappings.XB360 := [{name: "LX", id: 11}
			,{name: "LY", id: 12, AxisType: 0}
			,{name: "RX", id: 9, AxisType: 0}
			,{name: "RY", id: 10, AxisType: 0}
			,{name: "LT", id: 7, AxisType: 1}
			,{name: "RT", id: 4, AxisType: 1}]
		this.BaseClass.AxisMappings.XB1 := this.BaseClass.AxisMappings.XB360
		
		this.BaseClass.AxisMappings.PS3 := [{name: "LX", id: 11}
			,{name: "LY", id: 12, AxisType: 0}
			,{name: "RX", id: 9, AxisType: 0}
			,{name: "RY", id: 10, AxisType: 0}
			,{name: "L2", id: 7, AxisType: 1}
			,{name: "R2", id: 4, AxisType: 1}
			,{name: "ACCX", id: 21, AxisType: 2}
			,{name: "ACCY", id: 22, AxisType: 2}
			,{name: "ACCZ", id: 23, AxisType: 2}]
			
		this.BaseClass.AxisMappings.PS4 := [{name: "LX", id: 11}
			,{name: "LY", id: 12, AxisType: 0}
			,{name: "RX", id: 9, AxisType: 0}
			,{name: "RY", id: 10, AxisType: 0}
			,{name: "L2", id: 7, AxisType: 1}
			,{name: "R2", id: 4, AxisType: 1}
			,{name: "ACCX", id: 21, AxisType: 2}
			,{name: "ACCY", id: 22, AxisType: 2}
			,{name: "ACCZ", id: 23, AxisType: 2}
			,{name: "GYROX", id: 24, AxisType: 0}
			,{name: "GYROY", id: 25, AxisType: 0}
			,{name: "TOUCHX", id: 28, AxisType: 0}
			,{name: "TOUCHY", id: 29, AxisType: 0}]
	}
	
	; Library loading and logging
	_LoadLibrary(){
		this.BaseClass.LoadLibraryLog := ""
		hModule := DLLCall("LoadLibrary", "Str", "Resources\gcdapi.dll", "Ptr")
		this.BaseClass.LoadLibraryLog .= "Loading Resources\gcdapi.dll returned " hModule "`n"
		if (hModule){
			; Initialize the API
			ret := DllCall("gcdapi\gcdapi_Load", "char")
			this.BaseClass.LoadLibraryLog .= "gcdapi\gcdapi_Load returned " ret "`n"
			if (ret){
				this.BaseClass.LoadLibraryLog .= "Titan One DLL loaded OK, checking for connected devices...`n"
				ret := this.Acquire()
				if (ret){
					this.BaseClass.LoadLibraryLog .= "Titan One Input type is: " this.BaseClass.Connections.Input "`n"
					this.BaseClass.LoadLibraryLog .= "Titan One Output type is: " this.BaseClass.Connections.Output "`n"
				} else {
					this.BaseClass.LoadLibraryLog .= "No connected devices were detected.`n"
				}
				this._SetInitState(hMoudule)
				return 1

			}
		}
		this._SetInitState(0)
		return 0
	}
	
	; Get the connection information.
	; Titan API seems to take a while to wake up at the start, so a timer is used
	Acquire(){
		; Depending on what device is connected, instantiate the appropriate class
		t := A_TickCount + 2000
		while (A_TickCount < t && (!IsObject(op := this.GetConnections()))){
			sleep 10
		}
		this.BaseClass.Connections := op
		if (op == 0){
			return 0
		}
		
		for i, name in this.OutputOrder {
			this.BaseClass.UCRMenuOutput[name].SetCheckState(name == op.output)
		}
		return 1
	}
	
	ShowLog(){
		Clipboard := this.BaseClass.LoadLibraryLog
		msgbox % this.BaseClass.LoadLibraryLog "`n`nThis information has been copied to the clipboard"
	}

	_SetInitState(hMoudule){
		OutputDebug % "UCR| Titan One API Initialized"
		state := (hModule != 0)
		this.BaseClass._hModule := hModule
		this.BaseClass.IsAvailable := state
		this.BaseClass.IsInitialized := 1
	}

	; Resets all Identifiers in the WriteArray to 0
	Reset(){
		DllCall("RtlFillMemory", "Ptr", this.BaseClass.WriteArray.Ptr, "Ptr", 36, "Char",0 ) ; Zero fill memory
	}

	; Sets the value of one of the identifiers
	SetIdentifier(index, state){
		NumPut(state, this.BaseClass.WriteArray.Ptr, index, "char")
	}

	; ------------------------ API calls ----------------------------

	; Passes the WriteArray to the API
	Write(){
		if (this.BaseClass.Connections.Output){
			return DllCall("gcdapi\gcapi_Write", "uint", this.BaseClass.WriteArray.Ptr, "char")
		} else {
			OutputDebug % "UCR| Titan API - Tried to write with no output set"
			return 0
		}
	}

	; Returns type of controller for the input and output port
	GetConnections(){
		VarSetCapacity(GCAPI_REPORT , 500)
		if (!DllCall("gcdapi\gcapi_Read", "Ptr", &GCAPI_REPORT, "Char" )){
			return 0
		}
		oc := NumGet(GCAPI_REPORT, 0, "char")
		ic := NumGet(GCAPI_REPORT, 1, "char")
		output := this.OutputNames[oc]
		input := this.InputNames[ic]
		if (input || output)
			return {output: output, input: input}
		return 0
	}
	
	SetButtonState(state){
		if (this.BaseClass.Connections.Output){
			this.SetIdentifier(this.BaseClass.ButtonMappings[this.BaseClass.Connections.Output, this.Binding[1]].id, state * 100)
		}
	}
	
	SetAxisState(state){
		if (this.BaseClass.Connections.Output){
			; If this is a half-axis (eg trigger), then do not stretch to fill full scale
			; When UCR passes an axis from one object to another, it is always in the scale 0..100
			; Titan uses -100..100 for normal axes, 0..100 for triggers and -25...25 for Accelerometer axes
			; So we just pass the value straight through for triggers, and stretch / shift the scale for other types of axis
			am := this.BaseClass.AxisMappings[this.BaseClass.Connections.Output, this.Binding[1]]
			; Input is always 0..100
			if (!am.AxisType) {
				; Full Axis: -100...+100
				state := (state * 2) - 100
			} else if (am.AxisType == 2){
				; "Quarter Axis" (eg PS4_ACCX/Y/Z): -25...25
				state := (state / 2) - 25
			}
			this.SetIdentifier(am.id, state)
		}
	}
	
	SetHatState(state){
		id := this.HatMappings[this.Binding[1]]
		OutputDebug % "UCR| SetHatState - output type=" this.BaseClass.Connections.Output ", Binding=" this.Binding[1] ", id=" id
		if (this.BaseClass.Connections.Output){
			this.SetIdentifier(id, state * 100)
		}
	}
}

; ======================================== BUTTON ==========================================
class TitanOne_Button_Output extends _UCR.Classes.IOClasses.TitanOne_Output {
	static IOClass := "TitanOne_Button_Output"
	static _NumButtons := 14
	
	BuildHumanReadable(){
		return this._Prefix " Titan One Buttton " this.BuildButtonName(this.Binding[1])
	}
	
	BuildButtonName(id){
		return id
	}
	
	AddMenuItems(){
		;OutputDebug % "UCR| Button AddMenuItems - this.BaseClass.Connections.Output=" this.BaseClass.Connections.Output
		menu := this.ParentControl.AddSubMenu("Titan One Buttons", "TitanOneButtons")
		Loop % this._NumButtons {
			btn := A_Index
			str := ""
			for i, ot in this.OutputOrder {
				n := this.BaseClass.ButtonMappings[ot, btn].name
				if (n){
					if (str)
						str .= " / "
					str .= ot " " n
				}
			}
			menu.AddMenuItem(A_Index " (" str " )", A_Index, this._ChangedValue.Bind(this, A_Index))	; Set the callback when selected
		}
	}

	_ChangedValue(o){
		bo := this.ParentControl.GetBinding()._Serialize()
		bo.IOClass := this.IOClass
		if (o <= this._NumButtons){
			; Button selected
			bo.Binding := [o]
		} else {
			return
		}
		this.ParentControl.SetBinding(bo)
	}
	
	Set(state){
		this.SetButtonState(state)
		this.Write()
	}
}

; ======================================== AXIS ==========================================
class TitanOne_Axis_Output extends _UCR.Classes.IOClasses.TitanOne_Output {
	static IOClass := "TitanOne_Axis_Output"
	static _NumAxes := 13
	
	BuildHumanReadable(){
		return this._Prefix " Titan One Axis " this.BuildAxisName(this.Binding[1])
	}
	
	BuildAxisName(id){
		return id
	}
	
	AddMenuItems(){
		menu := this.ParentControl.AddSubMenu("Titan One Axes", "TitanOneAxes")
		Loop % this._NumAxes {
			ax := A_Index
			str := ""
			for i, ot in this.OutputOrder {
				n := this.BaseClass.AxisMappings[ot, ax].name
				if (n){
					if (str)
						str .= " / "
					str .= ot " " n
				}
			}
			menu.AddMenuItem(ax " (" str " )", ax, this._ChangedValue.Bind(this, ax))	; Set the callback when selected
		}
	}
	
	_ChangedValue(o){
		bo := this.ParentControl.GetBinding()._Serialize()
		bo.IOClass := this.IOClass
		if (o <= this._NumAxes){
			; Button selected
			bo.Binding := [o]
		} else {
			return
		}
		this.ParentControl.SetBinding(bo)
	}
	
	Set(state){
		this.SetAxisState(state)
		this.Write()
	}
}

; ======================================== HAT ==========================================
class TitanOne_Hat_Output extends _UCR.Classes.IOClasses.TitanOne_Output {
	static IOClass := "TitanOne_Hat_Output"
	static _NumDirections := 4
	static HatDirections := ["Up", "Right", "Down", "Left"]
	
	BuildHumanReadable(){
		return this._Prefix " Titan One D-Pad " this.BuildHatName(this.Binding[1])
	}
	
	BuildHatName(id){
		return this.HatDirections[id]
	}
	
	AddMenuItems(){
		;OutputDebug % "UCR| Hat AddMenuItems. this.BaseClass.Connections.Output=" this.BaseClass.Connections.Output
		menu := this.ParentControl.AddSubMenu("Titan One D-Pad", "TitanOneHat")
		Loop % this._NumDirections {
			menu.AddMenuItem(this.BuildHatName(A_Index), A_Index, this._ChangedValue.Bind(this, A_Index))	; Set the callback when selected
		}
	}

	_ChangedValue(o){
		bo := this.ParentControl.GetBinding()._Serialize()
		bo.IOClass := this.IOClass
		if (o <= this._NumDirections){
			; Direction selected
			bo.Binding := [o]
		} else {
			return
		}
		this.ParentControl.SetBinding(bo)
	}
	
	Set(state){
		OutputDebug % "UCR| Set " state
		this.SetHatState(state)
		this.Write()
	}
}
