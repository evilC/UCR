class TitanOne_Output extends _UCR.Classes.IOClasses.IOClassBase {
	static IsInitialized := 0
	static IsAvailable := 0
	static _hModule := 0
	
	static InputCodes := {PS3: 0x10, XB360: 0x20, Wii: 0x30, PS4: 0x40, XB1: 0x50}
	static InputNames := {0x10: "PS3", 0x20: "XB360", 0x30: "Wii", 0x40: "PS4", 0x50: "XB1"}
	static OutputCodes := {PS3: 0x1, XB360: 0x2, PS4: 0x3, XB1: 0x4}
	static OutputNames := {0x1: "PS3", 0x2: "XB360", 0x3: "PS4", 0x4: "XB1"}
	static OutputOrder := ["XB360", "XB1", "PS3", "PS4"]
	
	static ButtonMappings := {}

	Connections := 0	; Type of input + output that the Titan is currently set to.
						; Has Input + Output properties. Each will be one of the OutputNames (eg "XB360").
	WriteArray := {}	; Holds the Identifier Array
	
	_Init(){
		if (_UCR.Classes.IOClasses.TitanOne_Output.IsInitialized)
			return
		loaded := this._LoadLibrary()
		; Set Capacity for Write Array, and get a pointer to it
		this.WriteArray.SetCapacity("GCINPUT", 36)
		this.WriteArray.Ptr := this.WriteArray.GetAddress("GCINPUT")
		; Initialize the Write Array to all Zeros
		this.Reset()

		if (loaded){
			this.Acquire()
		}
		
		this.ButtonMappings.XB360 := [{name: "A", id: 19}
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
		this.ButtonMappings.XB1 := this.ButtonMappings.XB360
		this.ButtonMappings.PS3 := [{name: "Cross", id: 19}
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
		this.ButtonMappings.PS4 := [{name: "Cross", id: 19}
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
	}
	
	; Library loading and logging
	_LoadLibrary(){
		this.LoadLibraryLog := ""
		hModule := DLLCall("LoadLibrary", "Str", "Resources\gcdapi.dll", "Ptr")
		this.LoadLibraryLog .= "Loading Resources\gcdapi.dll returned " hModule "`n"
		if (hModule){
			; Initialize the API
			ret := DllCall("gcdapi\gcdapi_Load", "char")
			this.LoadLibraryLog .= "gcdapi\gcdapi_Load returned " ret "`n"
			if (ret){
				this.LoadLibraryLog .= "Titan One library loaded OK`n"
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
		while (A_TickCount < t && (!IsObject(this.Connections := this.GetConnections()))){
			sleep 10
		}
		if (this.Connections == 0){
			return 0
		}
	}
	
	ShowLog(){
		Clipboard := this.LoadLibraryLog
		msgbox % this.LoadLibraryLog "`n`nThis information has been copied to the clipboard"
	}

	_SetInitState(hMoudule){
		state := (hModule != 0)
		_UCR.Classes.IOClasses.TitanOne_Output._hModule := hModule
		_UCR.Classes.IOClasses.TitanOne_Output.IsAvailable := state
		_UCR.Classes.IOClasses.TitanOne_Output.IsInitialized := state
		UCR.IOClassMenu.AddSubMenu("Titan One", "TitanOne")
			.AddMenuItem("Show &Titan One Log...", "ShowTitanOneLog", this.ShowLog.Bind(this))
	}

	; Resets all Identifiers in the WriteArray to 0
	Reset(){
		DllCall("RtlFillMemory", "Ptr", this.WriteArray.Ptr, "Ptr", 36, "Char",0 ) ; Zero fill memory
	}

	; Sets the value of one of the identifiers
	SetIdentifier(index, state){
		NumPut(state, this.WriteArray.Ptr, index, "char")
	}

	; ------------------------ API calls ----------------------------

	; Passes the WriteArray to the API
	Write(){
		return DllCall("gcdapi\gcapi_Write", "uint", this.WriteArray.Ptr, "char")
	}

	; Returns type of controller for the input and output port
	GetConnections(){
		VarSetCapacity(GCAPI_REPORT , 500)
		if (!DllCall("gcdapi\gcapi_Read", "Ptr", &GCAPI_REPORT, "Char" )){
			return 0
		}
		output := NumGet(GCAPI_REPORT, 0, "char")
		input := NumGet(GCAPI_REPORT, 1, "char")
		return {output: this.OutputNames[output], input: this.OutputNames[input]}
	}
	
	SetButtonState(state){
		this.SetIdentifier(this.ButtonMappings[this.Connections.Output, this.Binding[1]].id, state)
	}
}

class TitanOne_Button_Output extends _UCR.Classes.IOClasses.TitanOne_Output {
	static IOClass := "TitanOne_Button_Output"
	static _NumButtons := 12
	
	BuildHumanReadable(){
		return this._Prefix " Titan One Buttton " this.BuildButtonName(this.Binding[1])
	}
	
	BuildButtonName(id){
		return id
	}
	
	AddMenuItems(){
		menu := this.ParentControl.AddSubMenu("Titan One Buttons", "TitanOneButtons")
		Loop % this._NumButtons {
			btn := A_Index
			str := ""
			for i, ot in this.OutputOrder {
				n := this.ButtonMappings[ot, btn].name
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





/*
		menu := this.ParentControl.AddSubMenu("Titan Axis", "TitanAxis")
		offset := 100
		Loop 6 {
			str := ""
			TitanAxes := UCR.Libraries.Titan.GetAxisNames()
			axis := A_Index
			str := " ( ", i := 0
			for console, axes in TitanAxes {
				if (!axes[axis])
					continue
				if (i){
					str .= " / "
				}
				str .= console " " axes[axis]
				i++
			}
			str .= ")"

			;names := GetAxisNames
			menu.AddMenuItem(A_Index str, A_Index, this._ChangedValue.Bind(this, offset + A_Index))
		}
		
		
		
				state := Round(state/327.67)
				UCR.Libraries.Titan.SetAxisByIndex(this.__value.Axis, state)


		*/
		
		/*
		TitanButtons := UCR.Libraries.Titan.GetButtonNames()
		menu := this.AddSubMenu("Titan Buttons", "TitanButtons")
		Loop 13 {
			btn := A_Index
			str := " ( ", i := 0
			for console, buttons in TitanButtons {
				if (!buttons[btn])
					continue
				if (i){
					str .= " / "
				}
				str .= console " " buttons[btn]
				i++
			}
			str .= ")"
			menu.AddMenuItem(A_Index str, "Button" A_Index, this._ChangedValue.Bind(this, 10000 + A_Index))
		}

		menu := this.AddSubMenu("Titan Hat", "TitanHat")
		Loop 4 {
			menu.AddMenuItem(HatDirections[A_Index], HatDirections[A_Index], this._ChangedValue.Bind(this, 10210 + A_Index))	; Set the callback when selected
		}
		*/
