; ======================================================================== BINDOBJECT ===============================================================
; A BindObject represents a collection of keys / mouse / joystick buttons
class _BindObject {
	/*
	; 0 = Unset, 1 = Key / Mouse
	; 2 = vJoy button, 3 = vJoy hat 1, 4 = vJoy hat 2, 5 = vJoy hat 3, 6 = vJoy hat 4
	; 7 = vXBox button, 8 = vXBox hat
	; 9 = Titan button, 10 = Titan hat
	Type := 0
	Buttons := []
	Wild := 0
	Block := 0
	Suppress := 0
	*/
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
	
	_Deserialize(obj){
		for k, v in obj {
			this[k] := v
		}
	}
}

class vJoy_Button_Output extends vGen_Output {
	static IOClass := "vJoy_Button_Output"
	
	_JoyMenus := []
	static _NumSticks := 8			; vJoy has 8 sticks
	static _NumButtons := 128		; vXBox has 10 Buttons
	
	BuildHumanReadable(){
		str := "vJoy Stick " this.DeviceID
		if (this.Binding[1]){
			str .= ", Button " this.Binding[1]
		} else {
			str .= " (No Button Selected)"
		}
		return str
	}
	
	AddMenuItems(){
		menu := this.ParentControl.AddSubMenu("vJoy Stick", "vJoyStick")
		Loop % this._NumSticks {
			menu.AddMenuItem(A_Index, A_Index, this._ChangedValue.Bind(this, A_Index))
		}
		
		chunksize := 16
		Loop % round(this._NumButtons / chunksize) {
			offset := (A_Index-1) * chunksize
			menu := this.ParentControl.AddSubMenu("vJoy Buttons " offset + 1 "-" offset + chunksize, "vJoyBtns" A_Index)
			this._JoyMenus.Push(menu)
			Loop % chunksize {
				btn := A_Index + offset
				menu.AddMenuItem(btn, btn, this._ChangedValue.Bind(this, 100 + btn))	; Set the callback when selected
				this._JoyMenus.Push(menu)
			}
		}
	}

	UpdateBinding(){
		if (this.DeviceID && this.Binding[1]){
			this._RegisterButton()
		}
	}
	
	_ChangedValue(o){
		if (o < 9){
			; Stick selected
			this.DeviceID := o
		} else if (o > 100 && o < 229){
			; Button selected
			o -= 100
			this.Binding[1] := o
		} else {
			return
		}
		this.ParentControl.value := this
	}

}


class vXBox_Button_Output extends vGen_Output {
	static IOClass := "vXBox_Button_Output"
	
	_JoyMenus := []
	static _ButtonNames := ["A", "B", "X", "Y", "LB", "RB", "Back","Start", "LS", "RS"]
	static _vGenDeviceType := 1		; 0 = vJoy, 1 = vXBox
	static _NumSticks := 4			; vXBox has 4 sticks
	static _NumButtons := 10			; vXBox has 10 Buttons
	
	BuildHumanReadable(){
		str := "vXBox Stick " this.DeviceID
		if (this.Binding[1]){
			str .=  ", Button " this._ButtonNames[this.Binding[1]]
		} else {
			str .= " (No Button Selected)"
		}
		return str
	}

	AddMenuItems(){
		menu := this.ParentControl.AddSubMenu("vXBox Stick", "vXBoxStick")
		Loop % this._NumSticks {
			menu.AddMenuItem(A_Index, A_Index, this._ChangedValue.Bind(this, A_Index))
		}
		
		menu := this.ParentControl.AddSubMenu("vXBox Buttons", "vXBoxButtons")
		this._JoyMenus.Push(menu)
		Loop 10 {
			menu.AddMenuItem(this._ButtonNames[A_Index], A_Index, this._ChangedValue.Bind(this, 100 + A_Index))	; Set the callback when selected
			this._JoyMenus.Push(menu)
		}

	}
	
	UpdateBinding(){
		if (this.DeviceID && this.Binding[1]){
			this._RegisterButton()
		}
	}
	
	_ChangedValue(o){
		if (o < 5){
			; Stick selected
			this.DeviceID := o
		} else if (o > 100 && o < 111){
			; Button selected
			o -= 100
			this.Binding[1] := o
		} else {
			return
		}
		this.ParentControl.value := this
	}

}

class vGen_Output extends _BindObject {
	static IOType := 1
	static IOClass := "vGen_Output"
	;static LibraryLoaded := vGen_Output._Init()
	
	static _vGenDeviceType := 0		; 0 = vJoy, 1 = vXBox
	static _vGenDeviceTypeNames := {0: "vJoy", 1: "vXBox"}
	static DllName := "vGenInterface"
	static _StickControlGUIDs := {}	; Contains GUIControl GUIDs that use each stick
	static _NumSticks := 0			; Numer of sticks supported. Will be overridden
	static _NumButtons := 0			; Numer of buttons supported.
	static _DeviceHandles := []
	
