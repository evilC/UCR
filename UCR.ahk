#SingleInstance force
#include <JSON>				; Coco's JSON Lib v2 http://autohotkey.com/boards/viewtopic.php?f=6&t=627
OutputDebug DBGVIEWCLEAR

global UCR
new UCRMain()
return

;~ GuiClose:
	;~ ExitApp

; ======================================================================== MAIN CLASS ===============================================================
Class UCRMain {
	_BindMode := 0
	Profiles := []
	CurrentProfile := 0
	PluginList := []
	PLUGIN_WIDTH := 500
	PLUGIN_FRAME_WIDTH := 540
	TOP_PANEL_HEIGHT := 75
	GUI_MIN_HEIGHT := 300
	__New(){
		global UCR := this
		Gui +HwndHwnd
		this.hwnd := hwnd

		str := A_ScriptName
		if (A_IsCompiled)
			str := StrSplit(str, ".exe")
		else
			str := StrSplit(str, ".ahk")
		this._SettingsFile := A_ScriptDir "\" str.1 ".ini"
		
		this._BindModeHandler := new _BindModeHandler()
		this._HotkeyHandler := new _HotkeyHandler()
		
		this._CreateGui()
		this._LoadSettings()
		this._HotkeyHandler.ChangeHotkeyState(1)
	}
	
	GuiClose(hwnd){
		if (hwnd = this.hwnd)
			ExitApp
	}
	
	_CreateGui(){
		Gui, % this.hwnd ":Margin", 0, 0
		Gui, % this.hwnd ":+Resize"
		Gui % this.hwnd ":Show", % "x0 y0 w" UCR.PLUGIN_FRAME_WIDTH " h" UCR.GUI_MIN_HEIGHT, UCR - Universal Control Remapper
		Gui, % this.hwnd ":+Minsize" UCR.PLUGIN_FRAME_WIDTH "x" UCR.GUI_MIN_HEIGHT
		Gui, % this.hwnd ":+Maxsize" UCR.PLUGIN_FRAME_WIDTH
		Gui, new, HwndHwnd
		this.hTopPanel := hwnd
		Gui % this.hTopPanel ":-Border"
		;Gui % this.hTopPanel ":Show", % "x0 y0 w" UCR.PLUGIN_FRAME_WIDTH " h" UCR.TOP_PANEL_HEIGHT, Main UCR Window
		
		; Profile Select DDL
		Gui, % this.hTopPanel ":Add", Text, xm y+10, Current Profile:
		Gui, % this.hTopPanel ":Add", DDL, % "x100 yp-5 hwndhProfileSelect w300"
		this.hProfileSelect := hProfileSelect
		fn := this._ProfileSelectChanged.Bind(this)
		GuiControl % this.hTopPanel ":+g", % this.hProfileSelect, % fn

		Gui, % this.hTopPanel ":Add", Button, % "hwndhAddProfile x+5 yp", Add
		this.hAddProfile := hAddProfile
		fn := this._AddProfile.Bind(this)
		GuiControl % this.hTopPanel ":+g", % this.hAddProfile, % fn

		Gui, % this.hTopPanel ":Add", Button, % "hwndhDeleteProfile x+5 yp", Delete
		this.hDeleteProfile := hDeleteProfile
		fn := this._DeleteProfile.Bind(this)
		GuiControl % this.hTopPanel ":+g", % this.hDeleteProfile, % fn

		; Add Plugin
		Gui, % this.hTopPanel ":Add", Text, xm y+10, Plugin Selection:
		Gui, % this.hTopPanel ":Add", DDL, % "x100 yp-5 hwndhPluginSelect w300"
		this.hPluginSelect := hPluginSelect

		Gui, % this.hTopPanel ":Add", Button, % "hwndhAddPlugin x+5 yp", Add
		this.hAddPlugin := hAddPlugin
		fn := this._AddPlugin.Bind(this)
		GuiControl % this.hTopPanel ":+g", % this.hAddPlugin, % fn
		
		Gui, % this.hwnd ":Add", Gui, % "w" UCR.PLUGIN_FRAME_WIDTH " h" UCR.TOP_PANEL_HEIGHT, % this.hTopPanel
	}
	
	; Called when hProfileSelect changes through user interaction (They selected a new profile)
	_ProfileSelectChanged(){
		GuiControlGet, name, % this.hTopPanel ":", % this.hProfileSelect
		this._ChangeProfile(name)
	}
	
	; The user clicked the "Add Plugin" button
	_AddPlugin(){
		this.CurrentProfile._AddPlugin()
	}
	
	; We wish to change profile. This may happen due to user input, or application changing
	_ChangeProfile(name, save := 1){
		OutputDebug % "Changing Profile to: " name
		if (IsObject(this.CurrentProfile)){
			;~ if (name = this.CurrentProfile.Name)
				;~ return
			this.CurrentProfile._DeActivate()
		}
		GuiControl, % this.hTopPanel ":ChooseString", % this.hProfileSelect, % name
		this.CurrentProfile := this.Profiles[name]
		this.CurrentProfile._Activate()
		if (save){
			this._ProfileChanged(this.CurrentProfile)
		}
	}
	
	; Populate hProfileSelect with a list of available profiles
	_UpdateProfileSelect(){
		profiles := ["Global", "Default"]
		;profiles := ["Default"]
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
		GuiControl,  % this.hTopPanel ":", % this.hProfileSelect, % str
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
		GuiControl,  % this.hTopPanel ":", % this.hPluginSelect, % str
	}
	
	; User clicked add new profile button
	_AddProfile(){
		name := this._GetUniqueName()
		if (name = 0)
			return
		this.Profiles[name] := new _Profile(name)
		this._UpdateProfileSelect()
		this._ChangeProfile(Name)
		
	}
	
	_GetUniqueName(){
		c := 1
		; Find a unuqe name to suggest as a new name
		while (ObjHasKey(this.Profiles, "Profile " c)){
			c++
		}
		suggestedname := "Profile " c
		; Allow user to pick name
		choosename := 1
		prompt := "Enter a name for the Profile"
		while(choosename) {
			InputBox, name, Add Profile, % prompt, ,,130,,,,, % suggestedname
			if (!ErrorLevel){
				if (ObjHasKey(this.Profiles, Name)){
					prompt := "Duplicate name chosen, please enter a unique name"
					name := suggestedname
				} else {
					return name
				}
			} else {
				return 0
			}
		}
	}
	
	; user clicked the Delete Profile button
	_DeleteProfile(){
		GuiControlGet, name, % this.hTopPanel ":", % this.hProfileSelect
		if (name = "Default" || name = "Global")
			return
		this.Profiles.Delete(name)
		this._UpdateProfileSelect()
		this._ChangeProfile("Default")
	}
	
	; Load a list of available plugins
	_LoadPluginList(){
		; Bodge
		;this.PluginList := ["KeyToKeyPlugin", "TestPlugin1"]
		this.PluginList := []
		Loop, Files, % A_ScriptDir "\Plugins\*.ahk", F
		{
			FileRead,plugincode,% A_LoopFileFullPath
			RegExMatch(plugincode,"i)class\s+(\w+)\s+extends\s+_Plugin",classname)
			this.PluginList.push(classname1)
			AddFile(A_LoopFileFullPath, 1)
			a := TestPlugin1
		}
	}
	
	; Load settings from disk
	_LoadSettings(){
		this._LoadPluginList()
		this._UpdatePluginSelect()
		
		FileRead, j, % this._SettingsFile
		if (j = ""){
			j := {"CurrentProfile":"Default","Profiles":{"Default":{}, "Global": {}}}
			;j := {"CurrentProfile":"Default","Profiles":{"Default":{}}}
		} else {
			OutputDebug % "Loading JSON from disk"
			j := JSON.Load(j)
		}
		this._Deserialize(j)
		
		this._UpdateProfileSelect()
		this._ChangeProfile(this.CurrentProfile.Name, 0)
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
			this.Profiles[name]._Hide()
		}
		this.CurrentProfile := this.Profiles[obj.CurrentProfile]
	}
	
	; A child profile changed in some way - save state to disk
	; ToDo: improve. Only the thing that changed needs to be re-serialized. Cache values.
	_ProfileChanged(profile){
		obj := this._Serialize()
		OutputDebug % "Saving JSON to disk"
		jdata := JSON.Dump(obj, ,true)
		FileDelete, % this._SettingsFile
		FileAppend, % jdata, % this._SettingsFile
		;FileReplace(jdata,this._SettingsFile)
	}
	
	; The user selected the "Bind" option from a Hotkey GuiControl,
	;  or changed an option such as "Wild"
	_RequestBinding(hk, delta := 0){
		if (delta = 0){
			; No delta param passed - request bind mode
			if (!this._BindMode){
				this._BindMode := 1
				this._HotkeyHandler.ChangeHotkeyState(0)
				this._BindModeHandler.StartBindMode(hk, this._BindModeEnded.Bind(this))
				return 1
			}
			return 0
		} else {
			; Change property requested
			; just set the hotkey for now
			bo := hk.value.clone()
			for k, v in delta {
				bo[k] := v
			}
			if (this._HotkeyHandler.IsBindable(hk, bo)){
				hk.value := bo
				this._HotkeyHandler.SetBinding(hk)
				this._HotkeyHandler.ChangeHotkeyState(1, hk)
			}
		}
	}
	
	_BindModeEnded(hk, bo){
		this._BindMode := 0
		if (hk._IsOutput){
			hk.value := bo
		} else {
			if (this._HotkeyHandler.IsBindable(hk, bo)){
				hk.value := bo
				this._HotkeyHandler.SetBinding(hk)
			}
		}
		this._HotkeyHandler.ChangeHotkeyState(1)
	}
}
; =================================================================== HOTKEY HANDLER ==========================================================
Class _HotkeyHandler {
	RegisteredBindings := {}
	__New(){
		
	}
	
	; Set a Binding
	SetBinding(hk){
		if (hk.value.Keys.length()){
			hkstring := this.BuildHotkeyString(hk.value)
			this.RegisteredBindings[hk.hwnd] := {hkstring: hkstring, hk: hk}
		} else {
			;Clear Binding
			this.RegisteredBindings.Delete(hk.hwnd)
		}
		return 1
	}
	
	; Check for duplicates etc
	IsBindable(hk, bo){
		return 1
	}
	
	; Turns on or off Hotkey(s)
	ChangeHotkeyState(state, hk := 0){
		critical
		if (hk = 0){
			; Change State of all hotkeys
			for id, obj in this.RegisteredBindings {
				if (state){
					fn := this.KeyEvent.Bind(this, obj.hk, 1)
					hotkey, % "$" obj.hkstring, % fn, On
					fn := this.KeyEvent.Bind(this, obj.hk, 0)
					hotkey, % "$" obj.hkstring " up", % fn, On
				} else {
					hotkey, % "$" obj.hkstring, Off
					hotkey, % "$" obj.hkstring " up", Off
				}
			}
		} else {
			; Change state of one hotkey (eg toggle wild)
			obj := this.RegisteredBindings[hk.hwnd]
			if (state){
				fn := this.KeyEvent.Bind(this, hk, 1)
				hotkey, % "$" obj.hkstring, % fn, On
				fn := this.KeyEvent.Bind(this, hk, 0)
				hotkey, % "$" obj.hkstring " up", % fn, On
			} else {
				hotkey, % "$" obj.hkstring, Off
				hotkey, % "$" obj.hkstring " up", Off
			}
		}
		critical off
	}
	
	BuildHotkeyString(bo){
		str := ""
		if (bo.Wild)
			str .= "*"
		if (!bo.Block)
			str .= "~"
		max := bo.Keys.Length()
		Loop % max {
			key := bo.Keys[A_Index]
			if (A_Index = max){
				islast := 1
				nextkey := 0
			} else {
				islast := 0
				nextkey := bo.Keys[A_Index+1]
			}
			if (key.IsModifier() && (max > A_Index)){
				str .= key.RenderModifier()
			} else {
				str .= key.BuildHumanReadable()
			}
		}
		return str
	}
	
	KeyEvent(hk, event){
		if (IsObject(hk.ChangeStateCallback)){
			if (hk.__value.Suppress && event && hk.State){
				; Suppress repeats option
				return
			}
			;SoundBeep
			hk.State := event
			hk.ChangeStateCallback.(event)
		}
	}
}

