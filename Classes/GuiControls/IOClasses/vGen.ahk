class vGen_Output extends _UCR.Classes.IOClasses.IOClassBase {
	static IOType := 2		; 1 for Input, 2 for Output
	static IOClass := "vGen_Output"
	static IsAnalog := 0
	
	static _vGenDeviceTypeNames := {0: "vJoy", 1: "vXBox"}
	static DllName := "vGenInterface"
	static _hModule := 0
	static _StickControlGUIDs := {}	; Contains GUIControl GUIDs that use each stick
	static _NumSticks := 0			; Numer of sticks supported. Will be overridden
	static _NumButtons := 0			; Numer of buttons supported.
	static _DeviceHandles := []
	
	static IsInitialized := 0
	static IsAvailable := 0
	
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
	
	static UCRMenuOutput := {}
	static ScpVBusInstalled := 0
	
	; All class properties that need to be common across all variants of this IOClass are stored on the base class
	static BaseClass := _UCR.Classes.IOClasses.vGen_Output
	
	_Init(){
		if (this.BaseClass.IsInitialized)
			return
		OutputDebug % "UCR| Initializing vJoy API"
		this.BaseClass.UCRMenuEntry := UCR.IOClassMenu.AddSubMenu("vJoy", "vJoy")
		this.BaseClass.UCRMenuEntry.AddMenuItem("Show &vJoy Log...", "ShowvJoyLog", this.ShowvJoyLog.Bind(this))
		this.BaseClass.UCRMenuOutput.vJoyInstalled := this.BaseClass.UCRMenuEntry.AddMenuItem("vJoy Installed (Required)", "vJoyInstalled").Disable()
		this.BaseClass.UCRMenuOutput.SCPVBusInstalled := this.BaseClass.UCRMenuEntry.AddMenuItem("SCPVBus Installed (Required for vXBox)", "SCPVBusInstalled").Disable()
		this.BaseClass.UCRMenuOutput.InstallSCPVBus := this.BaseClass.UCRMenuEntry.AddMenuItem("Install SCPVBus (Will Restart UCR)", "InstallSCPVBus", this.InstallUninstallScpVBus.Bind(this,1)).Disable()
		this.BaseClass.UCRMenuOutput.UninstallSCPVBus := this.BaseClass.UCRMenuEntry.AddMenuItem("Uninstall SCPVBus (Will Restart UCR)", "UninstallSCPVBus", this.InstallUninstallScpVBus.Bind(this,0)).Disable()
		this._LoadLibrary()
		
		this.BaseClass._POVStates.vJoy_Hat_Output := [[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]]
		
		this.BaseClass._POVStates.vXBox_Hat_Output := [[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]
		,[{x:0, y: 0},{x:0, y: 0},{x:0, y: 0},{x:0, y: 0}]]
	}
	
	IsBound(){
		return (this.DeviceID != 0)
	}
	
	_LoadLibrary(){
		this.LoadLibraryLog := ""
		this.BaseClass.UCRMenuOutput.vJoyInstalled.UnCheck()
		
		; Check if vJoy is installed. Even with the DLL, if vJoy is not installed it will not work...
		; Find vJoy install folder by looking for registry key.
		if (A_Is64bitOS && A_PtrSize != 8){
			SetRegView 64
		}
		RegRead vJoyFolder, HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8E31F76F-74C3-47F1-9550-E041EEDC5FBB}_is1, InstallLocation

		if (!vJoyFolder){
			this.LoadLibraryLog .= "ERROR: Could not find the vJoy Registry Key.`n`nvJoy does not appear to be installed.`nPlease ensure you have installed vJoy from`n`nhttp://vjoystick.sourceforge.net."
			this._SetInitState(0)
			return 0
		}
		
		; Try to find location of correct DLL.
		; vJoy versions prior to 2.0.4 241214 lack these registry keys - if key not found, advise update.
		if (A_PtrSize == 8){
			; 64-Bit AHK
			DllKey := "DllX64Location"
		} else {
			; 32-Bit AHK
			DllKey := "DllX86Location"
		}
		RegRead DllFolder, HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8E31F76F-74C3-47F1-9550-E041EEDC5FBB}_is1, % DllKey

		if (!DllFolder){
			; Could not find registry entry. Advise vJoy update.
			this.LoadLibraryLog .= "A vJoy install was found in " vJoyFolder ", but the relevant registry entries were not found.`nPlease update vJoy to the latest version from `n`nhttp://vjoystick.sourceforge.net."
			this._SetInitState(0)
			return 0
		}
		this.BaseClass.UCRMenuOutput.vJoyInstalled.Check()
		
		DllFolder .= "\"

		; All good so far, try and load the DLL
		DllFile := "vGenInterface.dll"
		this.LoadLibraryLog := "vJoy Install Detected. Trying to load " DllFile "...`n"
		CheckLocations := [DllFolder DllFile]

		hModule := 0
		Loop % CheckLocations.Maxindex() {
			this.LoadLibraryLog .= "Checking " CheckLocations[A_Index] "... "
			if (FileExist(CheckLocations[A_Index])){
				this.LoadLibraryLog .= "FOUND.`nTrying to load.. "
				hModule := DLLCall("LoadLibrary", "Str", CheckLocations[A_Index])
				if (hModule){
					this.hModule := hModule
					this.LoadLibraryLog .= "OK.`n"
					this.LoadLibraryLog .= "Checking driver enabled... "
					en := DllCall(DllFile "\vJoyEnabled", "Cdecl")
					if (en){
						this.LibraryLoaded := 1
						this.LoadLibraryLog .= "OK.`n"
						ver := DllCall(DllFile "\GetvJoyVersion", "Cdecl")
						this.LoadLibraryLog .= "Loaded vJoy DLL version " ver "`n"
						vb := this.IsVBusExist()
						if (vb){
							this.LoadLibraryLog .= "SCPVBus is installed`n"
						} else {
							this.LoadLibraryLog .= "SCPVBus is not installed (Non fatal)`n"
						}
						this.SetScpVBusState(vb)
						this._SetInitState(hModule)
						return 1
					} else {
						this.LoadLibraryLog .= "FAILED.`n"
					}
				} else {
					this.LoadLibraryLog .= "FAILED.`n"
				}
			} else {
				this.LoadLibraryLog .= "NOT FOUND.`n"
			}
		}
		this.LoadLibraryLog .= "`nFailed to load valid  " DllFile "`n"
		this.LibraryLoaded := 0
		this._SetInitState(0)
		return 0
	}
	
	_SetInitState(hMoudule){
		state := (hModule != 0)
		this.BaseClass._hModule := hModule
		this.BaseClass.IsAvailable := state
		this.BaseClass.IsInitialized := 1
	}
	
	ShowvJoyLog(){
		Clipboard := this.LoadLibraryLog
		msgbox % this.LoadLibraryLog "`n`nThis information has been copied to the clipboard"
	}
	
	InstallUninstallScpVBus(state){
		if (state == this.BaseClass.ScpVBusInstalled)
			return
		if (state){
			RunWait, *Runas devcon.exe install ScpVBus.inf root\ScpVBus, % A_ScriptDir "\Resources\ScpVBus", UseErrorLevel
		} else {
			RunWait, *Runas devcon.exe remove root\ScpVBus, % A_ScriptDir "\Resources\ScpVBus", UseErrorLevel
		}
		if (ErrorLevel == "ERROR")
			return 0
		Reload
		;~ ex := this.IsVBusExist()
		;~ if (ex != state)
			;~ return 0
		;~ this.SetScpVBusState(state)
		;~ return 1
	}
	
	SetScpVBusState(state){
		this.BaseClass.UCRMenuOutput.InstallSCPVBus.SetEnableState(!state)
		this.BaseClass.UCRMenuOutput.UninstallSCPVBus.SetEnableState(state)
		this.BaseClass.ScpVBusInstalled := state
		this.BaseClass.UCRMenuOutput.SCPVBusInstalled.SetCheckState(state)
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

	IsVBusExist(){
		ret := DllCall(this.DllName "\isVBusExist", "Cdecl")
		return (ret == 0)
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
		OutputDebug % "UCR| vGen_Output _UnRegister - IOClass " this.IOClass ", DevType: " this._GetDevTypeName() ", Device " this.DeviceID " of " this._NumSticks
		if (IsEmptyAssoc(this._StickControlGUIDs[this._vGenDeviceType, this.DeviceID])){
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
		if (IsEmptyAssoc(this._StickControlGUIDs[this._vGenDeviceType, this.DeviceID])){
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
				return 1
			}
		} else {
			; Already Acquired
			;OutputDebug % "UCR| IOClass " this.IOClass " has already Acquired Stick " this.DeviceID
			return 1
		}
		
	}
	
	_Relinquish(DeviceID){
		handle := this._DeviceHandles[this._vGenDeviceType, this.DeviceID]
		OutputDebug % "UCR| vGen _Relinquish Relinquishing " this._vGenDeviceType " device " DeviceID ", handle " this._DeviceHandles[this._vGenDeviceType, this.DeviceID]
		rel := DllCall(this.DllName "\RelinquishDev", "Ptr", handle, "Cdecl")
		this._DeviceHandles[this._vGenDeviceType, this.DeviceID] := 0
		if (rel == 0){
			OutputDebug % "UCR| IOClass " this.IOClass " Relinquished Stick " this.DeviceID
		}
		return (rel = 0) 
	}
	
	_GetDevTypeName(){
		return this._vGenDeviceTypeNames[this._vGenDeviceType]
	}
	
	UpdateMenus(cls){
		;OutputDebug % "UCR| UpdateMenus. This IOClass: " this.IOClass "  ||  _vGenDeviceType - this: " this._vGenDeviceType ", GuiControl: " this.ParentControl.GetBinding()._vGenDeviceType
		; Is the vGenDeviceType of the old class the same as the new class, and has a device been chosen ?
		bo := this.ParentControl.GetBinding()
		state := (this._vGenDeviceType == bo._vGenDeviceType && bo.DeviceID)
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
	
	UpdateBinding(){
		if (this.DeviceID && this.Binding[1]){
			OutputDebug % "UCR| " this.IOClass " UpdateBinding Registering"
			this._Register()
		} else {
			OutputDebug % "UCR| " this.IOClass " UpdateBinding UnRegistering"
			this._UnRegister()
		}
	}

	_Deserialize(obj){
		base._Deserialize(obj)
	}
}

; ============================================== vJoy =======================================
class vJoy_Base extends _UCR.Classes.IOClasses.vGen_Output {
	static _vGenDeviceType := 0		; 0 = vJoy, 1 = vXBox
	static _NumSticks := 8			; vJoy has 8 sticks
	static _Prefix := "vJoy"
}

; Handles selection of vJoy Stick
class vJoy_Stick extends _UCR.Classes.IOClasses.vJoy_Base {
	static IOClass := "vJoy_Stick"
	
	AddMenuItems(){
		menu := this.ParentControl.AddSubMenu(this._Prefix " Stick", this._Prefix "Stick")
		Loop % this._NumSticks {
			menu.AddMenuItem(A_Index, A_Index, this._ChangedValue.Bind(this, A_Index))
		}
	}
	
	BuildHumanReadable(){
		return this._Prefix " Stick " this.DeviceID "`n(No Button Selected)"
	}

	_ChangedValue(o){
		create_new := !this.ParentControl.IsBound()
		if (!create_new){
			create_new := (bo._vGenDeviceType != this._vGenDeviceType)
			if (!create_new){
				bo := this.ParentControl.GetBinding()._Serialize()
			}
		}
		if (create_new){
			; Create empty bindobject
			bo := new _UCR.Classes.IOClasses.BindObject()
		}
		bo.IOClass := this.IOClass
		
		if (o < 9){
			; Stick selected
			bo.DeviceID := o
		} else {
			return
		}
		this.ParentControl.SetBinding(bo)
	}
}

class vJoy_Button_Output extends _UCR.Classes.IOClasses.vJoy_Base {
	static IOClass := "vJoy_Button_Output"
	static _NumButtons := 128		; vJoy has 128 Buttons

	_JoyMenus := []

	Set(state){
		base.SetButtonState(state)
	}
	
	BuildHumanReadable(){
		return this._Prefix " Stick " this.DeviceID ", " this.BuildButtonName(this.Binding[1])
	}
	
	BuildButtonName(id){
		return "Button " id
	}
	
	AddMenuItems(){
		chunksize := 16
		Loop % round(this._NumButtons / chunksize) {
			offset := (A_Index-1) * chunksize
			menu := this.ParentControl.AddSubMenu(this._Prefix " Buttons " offset + 1 "-" offset + chunksize, this._Prefix "Btns" A_Index)
			this._JoyMenus.Push(menu)
			Loop % chunksize {
				btn := A_Index + offset
				menu.AddMenuItem(btn, btn, this._ChangedValue.Bind(this, btn))	; Set the callback when selected
				this._JoyMenus.Push(menu)
			}
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

}

class vJoy_Axis_Output extends _UCR.Classes.IOClasses.vJoy_Base {
	static IOClass := "vJoy_Axis_Output"
	static _NumAxes := 8			; vJoy has 8 Axes
	static AxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	static IsAnalog := 1
	
	_JoyMenus := []
	
	Set(state){
		base.SetAxisState(state)
	}
	
	BuildHumanReadable(){
		str := this._Prefix " Stick " this.DeviceID
		if (this.Binding[1]){
			str .= ", " this.BuildAxisName(this.Binding[1])
		} else {
			str .= "`n(No Axis Selected)"
		}
		return str
	}
	
	BuildAxisName(axis){
		return "Axis " axis
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
	
	_ChangedValue(o){
		bo := this.ParentControl.GetBinding()._Serialize()
		bo.IOClass := this.IOClass
		if (o < 9){
			; Stick selected
			bo.DeviceID := o
		} else if (o > 100 && o < 109){
			; Axis selected
			o -= 100
			bo.Binding[1] := o
		} else {
			return
		}
		this.ParentControl.SetBinding(bo)
	}
}

class vJoy_Hat_Output extends _UCR.Classes.IOClasses.vJoy_Base {
	static IOClass := "vJoy_Hat_Output"
	static _NumHats := 4
	static _HatDirections := ["Up", "Right", "Down", "Left"]
	static _HatName := "Hat"
	_JoyMenus := []
	
	Set(state){
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
	
	_ChangedValue(o){
		bo := this.ParentControl.GetBinding()._Serialize()
		bo.IOClass := this.IOClass
		if (o <= this._NumSticks){
			; Stick selected
			bo.DeviceID := o
		} else if (o > 100 && o <= (this._NumHats * 100) + 4){
			; Button selected
			;o -= 100
			bo.Binding := [o]
		} else {
			return
		}
		this.ParentControl.SetBinding(bo)
	}
}

; ==================================== vXBox =======================================
class vXBox_Base extends _UCR.Classes.IOClasses.vGen_Output {
	static _vGenDeviceType := 1		; 0 = vJoy, 1 = vXBox
	static _NumSticks := 4			; vXBox has 4 sticks
	static _Prefix := "vXBox"	
}

; Handles selection of vJoy Stick
class vXBox_Stick extends _UCR.Classes.IOClasses.vJoy_Stick {
	static IOClass := "vXBox_Stick"
	static _Prefix := "vXBox"
	static _vGenDeviceType := 1		; 0 = vJoy, 1 = vXBox
	static _NumSticks := 4			; vXBox has 4 sticks
}

class vXBox_Button_Output extends _UCR.Classes.IOClasses.vJoy_Button_Output {
	static IOClass := "vXBox_Button_Output"
	static _Prefix := "vXBox"
	static _vGenDeviceType := 1		; 0 = vJoy, 1 = vXBox
	static _ButtonNames := ["A", "B", "X", "Y", "LB", "RB", "Back","Start", "LS", "RS"]
	static _NumButtons := 10			; vXBox has 10 Buttons
	
	BuildButtonName(id){
		return this._ButtonNames[id]
	}
	
	AddMenuItems(){
		menu := this.ParentControl.AddSubMenu("vXBox Buttons", "vXBoxButtons")
		this._JoyMenus.Push(menu)
		Loop 10 {
			menu.AddMenuItem(this._ButtonNames[A_Index], A_Index, this._ChangedValue.Bind(this, A_Index))	; Set the callback when selected
			this._JoyMenus.Push(menu)
		}
	}
}

class vXBox_Axis_Output extends _UCR.Classes.IOClasses.vJoy_Axis_Output {
	static IOClass := "vXBox_Axis_Output"
	static _NumAxes := 6			; vXBox has 6 Axes
	static _Prefix := "vXBox"
	static _vGenDeviceType := 1		; 0 = vJoy, 1 = vXBox
	static AxisList := ["LS X", "LS Y", "RT", "RS X", "RS Y", "LT"]
	
	BuildAxisName(axis){
		return this.AxisList[axis]
	}
}

class vXBox_Hat_Output extends _UCR.Classes.IOClasses.vJoy_Hat_Output {
	static IOClass := "vXBox_Hat_Output"
	static _NumHats := 1
	static _Prefix := "vXBox"
	static _vGenDeviceType := 1		; 0 = vJoy, 1 = vXBox
	static _HatName := "D-Pad"
}
