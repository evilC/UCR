#SingleInstance force
#include <JSON>

global UCR_PLUGIN_WIDTH := 500, UCR_PLUGIN_FRAME_WIDTH := 540

global UCR
UCR := new UCRMain()
return

GuiClose:
	ExitApp

; ======================================================================== MAIN CLASS ===============================================================
Class UCRMain {
	_BindMode := 0
	Profiles := []
	CurrentProfile := 0
	PluginList := []
	__New(){
		Gui +HwndHwnd
		this.hwnd := hwnd

		str := A_ScriptName
		if (A_IsCompiled)
			str := StrSplit(str, ".exe")
		else
			str := StrSplit(str, ".ahk")
		this._SettingsFile := A_ScriptDir "\" str.1 ".ini"

		this._CreateGui()
		this._LoadSettings()
	}
	
	_CreateGui(){
		Gui % this.hwnd ":Show", % "x0 y0 w" UCR_PLUGIN_FRAME_WIDTH " h100", Main UCR Window
		
		; Profile Select DDL
		Gui, % this.hwnd ":Add", Text, xm y+10, Current Profile:
		Gui, % this.hwnd ":Add", DDL, % "x100 yp-5 hwndhProfileSelect w300"
		this.hProfileSelect := hProfileSelect
		fn := this._ProfileSelectChanged.Bind(this)
		GuiControl % this.hwnd ":+g", % this.hProfileSelect, % fn

		Gui, % this.hwnd ":Add", Button, % "hwndhAddProfile x+5 yp", Add
		this.hAddProfile := hAddProfile
		fn := this._AddProfile.Bind(this)
		GuiControl % this.hwnd ":+g", % this.hAddProfile, % fn

		Gui, % this.hwnd ":Add", Button, % "hwndhDeleteProfile x+5 yp", Delete
		this.hDeleteProfile := hDeleteProfile
		fn := this._DeleteProfile.Bind(this)
		GuiControl % this.hwnd ":+g", % this.hDeleteProfile, % fn

		; Add Plugin
		Gui, % this.hwnd ":Add", Text, xm y+10, Plugin Selection:
		Gui, % this.hwnd ":Add", DDL, % "x100 yp-5 hwndhPluginSelect w300"
		this.hPluginSelect := hPluginSelect

		Gui, % this.hwnd ":Add", Button, % "hwndhAddPlugin x+5 yp", Add
		this.hAddPlugin := hAddPlugin
		fn := this._AddPlugin.Bind(this)
		GuiControl % this.hwnd ":+g", % this.hAddPlugin, % fn
	}
	
	; Called when hProfileSelect changes through user interaction (They selected a new profile)
	_ProfileSelectChanged(){
		GuiControlGet, name, % this.hwnd ":", % this.hProfileSelect
		this._ChangeProfile(name)
	}
	
	; The user clicked the "Add Plugin" button
	_AddPlugin(){
		this.CurrentProfile._AddPlugin()
	}
	
	; We wish to change profile. This may happen due to user input, or application changing
	_ChangeProfile(name){
		if (IsObject(this.CurrentProfile))
			this.CurrentProfile._DeActivate()
		GuiControl, % this.hwnd ":ChooseString", % this.hProfileSelect, % name
		this.CurrentProfile := this.Profiles[name]
		this.CurrentProfile._Activate()
		this._ProfileChanged(this.CurrentProfile)
	}
	
	; Populate hProfileSelect with a list of available profiles
	_UpdateProfileSelect(){
		profiles := ["Default", "Global"]
		for profile in this.Profiles {
			if (profile = "Default" || profile = "Global")
				continue
			profiles.push(profile)
		}
		str := "|"
		max := profiles.length()
		Loop % max {
			if (A_Index > 1)
				str .= "|"
			name := this.Profiles[profiles[A_Index]].Name
			str .= name
			if (name = this.CurrentProfile.Name)
				str .= "|"
			if (A_Index = max)
				str .= "|"
		}
		GuiControl,  % this.hwnd ":", % this.hProfileSelect, % str
	}
	
	; Update hPluginSelect with a list of available Plugins
	_UpdatePluginSelect(){
		max := this.PluginList.length()
		Loop % max {
			if (A_Index > 1)
				str .= "|"
			str .= this.PluginList[A_Index]
			if (A_Index = 1){
				str .= "|"
				if (A_Index = max)
					str .= "|"
			}
		}
		GuiControl,  % this.hwnd ":", % this.hPluginSelect, % str
	}
	
	; User clicked add new profile button
	_AddProfile(){
		c := 1
		alreadyused := 1
		while (alreadyused){
			alreadyused := 0
			suggestedname := "Profile " c
			for name, obj in this.Profiles {
				if (name = suggestedname){
					alreadyused := 1
					break
				}
			}
			if (!alreadyused)
				break
			c++
		}
		choosename := 1
		prompt := "Enter a name for the Profile"
		while(choosename) {
			InputBox, name, Add Profile, % prompt, ,,130,,,,, % suggestedname
			if (!ErrorLevel){
				if (ObjHasKey(this.Profiles, Name)){
					prompt := "Duplicate name chosen, please enter a unique name"
					name := suggestedname
				} else {
					this.Profiles[name] := new _Profile(name)
					this._UpdateProfileSelect()
					this._ChangeProfile(Name)
					choosename := 0
				}
			} else {
				choosename := 0
			}
		}
	}
	
	; user clicked the Delete Profile button
	_DeleteProfile(){
		GuiControlGet, name, % this.hwnd ":", % this.hProfileSelect
		if (name = "Default" || name = "Global")
			return
		this.Profiles.Delete(name)
		this._UpdateProfileSelect()
		this._ChangeProfile("Default")
	}
	
	; Load a list of available plugins
	_LoadPluginList(){
		; Bodge
		this.PluginList := ["TestPlugin1", "TestPlugin2"]
	}
	
	; Load settings from disk
	_LoadSettings(){
		this._LoadPluginList()
		this._UpdatePluginSelect()
		
		FileRead, j, % this._SettingsFile
		if (j = ""){
			j := {"CurrentProfile":"Default","Profiles":{"Default":{}, "Global": {}}}
		} else {
			j := JSON.Load(j)
		}
		this._Deserialize(j)
		
		this._UpdateProfileSelect()
		this._ChangeProfile(this.CurrentProfile.Name)
	}
	
	; Serialize this object down to the bare essentials for loading it's state
	_Serialize(){
		obj := {CurrentProfile: this.CurrentProfile.Name}
		obj.Profiles := {}
		for name, profile in this.Profiles {
			obj.Profiles[name] := profile._Serialize()
		}
		return obj
	}

	; Load this object from simple data strutures
	_Deserialize(obj){
		this.Profiles := {}
		for name, profile in obj.Profiles {
			this.Profiles[name] := new _Profile(name)
			this.Profiles[name]._Deserialize(profile)
		}
		this.CurrentProfile := this.Profiles[obj.CurrentProfile]
	}
	
	; A child profile changed in some way - save state to disk
	; ToDo: improve. Only the thing that changed needs to be re-serialized. Cache values.
	_ProfileChanged(profile){
		obj := this._Serialize()
		
		jdata := JSON.Dump(obj, true)
		FileReplace(jdata,this._SettingsFile)
	}
	
	; The user selected the "Bind" option from a Hotkey GuiControl
	_RequestBinding(hk){
		if (!this._BindMode){
			this._BindMode := 1
			new _BindModeHandler(hk)
			this._BindMode := 0
			return 1
		}
		return 0
	}
}