; =================================================================== BIND MODE HANDLER ==========================================================
; Prompts the user for input and detects their choice of binding
class _BindModeHandler {
	DebugMode := 2
	SelectedBinding := 0
	BindMode := 0
	EndKey := 0
	HeldModifiers := {}
	ModifierCount := 0
	_Callback := 0
	
	_Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
	,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
	,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
	,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	__New(hk, callback){
		
	}
	
	StartBindMode(hk, callback){
		this._callback := callback
		this._OriginalHotkey := hk
		
		this.SelectedBinding := 0
		this.BindMode := 1
		this.EndKey := 0
		this.HeldModifiers := {}
		this.ModifierCount := 0

		this.SetHotkeyState(1)
	}
	
	; Turns on or off the hotkeys
	SetHotkeyState(state){
		static pfx := "$*"
		static current_state := 0
		static updown := [{e: 1, s: ""}, {e: 0, s: " up"}]
		critical
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
		critical off
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
			bindObj := this._OriginalHotkey.value.clone()
			
			bindObj.Keys := []
			for code, key in this.HeldModifiers {
				bindObj.Keys.push(key)
			}
			bindObj.Keys.push(this.EndKey)
			this._Callback.(this._OriginalHotkey, bindObj)
			
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
	PluginOrder := []
	AssociatedApss := 0
	
	__New(name){
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
		this.hwnd := hwnd
		try {
			Gui, +Scroll
		}
		Gui, -Caption
		Gui, Add, Edit, % "hwndhSpacer y0 w2 h10 x" UCR.PLUGIN_WIDTH + 10
		this.hSpacer := hSpacer
		Gui, Color, 777777
		Gui, % UCR.hwnd ":Add", Gui, % "x0 y" UCR.TOP_PANEL_HEIGHT " w" UCR.PLUGIN_FRAME_WIDTH " ah h" UCR.GUI_MIN_HEIGHT - UCR.TOP_PANEL_HEIGHT, % this.hwnd
		Gui, % hOld ":Default"	; Restore previous default Gui
	}
	
	; The profile became active
	_Activate(){
		Gui, % this.hwnd ":Show"
	}
	
	; The profile went inactive
	_DeActivate(){
		this._Hide()
	}
	
	; Hide the GUI
	_Hide(){
		Gui, % this.hwnd ":Hide"
	}
	
	; User clicked Add Plugin button
	_AddPlugin(){
		GuiControlGet, plugin, % UCR.hTopPanel ":", % UCR.hPluginSelect
		name := this._GetUniqueName(plugin)
		if (name = 0)
			return
		this.PluginOrder.push(name)
		this.Plugins[name] := new %plugin%(this, name)
		this.Plugins[name].Type := plugin
		this._LayoutPlugin()
		UCR._ProfileChanged(this)
	}
	
	; Layout a plugin.
	; Pass PluginOrder index to lay out, or leave blank to lay out last plugin
	_LayoutPlugin(i := -1){
		static SCROLLINFO:="UINT cbSize;UINT fMask;int  nMin;int  nMax;UINT nPage;int  nPos;int  nTrackPos"
				,scroll:=Struct(SCROLLINFO,{cbSize:sizeof(SCROLLINFO),fMask:4})
		GetScrollInfo(this.hwnd,true,scroll[])
		i := (i = -1 ? this.PluginOrder.length() : i)
		name := this.PluginOrder[i]
		y := 0
		if (i > 1){
			prev := this.PluginOrder[i-1]
			hwnd := this.Plugins[prev].hFrame
			WinGetPos, , , , h, % "ahk_id " hwnd
			y := this.Plugins[prev]._y + h
		}
		y += 5 - scroll.nPos
		Gui, % this.Plugins[name].hFrame ":Show", % "x5 y" y " w" UCR.PLUGIN_WIDTH
		WinGetPos, , , , h, % "ahk_id " this.Plugins[name].hFrame
		this.Plugins[name]._y:= y
		GuiControl, Move, % this.hSpacer, % "h" y + h + scroll.nPos
	}
	
	; Lays out all plugins
	_LayoutPlugins(){
		max := this.PluginOrder.length()
		if (max){
			Loop % max{
				this._LayoutPlugin(A_Index)
			}
		} else {
			GuiControl, Move, % this.hSpacer, % "h10"
		}
	}
	
	; Delete a plugin
	_RemovePlugin(plugin){
		Gui, % plugin.hwnd ":Destroy"
		Gui, % plugin.hFrame ":Destroy"
		Loop % this.PluginOrder.length(){
			if (this.PluginOrder[A_Index] = plugin.name){
				this.PluginOrder.RemoveAt(A_Index)
				break
			}
		}
		this.Plugins.Remove(plugin.name)
		this._PluginChanged(plugin)
		this._LayoutPlugins()
	}
	
	; Obtain a profiel-unique name for the plugin
	_GetUniqueName(name){
		name .= " "
		num := 1
		while (ObjHasKey(this.Plugins, name num)){
			num++
		}
		name := name num
		prompt := "Enter a name for the Plugin"
		Loop {
			InputBox, name, Add Plugin, % prompt, ,,130,,,,, % name
			if (!ErrorLevel){
				if (ObjHasKey(this.Plugins, Name)){
					prompt := "Duplicate name chosen, please enter a unique name"
					name := suggestedname
				} else {
					return name
				}
			} else {
				return 0
			}
		}
	}
	
	; Save the profile to disk
	_Serialize(){
		obj := {}
		obj.Plugins := {}
		for name, plugin in this.Plugins {
			obj.Plugins[name] := plugin._Serialize()
		}
		return obj
	}
	
	; Load the profile from disk
	_Deserialize(obj){
		for name, plugin in obj.Plugins {
			cls := plugin.Type
			this.PluginOrder.push(name)
			this.Plugins[name] := new %cls%(this, name)
			this.Plugins[name]._Deserialize(plugin)
			this._LayoutPlugin()
		}
	}
	
	_PluginChanged(plugin){
		OutputDebug % "Profile " this.Name " --> UCR"
		UCR._ProfileChanged(this)
	}
}

; ======================================================================== PLUGIN ===============================================================
; The _Plugin class itself is never instantiated.
; Instead, plugins derive from the base _Plugin class.
Class _Plugin {
	Type := "_Plugin"			; The class of the plugin
	ParentProfile := 0			; Will point to the parent profile
	Name := ""					; The name the user chose for the plugin
	Hotkeys := {}				; An associative array, indexed by name, of child Hotkeys
	Outputs := {}				; An associative array, indexed by name, of child Outputs
	GuiControls := {}			; An associative array, indexed by name, of child GuiControls
	
	; Override this class in your derived class and put your Gui creation etc in here
	Init(){
		
	}

	__New(parent, name){
		this.ParentProfile := parent
		this.Name := name
		this._CreateGui()
		this.Init()
		this._ParentGuis()
	}
	
	; Initialize the GUI
	; Plugin controls will be added straight afterwards
	_CreateGui(){
		Gui, new, HwndHwnd
		this.hwnd := hwnd
		Gui -Caption
		;Gui, Color, 0000FF
	}
	
	; Add the chrome around the plugin, then add the plugin to the parent
	_ParentGuis(){
		Gui, new, HwndHwnd
		this.hFrame := hwnd
		Gui, Margin, 0, 0
		Gui -Caption
		Gui, Color, 7777FF
		Gui, Add, Button, % "hwndhClose y3 x" UCR.PLUGIN_WIDTH - 23, X
		Gui, Font, s15, Verdana
		Gui, Add, Text, % "hwndhTitle x5 y3 w" UCR.PLUGIN_WIDTH - 40, % this.Name
		this._hTitle := hTitle
		fn := this._Close.Bind(this)
		GuiControl, +g, % hClose, % fn
		Gui, % this.hwnd ":Show", % "w" UCR.PLUGIN_WIDTH
		Gui, % this.hFrame ":Add", Gui, x0 y30, % this.hwnd
		Gui, % this.hFrame ":+Parent" this.ParentProfile.hwnd
	}

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
	
	; An Output is a sequence of keys to be pressed, often in reaction to a hotkey being pressed
	AddOutput(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.Outputs, name)){
			this.Outputs[name] := new _Output(this, name, ChangeValueCallback, aParams*)
			return this.Outputs[name]
		}
	}
	
	; A GuiControl / Hotkey changed
	_ControlChanged(ctrl){
		OutputDebug % "Plugin " this.Name " --> Profile"
		this.ParentProfile._PluginChanged(this)
	}
	
	; Save plugin to disk
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
		for name, ctrl in this.Outputs {
			obj.Outputs[name] := ctrl._Serialize()
		}
		return obj
	}
	
	; Load plugin from disk
	_Deserialize(obj){
		this.Type := obj.Type
		for name, ctrl in obj.GuiControls {
			this.GuiControls[name]._Deserialize(ctrl)
		}
		for name, ctrl in obj.Hotkeys {
			this.Hotkeys[name]._Deserialize(ctrl)
		}
		for name, ctrl in obj.Outputs {
			this.Outputs[name]._Deserialize(ctrl)
		}
		
	}
	
	; The plugin was closed (deleted)
	_Close(){
		this.ParentProfile._RemovePlugin(this)
	}
}