	static _hModule := 0
	
	_Init(){
		if (vGen_Output.IsInitialized)
			return
		dllpath := "Resources\" this.DllName ".dll"
		hModule := DllCall("LoadLibrary", "Str", dllpath, "Ptr")
		if (hModule == 0){
			OutputDebug % "UCR| IOClass " this.IOClass " Failed to load " dllpath
			vGen_Output.IsAvailable := 0
		} else {
			OutputDebug % "UCR| IOClass " this.IOClass " Loaded " dllpath
			vGen_Output.IsAvailable := 1
		}
		vGen_Output._hModule := hModule
		;ret := DllCall(this.DllName "\isVBusExist", "Cdecl int")
		vGen_Output.IsInitialized := 1
	}
	
	SetState(state){
		push := DllCall(this.DllName "\SetDevButton", "ptr", this._DeviceHandles[this._vGenDeviceType, this.DeviceID], "uint", this.Binding[1], "uint", 1, "Cdecl")
		sleep 1000
		push := DllCall(this.DllName "\SetDevButton", "ptr", this._DeviceHandles[this._vGenDeviceType, this.DeviceID], "uint", this.Binding[1], "uint", 0, "Cdecl")
	}
	
	_RegisterButton(){
		if (!this._AttemptAcquire()){
			return 0
		}
		this._SetStickControlGuid(this.DeviceID, this.ParentControl.id, 1)
		OutputDebug % "UCR| _RegisterButton - IOClass " this.IOClass ", DevType: " this._GetDevTypeName() ", Device " this.DeviceID " of " this._NumSticks
		return 1
	}
	
	_UnRegister(){
		this._SetStickControlGuid(this.DeviceID, this.ParentControl.id, 0)
		OutputDebug % "UCR| _UnRegister - IOClass " this.IOClass ", DevType: " this._GetDevTypeName() ", Device " this.DeviceID " of " this._NumSticks
		if (this.IsEmptyAssoc(this._StickControlGUIDs[this._vGenDeviceType, this.DeviceID])){
			this._Relinquish(this.DeviceID)
		}
	}
	
	; Registers a GuiControl as "owning" a stick
	_SetStickControlGuid(DeviceID, GUID, state){
		; Initialize arrays if they do not exist
		if (!this._StickControlGUIDs[this._vGenDeviceType].length()){
			this._StickControlGUIDs[this._vGenDeviceType] := []
		}
		if (!IsObject(this._StickControlGUIDs[this._vGenDeviceType, this.DeviceID])){
			this._StickControlGUIDs[this._vGenDeviceType, this.DeviceID] := {}
		}
		; update record
		if (state){
			this._StickControlGUIDs[this._vGenDeviceType, this.DeviceID, this.ParentControl.id] := 1
		} else {
			this._StickControlGUIDs[this._vGenDeviceType, this.DeviceID].Delete(this.ParentControl.id)
		}
	}
	
	_AttemptAcquire(){
		if (this.IsEmptyAssoc(this._StickControlGUIDs[this._vGenDeviceType, this.DeviceID])){
			;VarSetCapacity(dev, A_PtrSize)
			acq := DllCall(this.DllName "\AcquireDev", "uint", this.DeviceID, "uint", this._vGenDeviceType, "Ptr*", dev, "Cdecl")
			if (acq){
				OutputDebug % "UCR| IOClass " this.IOClass " Failed to Acquire Stick " this.DeviceID
				return 0
			} else {
				if (!this._DeviceHandles[this._vGenDeviceType].length()){
					this._DeviceHandles[this._vGenDeviceType] := []
				}
				this._DeviceHandles[this._vGenDeviceType, this.DeviceID] := dev
				OutputDebug % "UCR| IOClass " this.IOClass " Acquired Stick " this.DeviceID
				;msgbox % this.IsEmptyAssoc(this._StickControlGUIDs[this.DeviceID])
				return 1
			}
		} else {
			; Already Acquired
			OutputDebug % "UCR| IOClass " this.IOClass " has already Acquired Stick " this.DeviceID
			return 1
		}
		
	}
	
	_Relinquish(DeviceID){
		rel := DllCall(this.DllName "\RelinquishDev", "Ptr", this._DeviceHandles[this._vGenDeviceType, this.DeviceID], "Cdecl")
		this._DeviceHandles[this._vGenDeviceType, this.DeviceID] := 0
		if (rel == 0){
			OutputDebug % "UCR| IOClass " this.IOClass " Relinquished Stick " this.DeviceID
		}
		return (rel = 0) 
	}
	
	_GetDevTypeName(){
		return this._vGenDeviceTypeNames[this._vGenDeviceType]
	}
	
	IsEmptyAssoc(assoc){
		for k, v in assoc {
			return 0
		}
		return 1
	}
	
	_Deserialize(obj){
		base._Deserialize(obj)
	}
}