; =================================================================== BIND MODE HANDLER ==========================================================
; Prompts the user for input and detects their choice of binding
class _BindModeHandler {
	DebugMode := 2
	SelectedBinding := 0
	BindMode := 1
	EndKey := 0
	HeldModifiers := {}
	ModifierCount := 0
	
	_Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
	,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
	,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
	,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	__New(bo){
		this._OriginalBindObject := bo
		this.SetHotkeyState(1)
	}
	
	; Turns on or off the hotkeys
	SetHotkeyState(state){
		static pfx := "$*"
		static current_state := 0
		static updown := [{e: 1, s: ""}, {e: 0, s: " up"}]
		onoff := state ? "On" : "Off"
		if (state = current_state)
			return
		current_state := state
		if (state){
			SplashTextOn, 300, 30, Bind  Mode, Press a key combination to bind
		} else {
			SplashTextOff
		}
		; Cycle through all keys / mouse buttons
		Loop 256 {
			; Get the key name
			i := A_Index
			code := Format("{:x}", A_Index)
			n := GetKeyName("vk" code)
			if (n = "")
				continue
			; Down event, then Up event
			Loop 2 {
				blk := this.DebugMode = 2 || (this.DebugMode = 1 && i <= 2) ? "~" : ""
				k := new _Key({Code: i})
				;k.Code := i
				fn := this.ProcessInput.Bind(this, k, updown[A_Index].e)
				if (state)
					hotkey, % pfx blk n updown[A_Index].s, % fn
				hotkey, % pfx blk n updown[A_Index].s, % fn, % onoff
			}
		}
		; Cycle through all Joystick Buttons
		Loop 8 {
			j := A_Index
			Loop 32 {
				btn := A_Index
				n := j "Joy" A_Index
				Loop 2 {
					k := new _Key({Code: btn, Type: 1, DeviceID: j})
					fn := this._JoystickButtonDown.Bind(this, k)
					if (state)
							hotkey, % pfx n updown[A_Index].s, % fn
						hotkey, % pfx n updown[A_Index].s, % fn, % onoff
					}
			}
		}
	}
	