; ======================================================================== GUICONTROL ===============================================================
; Wraps a GuiControl to make it's value persistent between runs.
class _GuiControl {
	__value := ""	; variable that actually holds value. ._value and .__value handled by Setters / Getters
	__New(parent, name, ChangeValueCallback, aParams*){
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueFn := this._ChangedValue.Bind(this)
		this.ChangeValueCallback := ChangeValueCallback
		Gui, % this.ParentPlugin.hwnd ":Add", % aParams[1], % "hwndhwnd " aParams[2], % aParams[3]
		this.hwnd := hwnd
		this._SetGlabel(1)
	}
	
	; Turns on or off the g-label for the GuiControl
	; This is needed to work around not being able to programmatically set GuiControl without triggering g-label
	_SetGlabel(state){
		if (state){
			fn := this.ChangeValueFn
			GuiControl, % this.ParentPlugin.hwnd ":+g", % this.hwnd, % fn
		} else {
			GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		}
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
			OutputDebug % "GuiControl " this.Name " --> Plugin"
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
			this._SetGlabel(0)						; Turn off g-label to avoid triggering save
			GuiControl, , % this.hwnd, % value
			this._SetGlabel(1)						; Turn g-label back on
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
	__value := ""		; Holds the BindObject class
	; Other internal vars
	_IsOutput := 0
	_DefaultBanner := "Drop down the list to select a binding"
	_OptionMap := {Select: 1, Wild: 2, Block: 3, Suppress: 4, Clear: 5}
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		this._Setup(parent, name, ChangeValueCallback, aParams*)
		this.ChangeStateCallback := ChangeStateCallback
	}
	
