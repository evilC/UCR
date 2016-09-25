class vGen_Output extends _UCR._ControlClasses.IOClasses.IOClassBase {
	static IOType := 1
	static IOClass := "vGen_Output"
	;static LibraryLoaded := vGen_Output._Init()
	
	static _vGenDeviceTypeNames := {0: "vJoy", 1: "vXBox"}
	static DllName := "vGenInterface"
	static _hModule := 0
	static _StickControlGUIDs := {}	; Contains GUIControl GUIDs that use each stick
	static _NumSticks := 0			; Numer of sticks supported. Will be overridden
	static _NumButtons := 0			; Numer of buttons supported.
	static _DeviceHandles := []
	
	
	static _AngleToCardinals := {-1: {x: 0, y: 0}
		, 0: {x: 0, y: 1}		; Up
		, 45: {x: 1, y: 1}		; Up right
		, 90: {x: 1, y: 0}		; Right
		, 135: {x: 1, y: -1}	; Down right
		, 180: {x: 0, y: -1}	; Down
		, 225: {x: -1, y: -1}	; Down left
		, 270: {x: -1, y: 0}	; Left
		, 315: {x: -1, y: 1}}	; Up left
		;, 360: {x: 0, y: 1}}	; Up again, for safety
	static _IndexToCardinals := {-1: {x: 0, y: 0}
		, 1: {x: 0, y: 1}		; Up
		, 2: {x: 1, y: 0}		; Right
		, 3: {x: 0, y: -1}		; Down
		, 4: {x: -1, y: 0}}		; Left
	; Not static, will change - but needs to be shared amongst all class instances
	; Holds the state of each hat direction
	; Needed so we can merge two cardinal mappings from two plugins to get a diagonal
	static _POVStates := {}
	
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
		this._POVStates.vJoy_Hat_Output := [[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]]
		
		this._POVStates.vXBox_Hat_Output := [[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]]
		vGen_Output._hModule := hModule
		;ret := DllCall(this.DllName "\isVBusExist", "Cdecl int")
		vGen_Output.IsInitialized := 1
	}
	
	SetButtonState(state){
		; DWORD SetDevButton(HDEVICE hDev, UINT Button, BOOL Press);
		ret := DllCall(this.DllName "\SetDevButton", "ptr", this._DeviceHandles[this._vGenDeviceType, this.DeviceID], "uint", this.Binding[1], "uint", state, "Cdecl")
	}
	
	SetAxisState(state){
		; DWORD SetDevAxis(HDEVICE hDev, UINT Axis, FLOAT Value);
		ret := DllCall(this.DllName "\SetDevAxis", "ptr", this._DeviceHandles[this._vGenDeviceType, this.DeviceID], "uint", this.Binding[1], "Float", state, "Cdecl")
	}
	
	SetHatState(state){
		; DWORD SetDevPov(HDEVICE hDev, UINT nPov, FLOAT Value);
		h := this.GetHatStrings()
		change := this._IndexToCardinals[h.dir]
		old_state := this._POVStates[this.IOClass, this.DeviceID, h.hat]
		new_state := this._UpdatePovAngles(state, old_state, change)
		angle := this._StateToAngle(new_state)
		this._POVStates[this.IOClass, this.DeviceID, h.hat] := new_state
		;OutputDebug % "UCR| SetDevPov hat: " h.hat ", dir: " h.dir ", state: " state ", value:" angle ", old: x=" old_state.x ", y=" old_state.y ", new: x=" new_state.x ", y= " new_state.y
		ret := DllCall(this.DllName "\SetDevPov", "ptr", this._DeviceHandles[this._vGenDeviceType, this.DeviceID], "uint", h.hat, "Float", angle, "Cdecl")
	}

	_UpdatePovAngles(state, old_state, change){
		;OutputDebug % "UCR| _UpdatePovAngles received change of: x= " change.x ", y= " change.y ", state= " state
		ret := old_state.clone()
		for axis, dir in old_state {
			; Press of direction - add change
			if (change[axis]){
				ret[axis] := (state ? change[axis] : 0)
				;OutputDebug % "UCR| _UpdatePovAngles changing " axis " to " change[axis]
			}
		}
		return ret
	}

	_StateToAngle(state) {
		for angle, potential_state in this._AngleToCardinals {
			if (potential_state.x == state.x && potential_state.y == state.y){
				return angle
			}
		}
		return -1	; safety, should not be hit
	}
	
	_Register(){
		if (!this._AttemptAcquire()){
			return 0
		}
		this._SetStickControlGuid(this.DeviceID, this.ParentControl.id, 1)
		;OutputDebug % "UCR| _Register - IOClass " this.IOClass ", DevType: " this._GetDevTypeName() ", Device " this.DeviceID " of " this._NumSticks
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
			;OutputDebug % "UCR| IOClass " this.IOClass " has already Acquired Stick " this.DeviceID
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
	
	UpdateMenus(cls){
		;OutputDebug % "UCR| UpdateMenus. This IOClass: " this.IOClass "  ||  _vGenDeviceType - this: " this._vGenDeviceType ", GuiControl: " this.ParentControl.Get()._vGenDeviceType
		; Is the vGenDeviceType of the old class the same as the new class, and has a device been chosen ?
		state := (this._vGenDeviceType == this.ParentControl.Get()._vGenDeviceType && this.ParentControl.Get().DeviceID)
		for i, menu in this._JoyMenus {
			menu.SetEnableState(state)
		}
	}
	
	GetHatStrings(){
		hat := 0
		o := this.Binding[1]
		while (o > 100){
			hat++
			o -= 100
		}
		return {hat: hat, dir: o}
	}
	
	_Deserialize(obj){
		base._Deserialize(obj)
	}
}