	; Called when a key was pressed
	ProcessInput(i, e){
		if (!this.BindMode)
			return
		if (i.type){
			is_modifier := 0
		} else {
			is_modifier := i.IsModifier()
			; filter repeats
			;if (e && (is_modifier ? ObjHasKey(HeldModifiers, i.code) : EndKey) )
			if (e && (is_modifier ? ObjHasKey(this.HeldModifiers, i.code) : i.code = this.EndKey.code) )
				return
		}

		;~ ; Are the conditions met for end of Bind Mode? (Up event of non-modifier key)
		;~ if ((is_modifier ? (!e && ModifierCount = 1) : !e) && (i.type ? !ModifierCount : 1) ) {
		; Are the conditions met for end of Bind Mode? (Up event of any key)
		if (!e){
			; End Bind Mode
			this.BindMode := 0
			this.SetHotkeyState(0)
			bindObj := this._OriginalBindObject._value
			
			bindObj.Keys := []
			for code, key in this.HeldModifiers {
				bindObj.Keys.push(key)
			}
			bindObj.Keys.push(this.EndKey)
			this._OriginalBindObject.value := bindObj
			
			return
		} else {
			; Process Key Up or Down event
			if (is_modifier){
				; modifier went up or down
				if (e){
					this.HeldModifiers[i.code] := i
					this.ModifierCount++
				} else {
					this.HeldModifiers.Delete(i.code)
					this.ModifierCount--
				}
			} else {
				; regular key went down or up
				;if (i.type && ModifierCount){
				if (i.type && this.ModifierCount){
					; Reject joystick button + modifier - AHK does not support this
					if (e)
						SoundBeep
				} else if (e) {
					; Down event of non-modifier key - set end key
					this.EndKey := i
				}
			}
		}
		
		; Mouse Wheel u/d/l/r has no Up event, so simulate it to trigger it as an EndKey
		if (e && (i.code >= 156 && i.code <= 159)){
			this.ProcessInput(i, 0)
		}
	}
	
	_JoystickButtonDown(i){
		this.ProcessInput(i, 1)
		str := i.DeviceID "Joy" i.code
		while (GetKeyState(str)){
			Sleep 10
		}
		this.ProcessInput(i, 0)
	}
}

; ======================================================================== PROFILE ===============================================================
; The Profile class handles everything to do with Profiles.
; It has it's own GUI (this.hwnd), which is parented to the main GUI.
; The Profile's is parent to 0 or more plugins, which are each an instance of the _Plugin class.
; The Gui of each plugin appears inside the Gui of this profile.
Class _Profile {
	Name := ""
	Plugins := {}
	AssociatedApss := 0
	
	__New(name){
		this.UCR := parent
		this.Name := name
		this._CreateGui()
	}
	
	__Delete(){
		Gui, % this.hwnd ":Destroy"
	}
	
	_CreateGui(){
		Gui, +HwndhOld	; Preserve previous default Gui
		Gui, Margin, 5, 5
		Gui, new, HwndHwnd
		Gui, +VScroll
		this.hwnd := hwnd
		Gui, Show, % "x0 y140 w" UCR_PLUGIN_FRAME_WIDTH " h400 Hide", % "Profile: " this.Name
		Gui, % hOld ":Default"	; Restore previous default Gui
	}
	
	_Activate(){
		Gui, % this.hwnd ":Show"
	}
	
	_DeActivate(){
		Gui, % this.hwnd ":Hide"
	}
	
	_AddPlugin(){
		GuiControlGet, plugin, % UCR.hwnd ":", % UCR.hPluginSelect
		suggestedname := name := this._GetUniqueName(%plugin%)
		choosename := 1
		prompt := "Enter a name for the Plugin"
		while(choosename) {
			InputBox, name, Add Plugin, % prompt, ,,130,,,,, % name
			if (!ErrorLevel){
				if (ObjHasKey(this.Plugins, Name)){
					prompt := "Duplicate name chosen, please enter a unique name"
					name := suggestedname
				} else {
					this.Plugins[name] := new %plugin%(this, name)
					this.Plugins[name].Init()
					this.Plugins[name].Show()
					UCR._ProfileChanged(this)
					choosename := 0
				}
			} else {
				choosename := 0
			}
		}
	}
	
	_GetUniqueName(plugin){
		name := plugin.Type " "
		num := 1
		while (ObjHasKey(this.Plugins, name num)){
			num++
		}
		return name num
	}
	
	_Serialize(){
		obj := {}
		obj.Plugins := {}
		for name, plugin in this.Plugins {
			obj.Plugins[name] := plugin._Serialize()
		}
		return obj
	}
	
	_Deserialize(obj){
		for name, plugin in obj.Plugins {
			cls := plugin.Type
			this.Plugins[name] := new %cls%(this, name)
			this.Plugins[name].Init()
			this.Plugins[name]._Deserialize(plugin)
			this.Plugins[name].Show()
		}

	}
	
	_PluginChanged(plugin){
		UCR._ProfileChanged(this)
	}
}

; ======================================================================== PLUGIN ===============================================================
; The _Plugin class itself is never instantiated.
; Instead, plugins derive from the base _Plugin class.
Class _Plugin {
	static Type := "_Plugin"	; Change this to match the name of your class. It MUST be unique amongst ALL plugins.
	
	ParentProfile := 0			; Will point to the parent profile
	Name := ""					; The name the user chose for the plugin
	Hotkeys := {}				; An associative array, indexed by name, of child Hotkeys
	GuiControls := {}			; An associative array, indexed by name, of child GuiControls
	
	; Override this class in your derived class and put your Gui creation etc in here
	Init(){
		
	}
	
	; ------------------------------- PRIVATE -------------------------------------------
	; Do not override methods in here unless you know what you are doing!
	AddControl(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.GuiControls, name)){
			this.GuiControls[name] := new _GuiControl(this, name, ChangeValueCallback, aParams*)
			return this.GuiControls[name]
		}
	}
	