	_Setup(parent, name, ChangeValueCallback, aParams*){
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		
		Gui, % this.ParentPlugin.hwnd ":Add", % "Combobox", % "hwndhwnd " aParams[1], % aParams[2]
		this.hwnd := hwnd
		
		fn := this._ChangedValue.Bind(this)
		GuiControl, % this.ParentPlugin.hwnd ":+g", % this.hwnd, % fn
		
		; Get Hwnd of EditBox part of ComboBox
		this._hEdit := DllCall("GetWindow","PTR",this.hwnd,"Uint",5) ;GW_CHILD = 5
		
		this.__value := new _BindObject()
		this._SetCueBanner()
	}
	
	value[]{
		get {
			return this.__value
		}
		
		set {
			this._value := value	; trigger _value setter to set value and cuebanner etc
			OutputDebug % "Hotkey " this.Name " --> Plugin"
			this.ParentPlugin._ControlChanged(this)
		}
	}
	
	_value[]{
		get {
			return this.__value
		}
		
		; Parent class told this hotkey what it's value is. Set value, but do not fire ParentPlugin._ControlChanged
		set {
			this.__value := value
			this._SetCueBanner()
		}
	}

	; Builds the list of options in the DropDownList
	_BuildOptions(){
		this._CurrentOptionMap := [this._OptionMap["Select"]]
		str := "|Select New Binding"
		if (this.__value.Type = 0){
			; Joystick buttons do not have these options
			str .= "|Wild: " (this.__value.wild ? "On" : "Off") 
			this._CurrentOptionMap.push(this._OptionMap["Wild"])
			str .= "|Block: " (this.__value.block ? "On" : "Off")
			this._CurrentOptionMap.push(this._OptionMap["Block"])
			str .= "|Suppress Repeats: " (this.__value.suppress ? "On" : "Off")
			this._CurrentOptionMap.push(this._OptionMap["Suppress"])
		}
		str .= "|Clear Binding"
		this._CurrentOptionMap.push(this._OptionMap["Clear"])
		GuiControl, , % this.hwnd, % str
	}