; ============================================== vJoy =======================================
class vJoy_Base extends _UCR._ControlClasses.IOClasses.vGen_Output {
	static _vGenDeviceType := 0		; 0 = vJoy, 1 = vXBox
	static _NumSticks := 8			; vJoy has 8 sticks
	static _Prefix := "vJoy"	
}

class vJoy_Button_Output extends _UCR._ControlClasses.IOClasses.vJoy_Base {
	static IOClass := "vJoy_Button_Output"
	
	_JoyMenus := []
	static _NumButtons := 128		; vJoy has 128 Buttons
	
	SetState(state){
		base.SetButtonState(state)
	}
	
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
			this._Register()
		}
	}
	
	_ChangedValue(o){
		if (o < 9){
			; Stick selected
			this.DeviceID := o
			if (this.ParentControl.Get()._vGenDeviceType == this._vGenDeviceType){
				this.Binding[1] := this.ParentControl.Get().Binding[1]
			}
			
		} else if (o > 100 && o < 229){
			; Button selected
			o -= 100
			this.Binding[1] := o
			if (this.ParentControl.Get()._vGenDeviceType == this._vGenDeviceType){
				this.DeviceID := this.ParentControl.Get().DeviceID
			}
		} else {
			return
		}
		this.ParentControl.Set(this)
	}

}

class vJoy_Axis_Output extends _UCR._ControlClasses.IOClasses.vJoy_Base {
	static IOClass := "vJoy_Axis_Output"
	static _NumAxes := 8			; vJoy has 8 Axes
	static AxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	
	_JoyMenus := []
	
	SetState(state){
		base.SetAxisState(state)
	}
	
	BuildHumanReadable(){
		str := this._Prefix " Stick " this.DeviceID
		if (this.Binding[1]){
			str .= ", Axis " this.Binding[1]
		} else {
			str .= " (No Axis Selected)"
		}
		return str
	}
	
	AddMenuItems(){
		menu := this.ParentControl.AddSubMenu(this._Prefix " Stick", this._Prefix "Stick")
		Loop % this._NumSticks {
			menu.AddMenuItem(A_Index, A_Index, this._ChangedValue.Bind(this, A_Index))
		}
		
		menu := this.ParentControl.AddSubMenu(this._Prefix " Axes", this._Prefix "Axes")
		Loop % this._NumAxes {
			this._JoyMenus.Push(menu)
			menu.AddMenuItem(A_Index " (" this.AxisList[A_Index] ")", A_Index, this._ChangedValue.Bind(this, 100 + A_Index))	; Set the callback when selected
			this._JoyMenus.Push(menu)
		}
	}
	
	UpdateBinding(){
		if (this.DeviceID && this.Binding[1]){
			this._Register()
		}
	}
	
	_ChangedValue(o){
		if (o < 9){
			; Stick selected
			this.DeviceID := o
			if (this.ParentControl.Get()._vGenDeviceType == this._vGenDeviceType){
				this.Binding[1] := this.ParentControl.Get().Binding[1]
			}
		} else if (o > 100 && o < 109){
			; Axis selected
			o -= 100
			this.Binding[1] := o
			if (this.ParentControl.Get()._vGenDeviceType == this._vGenDeviceType){
				this.DeviceID := this.ParentControl.Get().DeviceID
			}
		} else {
			return
		}
		this.ParentControl.Set(this)
	}
}