	AddHotkey(name, ChangeValueCallback, ChangeStateCallback, aParams*){
		if (!ObjHasKey(this.Hotkeys, name)){
			this.Hotkeys[name] := new _Hotkey(this, name, ChangeValueCallback, ChangeStateCallback, aParams*)
			return this.Hotkeys[name]
		}
	}
	
	__New(parent, name){
		this.ParentProfile := parent
		this.Name := name
		this._CreateGui()
	}
	
	_CreateGui(){
		Gui, new, HwndHwnd
		Gui, -Border
		this.hwnd := hwnd
	}
	
	Show(){
		Gui, % this.ParentProfile.hwnd ":Add", Gui, % "w" UCR_PLUGIN_WIDTH, % this.hwnd
	}
	
	_ControlChanged(ctrl){
		this.ParentProfile._PluginChanged(this)
	}
	
	_Serialize(){
		obj := {Type: this.Type}
		obj.GuiControls := {}
		for name, ctrl in this.GuiControls {
			obj.GuiControls[name] := ctrl._Serialize()
		}
		obj.Hotkeys := {}
		for name, ctrl in this.Hotkeys {
			obj.Hotkeys[name] := ctrl._Serialize()
		}
		return obj
	}
	
	_Deserialize(obj){
		this.Type := obj.Type
		for name, ctrl in obj.GuiControls {
			this.GuiControls[name]._Deserialize(ctrl)
		}
		for name, ctrl in obj.Hotkeys {
			this.Hotkeys[name]._Deserialize(ctrl)
		}
		
	}

}

; ======================================================================== GUICONTROL ===============================================================
; Wraps a GuiControl to make it's value persistent between runs.
class _GuiControl {
	__New(parent, name, ChangeValueCallback, aParams*){
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		Gui, % this.ParentPlugin.hwnd ":Add", % aParams[1], % "hwndhwnd " aParams[2], % aParams[3]
		this.hwnd := hwnd
		fn := this._ChangedValue.Bind(this)
		GuiControl, % this.ParentPlugin.hwnd ":+g", % this.hwnd, % fn
	}
	