	; Sets the "Cue Banner" for the ComboBox
	_SetCueBanner(){
		this._BuildOptions()
		static EM_SETCUEBANNER:=0x1501
		if (this.__value.Keys.length()) {
			;Text := this._BuildHumanReadable()
			Text := this.__value.BuildHumanReadable()
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
				; Bind
				UCR._RequestBinding(this)
				return
			} else if (o = 2){
				; Wild
				mod := {wild: !this.__value.wild}
			} else if (o = 3){
				; Block
				mod := {block: !this.__value.block}
			} else if (o = 4){
				; Suppress
				mod := {suppress: !this.__value.suppress}
			} else if (o = 5){
				; Clear Binding
				mod := {Keys: []}
			} else {
				; not one of the options from the list, user must have typed in box
				return
			}
			if (IsObject(mod)){
				UCR._RequestBinding(this, mod)
				return
			}
		}
	}
	
	_Serialize(){
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Trigger _value setter to set gui state but not fire change event
		this._value := new _BindObject(obj)
		; Register hotkey on load
		UCR._HotkeyHandler.SetBinding(this)
	}
}

; ======================================================================== OUTPUT ===============================================================
Class _Output extends _Hotkey {
	_DefaultBanner := "Drop down the list to select an Output"
	_IsOutput := 1
	__New(parent, name, ChangeValueCallback, aParams*){
		this._Setup(parent, name, ChangeValueCallback, aParams*)
		;obj := this.base.__New(parent, name, ChangeValueCallback, ChangeValueCallback, aParams*)
		;return obj
	}
	
	SetState(state){
		max := this.__value.keys.Length()
		if (state)
			i := 1
		else
			i := max
		Loop % max{
			key := this.__value.keys[i]
			name := key.BuildHumanReadable()
			Send % "{" name (state ? " Down" : " Up") "}"
			if (state)
				i++
			else
				i--
		}
	}
}

; ======================================================================== BINDOBJECT ===============================================================
class _BindObject {
	Type := 0
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
	
	RenderModifier(){
		return this._Modifiers[this.Code].s
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

GuiClose(hwnd){
	UCR.GuiClose(hwnd)
}