class vJoy_Hat_Output extends _UCR._ControlClasses.IOClasses.vJoy_Base {
	static IOClass := "vJoy_Hat_Output"
	static _NumHats := 4
	static _HatDirections := ["Up", "Right", "Down", "Left"]
	static _HatName := "Hat"
	_JoyMenus := []
	
	SetState(state){
		base.SetHatState(state)
	}
	
	BuildHumanReadable(){
		h := this.GetHatStrings()
		hatstr := (this._NumHats > 1 ? h.hat " " : "")
		if (this.Binding[1]){
			str .= this._Prefix " Stick " this.DeviceID ", " this._HatName " " hatstr this._HatDirections[h.dir]
		} else {
			str .= " (No Button Selected)"
		}
		return str
	}

	AddMenuItems(){
		Loop % this._NumHats {
			hatnum := (this._NumHats > 1 ? " " A_Index : "")
			menu := this.ParentControl.AddSubMenu(this._Prefix " " this._HatName hatnum, this._Prefix "Hat" hatnum)
			this._JoyMenus.Push(menu)
			offset := A_Index * 100
			Loop 4 {
				menu.AddMenuItem(this._HatDirections[A_Index], A_Index, this._ChangedValue.Bind(this, A_Index + offset))
			}
		}
	}
	
	UpdateBinding(){
		if (this.DeviceID && this.Binding[1]){
			this._Register()
		}
	}
	
	_ChangedValue(o){
		if (o <= this._NumSticks){
			; Stick selected
			this.DeviceID := o
			if (this.ParentControl.Get()._vGenDeviceType == this._vGenDeviceType){
				this.Binding[1] := this.ParentControl.Get().Binding[1]
			}
		} else if (o > 100 && o <= (this._NumHats * 100) + 4){
			; Button selected
			;o -= 100
			this.Binding[1] := o
			if (this.ParentControl.Get()._vGenDeviceType == this._vGenDeviceType){
				this.DeviceID := this.ParentControl.Get().DeviceID
			}
		} else {
			return
		}
		this.ParentControl.Set(this)
	}
}

; ==================================== vXBox =======================================
class vXBox_Base extends _UCR._ControlClasses.IOClasses.vGen_Output {
	static _vGenDeviceType := 1		; 0 = vJoy, 1 = vXBox
	static _NumSticks := 4			; vXBox has 4 sticks
	static _Prefix := "vXBox"	
}

class vXBox_Button_Output extends _UCR._ControlClasses.IOClasses.vXBox_Base {
	static IOClass := "vXBox_Button_Output"
	
	_JoyMenus := []
	static _ButtonNames := ["A", "B", "X", "Y", "LB", "RB", "Back","Start", "LS", "RS"]
	static _NumButtons := 10			; vXBox has 10 Buttons
	
	SetState(state){
		base.SetButtonState(state)
	}
	
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
			this._Register()
		}
	}
	
	_ChangedValue(o){
		if (o < 5){
			; Stick selected
			this.DeviceID := o
			if (this.ParentControl.Get()._vGenDeviceType == this._vGenDeviceType){
				this.Binding[1] := this.ParentControl.Get().Binding[1]
			}
		} else if (o > 100 && o < 111){
			; Button selected
			o -= 100
			this.Binding[1] := o
			if (this.ParentControl.Get()._vGenDeviceType == this._vGenDeviceType){
				this.DeviceID := this.ParentControl.Get().DeviceID
			}
		} else {
			return
		}
		this.ParentControl.Set(this)
	}
}

class vXBox_Axis_Output extends _UCR._ControlClasses.IOClasses.vJoy_Axis_Output {
	static IOClass := "vXBox_Axis_Output"
	static _NumAxes := 6			; vXBox has 6 Axes
	static _Prefix := "vXBox"
	static _vGenDeviceType := 1		; 0 = vJoy, 1 = vXBox
	static AxisList := ["LS X", "LS Y", "RS X", "RS Y", "LT", "RT"]
}

class vXBox_Hat_Output extends _UCR._ControlClasses.IOClasses.vJoy_Hat_Output {
	static IOClass := "vXBox_Hat_Output"
	static _NumHats := 1
	static _Prefix := "vXBox"
	static _vGenDeviceType := 1		; 0 = vJoy, 1 = vXBox
	static _HatName := "D-Pad"
}