	; Get / Set of .value
	value[]{
		; Read of current contents of GuiControl
		get {
			return this.__value
		}
		
		; When the user types something in a guicontrol, this gets called
		; Fire _ControlChanged on parent so new setting can be saved
		set {
			this.__value := value
			this.ParentPlugin._ControlChanged(this)
		}
	}
	
	; Get / Set of ._value
	_value[]{
		; this will probably not get called
		get {
			return this.__value
		}
		; Update contents of GuiControl, but do not fire _ControlChanged
		; Parent has told child state to be in, child does not need to notify parent of change in state
		set {
			this.__value := value
			GuiControl, , % this.hwnd, % value
		}
	}
	
	; The user typed something into the GuiControl
	_ChangedValue(){
		GuiControlGet, value, % this.ParentPlugin.hwnd ":", % this.hwnd
		this.value := value		; Set control value and fire change events to parent
		; If the script author defined a callback for onchange event of this GuiControl, then fire it
		if (IsObject(this.ChangeValueCallback)){
			this.ChangeValueCallback.()
		}
	}
	
	_Serialize(){
		obj := {_value: this._value}
		return obj
	}
	
	_Deserialize(obj){
		this._value := obj._value
	}

}

; ======================================================================== HOTKEY ===============================================================
; A class the script author can instantiate to allow the user to select a hotkey.
class _Hotkey {
	; Internal vars describing the bindstring
	_value := ""		; The bindstring of the hotkey (eg ~*^!a). The getter for .value returns this
	_hotkey := ""		; The bindstring without any modes (eg ^!a)
	_wild := 0			; Whether Wild (*) mode is on
	_passthrough := 1	; Whether Passthrough (~) mode is on
	_norepeat := 0		; Whether or not to supress repeat down events
	_type := 0			; 0 = keyboard / mouse, 1 = joystick button
	; Other internal vars
	_DefaultBanner := "Drop down the list to select a binding"
	_OptionMap := {Select: 1, Wild: 2, Passthrough: 3, Suppress: 4, Clear: 5}
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
		Gui, % this.ParentPlugin.hwnd ":Add", % "Combobox", % "hwndhwnd " aParams[1], % aParams[2]
		this.hwnd := hwnd
		
		fn := this._ChangedValue.Bind(this)
		GuiControl, % this.ParentPlugin.hwnd ":+g", % this.hwnd, % fn
		
		; Get Hwnd of EditBox part of ComboBox
		this._hEdit := DllCall("GetWindow","PTR",this.hwnd,"Uint",5) ;GW_CHILD = 5
		
		this._BuildOptions()
		this._SetCueBanner()
	}
	
	value[]{
		get {
			return this._value
		}
		
		set {
			this._value := value
			h := this._value.BuildHumanReadable()
			this._SetCueBanner()
			this.ParentPlugin._ControlChanged(this)
		}
	}

	; Builds the list of options in the DropDownList
	_BuildOptions(){
		;str := "|Select Binding|Wild: " (this._wild ? "On" : "Off") "|Passthrough: " (this._passthrough ? "On" : "Off") "|Repeat Supression: " (this._norepeat ? "On" : "Off") "|Clear Binding"
		;GuiControl, % this.ParentPlugin.hwnd ":" , % this.hwnd, % str
		this._CurrentOptionMap := [this._OptionMap["Select"]]
		str := "|Select Binding"
		if (this._type = 0){
			; Joystick buttons do not have these options
			str .= "|Wild: " (this._wild ? "On" : "Off") 
			this._CurrentOptionMap.push(this._OptionMap["Wild"])
			str .= "|Passthrough: " (this._passthrough ? "On" : "Off")
			this._CurrentOptionMap.push(this._OptionMap["Passthrough"])
			str .= "|Repeat Suppression: " (this._norepeat ? "On" : "Off")
			this._CurrentOptionMap.push(this._OptionMap["Suppress"])
		}
		str .= "|Clear Binding"
		this._CurrentOptionMap.push(this._OptionMap["Clear"])
		GuiControl, , % this.hwnd, % str
	}

	; Sets the "Cue Banner" for the ComboBox
	_SetCueBanner(){
		static EM_SETCUEBANNER:=0x1501
		;if (this._hotkey = "") {
		if (this._value.Keys.length()) {
			;Text := this._BuildHumanReadable()
			Text := this._value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner			
		}
		DllCall("User32.dll\SendMessageW", "Ptr", this._hEdit, "Uint", EM_SETCUEBANNER, "Ptr", True, "WStr", text)
		return this
	}
	
	; An option was selected from the list
	_ChangedValue(){
		; Find index of dropdown list. Will be really big number if key was typed
		SendMessage 0x147, 0, 0,, % "ahk_id " this.hwnd  ; CB_GETCURSEL
		o := ErrorLevel
		GuiControl, % this.ParentPlugin.hwnd ":Choose", % this.hwnd, 0
		if (o < 100){
			o++
			o := this._CurrentOptionMap[o]
			; Option selected from list
			if (o = 1){
				binding := UCR._RequestBinding(this)
				;~ if (binding = 0)
					;~ return
				;~ this._value := binding
				;~ this._SetCueBanner()
				;~ this.ParentPlugin._ControlChanged(this)
				return
			} else if (o = 2){
				this._wild := !this._wild
			} else if (o = 3){
				this._passthrough := !this._passthrough
			} else if (o = 4){
				this._norepeat := !this._norepeat
			} else if (o = 5){
				this._hotkey := ""
			} else {
				; not one of the options from the list, user must have typed in box
				return
			}
			;this.ChangeHotkey(this._hotkey)
		}
	}
	
	_Serialize(){
		return this._value._Serialize()
	}
	
	_Deserialize(obj){
		this._value := new _BindObject(obj)
		this._SetCueBanner()
	}
}

class _BindObject {
	Keys := []
	Wild := 0
	Block := 0
	Suppress := 0
	
	__New(obj){
		this._Deserialize(obj)
	}
	
	_Serialize(){
		obj := {Keys: [], Wild: this.Wild, Block: this.Block, Suppress: this.Suppress}
		Loop % this.Keys.length(){
			obj.Keys.push(this.Keys[A_Index]._Serialize())
		}
		return obj
	}
	
	_Deserialize(obj){
		for k, v in obj {
			if (k = "Keys"){
				Loop % v.length(){
					this.Keys.push(new _Key(v[A_Index]))
				}
			} else {
				this[k] := v
			}
		}
	}
	
	BuildHumanReadable(){
		max := this.Keys.length()
		str := ""
		Loop % max {
			str .= this.Keys[A_Index].BuildHumanReadable()
			if (A_Index != max)
				str .= " + "
		}
		return str
	}
}

class _Key {
	Type := 0
	Code := 0
	DeviceID := 0
	UID := ""

	_Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
		,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
		,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
		,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	__New(obj){
		this._Deserialize(obj)
	}
	
	IsModifier(){
		if (this.Type = 0 && ObjHasKey(this._Modifiers, this.Code))
			return 1
		return 0
	}
	
	_Serialize(){
		return {Type: this.Type, Code: this.Code, DeviceID: this.DeviceID, UID: this.UID}
	}
	
	_Deserialize(obj){
		for k, v in obj {
			this[k] := v
		}
	}
	
	BuildHumanReadable(){
		if this.Type = 0 {
			code := Format("{:x}", this.Code)
			return GetKeyName("vk" code)
		} else if (this.Type = 1){
			return this.DeviceID "Joy" this.code
		}
	}
}
; ======================================================================== SAMPLE PLUGINS ===============================================================

class TestPlugin1 extends _Plugin {
	static Type := "TestPlugin1"
	Init(){
		Gui, Add, Text,, % "Name: " this.Name ", Type: " this.Type
		;this.AddControl("MyEdit1", this.MyEditChanged.Bind(this, "MyEdit1"), "Edit", "xm w200")
		;this.AddControl("MyEdit2", this.MyEditChanged.Bind(this, "MyEdit2"), "Edit", "xm w200")
		this.AddHotkey("MyHk1", this.MyHkChangedValue.Bind(this, "MyHk1"), this.MyHkChangedState.Bind(this, "MyHk1"), "xm w200")
	}
	
	MyEditChanged(name){
		; All GuiControls are automatically added to this.GuiControls.
		; .value holds the contents of the GuiControl
		ToolTip % Name " changed value to: " this.GuiControls[name].value
	}
	
	MyHkChangedValue(name){
		ToolTip % Name " changed value to: " this.Hotkeys[name].value
	}
	
	MyHkChangedState(Name, e){
		ToolTip % Name " changed state to: " e ? "Down" : "Up"
	}
}

class TestPlugin2 extends _Plugin {
	static Type := "TestPlugin2"
	Init(){
		Gui, Add, Text,, % "Name: " this.Name ", Type: " this.Type
	}
}
