#SingleInstance force
/*
Dependencies: 
Autohotkey_H v1 http://hotkeyit.github.io/v2/
UCR WILL NOT RUN USING VANILLA AUTOHOTKEY ("AHK_L")

JSON serialization (for dumping settings to disk) by CoCo's JSON Lib
For now, use my fork (Very minor tweak to fix AHK_H compatibility): https://github.com/evilC/AutoHotkey-JSON/
Coco's JSON Lib - http://autohotkey.com/boards/viewtopic.php?f=6&t=627
*/
#include Libraries\JSON.ahk
OutputDebug DBGVIEWCLEAR

global UCR
new UCRMain()
return

; ======================================================================== MAIN CLASS ===============================================================
Class UCRMain {
	_BindMode := 0
	Profiles := []
	Libraries := {}
	CurrentProfile := 0
	PluginList := []
	PLUGIN_WIDTH := 680
	PLUGIN_FRAME_WIDTH := 720
	TOP_PANEL_HEIGHT := 75
	GUI_MIN_HEIGHT := 300
	CurrentSize := {w: this.PLUGIN_FRAME_WIDTH, h: this.GUI_MIN_HEIGHT}
	CurrentPos := {x: "", y: ""}
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
		
		; Provide a common repository of libraries for plugins (vJoy, HID libs etc)
		this._LoadLibraries()
		
		; Start the input detection system
		this._BindModeHandler := new _BindModeHandler()
		this._InputHandler := new _InputHandler()

		; Create the Main Gui
		this._CreateGui()
		
		; Watch window position and size using MessageFilter thread
		this._MessageFilterThread := AhkThread(A_ScriptDir "\Threads\MessageFilterThread.ahk",,1)
		While !this._MessageFilterThread.ahkgetvar.autoexecute_done
			Sleep 50 ; wait until variable has been set.
		fn := this._OnSize.Bind(this)
		this._OnSizeCallback := fn	; make sure boundfunc does not go out of scope - the other thread needs it
		matchobj := {msg: 0x5, hwnd: this.hwnd}
		filterobj := {hwnd: this.hwnd}
		this._MessageFilterThread.ahkExec["new MessageFilter(" &fn "," &matchobj "," &filterobj ")"]
		matchobj.msg := 0x3
		fn := this._OnMove.Bind(this)
		this._OnMoveCallback := fn
		this._MessageFilterThread.ahkExec["new MessageFilter(" &fn "," &matchobj "," &filterobj ")"]
		
		; Load settings. This will cause all plugins to load.
		this._LoadSettings()

		; Now we have settings from disk, move the window to it's last position and size
		this._ShowGui()
	}
	
	GuiClose(hwnd){
		if (hwnd = this.hwnd)
			ExitApp
	}
	
	_LoadLibraries(){
		Loop, Files, % A_ScriptDir "\Libraries\*.*", D
		{
			str := A_LoopFileName
			AddFile(A_ScriptDir "\Libraries\" A_LoopFileName "\" A_LoopFileName ".ahk", 1)
			lib := new %A_LoopFileName%()
			res := lib._UCR_LoadLibrary()
			if (res == 1)
				this.Libraries[A_LoopFileName] := lib
			;~ FileRead,plugincode,% A_LoopFileFullPath
			;~ RegExMatch(plugincode,"i)class\s+(\w+)\s+extends\s+_Plugin",classname)
			;~ this.PluginList.push(classname1)
			;~ AddFile(A_LoopFileFullPath, 1)
		}
	}
	
	_CreateGui(){
		Gui, % this.hwnd ":Margin", 0, 0
		Gui, % this.hwnd ":+Resize"
		Gui, % this.hwnd ":Show", % "Hide w" UCR.PLUGIN_FRAME_WIDTH " h" UCR.GUI_MIN_HEIGHT, UCR - Universal Control Remapper
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

		;Gui, % this.hwnd ":Show"
	}
	
	_ShowGui(){
		xy := (this.CurrentPos.x != "" && this.CurrentPos.y != "" ? "x" this.CurrentPos.x " y" this.CurrentPos.y : "")
		Gui, % this.hwnd ":Show", % xy " h" this.CurrentSize.h
	}
	
	_OnMove(wParam, lParam, msg, hwnd){
		;this.CurrentPos := {x: LoWord(lParam), y: HiWord(lParam)}
		; Use WinGetPos rather than pos in message, as this is the top left of the Gui, not the client rect
		WinGetPos, x, y, , , % "ahk_id " this.hwnd
		if (x != "" && y != ""){
			this.CurrentPos := {x: x, y: y}
			this._SaveSettings()
		}
	}
	
	_OnSize(wParam, lParam, msg, hwnd){
		this.CurrentSize.h := HiWord(lParam)
		this._SaveSettings()
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
			this.CurrentProfile._Hide()
			if (!this.CurrentProfile._IsGlobal)
				this.CurrentProfile._DeActivate()
		}
		GuiControl, % this.hTopPanel ":ChooseString", % this.hProfileSelect, % name
		this.CurrentProfile := this.Profiles[name]
		this.CurrentProfile._Activate()
		this.CurrentProfile._Show()
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
		this.PluginList := []
		Loop, Files, % A_ScriptDir "\Plugins\*.ahk", F
		{
			FileRead,plugincode,% A_LoopFileFullPath
			RegExMatch(plugincode,"i)class\s+(\w+)\s+extends\s+_Plugin",classname)
			this.PluginList.push(classname1)
			; Check if the classname already exists.
			if (IsObject(%classname1%)){
				cls := %classname1%
				if (cls.base.__Class = "_Plugin"){
					; Existing class extends plugin
					; Class has been included via other means (eg to debug it), so do not try to include again.
					continue
				}
			}
			AddFile(A_LoopFileFullPath, 1)
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
		this.Profiles.Global._Activate()
		this._ChangeProfile(this.CurrentProfile.Name, 0)
	}
	
	; Save settings to disk
	; ToDo: improve. Only the thing that changed needs to be re-serialized. Cache values.
	_SaveSettings(){
		obj := this._Serialize()
		OutputDebug % "Saving JSON to disk"
		jdata := JSON.Dump(obj, ,true)
		FileDelete, % this._SettingsFile
		FileAppend, % jdata, % this._SettingsFile
	}
	
	; A child profile changed in some way
	_ProfileChanged(profile){
		this._SaveSettings()
	}
	
	; The user selected the "Bind" option from an Input/OutputButton GuiControl,
	;  or changed an option such as "Wild" in an InputButton
	_RequestBinding(hk, delta := 0){
		if (delta = 0){
			; Change Buttons requested - start Bind Mode.
			if (!this._BindMode){
				this._BindMode := 1
				this.Profiles.Global._SetHotkeyState(0)
				hk.ParentPlugin.ParentProfile._SetHotkeyState(0)
				this._BindModeHandler.StartBindMode(hk, this._BindModeEnded.Bind(this))
				return 1
			}
			return 0
		} else {
			; Change option (eg wild, passthrough) requested
			bo := hk.value.clone()
			for k, v in delta {
				bo[k] := v
			}
			if (this._InputHandler.IsBindable(hk, bo)){
				hk.value := bo
				this._InputHandler.SetButtonBinding(hk)
			}
			hk.ParentPlugin.ParentProfile._SetHotkeyState(1)
			this.Profiles.Global._SetHotkeyState(1)
		}
	}
	
	; Bind Mode Ended.
	; Decide whether or not binding is valid, and if so set binding and re-enable inputs
	_BindModeEnded(hk, bo){
		OutputDebug % "Bind Mode Ended: " bo.Buttons[1].code
		this._BindMode := 0
		if (hk._IsOutput){
			hk.value := bo
		} else {
			if (this._InputHandler.IsBindable(hk, bo)){
				hk.value := bo
				this._InputHandler.SetButtonBinding(hk)
			}
		}
		this.Profiles.Global._SetHotkeyState(1)
		hk.ParentPlugin.ParentProfile._SetHotkeyState(1)
	}
	
	; Request an axis binding.
	RequestAxisBinding(axis){
		this._InputHandler.SetAxisBinding(axis)
	}
	
	; Serialize this object down to the bare essentials for loading it's state
	_Serialize(){
		obj := {CurrentProfile: this.CurrentProfile.Name, CurrentSize: this.CurrentSize, CurrentPos: this.CurrentPos}
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
		if (IsObject(obj.CurrentSize))
			this.CurrentSize := obj.CurrentSize
		if (IsObject(obj.CurrentPos))
			this.CurrentPos := obj.CurrentPos
	}

}
; =================================================================== INPUT HANDLER ==========================================================
; Manages input (ie keyboard, mouse, joystick) during "normal" operation (ie when not in Bind Mode)
; Holds the "master list" of bound inputs and decides whether or not to allow bindings.
; All actual detection of input is handled in separate threads.
; Each profile has it's own thread of bindings which this class can turn on/off or add/remove bindings.
Class _InputHandler {
	RegisteredBindings := {}
	__New(){
		
	}
	
	; Set a Button Binding
	SetButtonBinding(BtnObj){
		; ToDo: Move building of bindstring inside thread? BuildHotkeyString is AHK input-specific, what about XINPUT?
		bindstring := this.BuildHotkeyString(BtnObj.value)
		; Set binding in Profile's InputThread
		BtnObj.ParentPlugin.ParentProfile._InputThread.ahkExec("InputThread.SetButtonBinding(" &BtnObj ",""" bindstring """)")
		return 1
	}
	
	; Set an Axis Binding
	SetAxisBinding(AxisObj){
		AxisObj.ParentPlugin.ParentProfile._InputThread.ahkExec("InputThread.SetAxisBinding(" &AxisObj ")")
	}
	
	; Check InputButtons for duplicates etc
	IsBindable(hk, bo){
		; Do not allow bind of LMB with block enabled
		if (bo.Block && bo.Buttons.length() = 1 && bo.Buttons[1].Type = 1 && bo.Buttons[1].code == 1){
			; ToDo: provide proper notification
			SoundBeep
			return 0
		}
		; ToDo: Implement duplicate check
		return 1
	}
	
	; Turns on or off Hotkey(s)
	ChangeHotkeyState(state, hk := 0){
		hk.ParentPlugin.ParentProfile._InputThread.ahkExec("InputThread.SetHotkeyState(" state ")")
	}
	
	; Builds an AHK hotkey string (eg ~^a) from a BindObject
	BuildHotkeyString(bo){
		if (!bo.Buttons.Length())
			return ""
		str := ""
		if (bo.Type = 1){
			if (bo.Wild)
				str .= "*"
			if (!bo.Block)
				str .= "~"
		}
		max := bo.Buttons.Length()
		Loop % max {
			key := bo.Buttons[A_Index]
			if (A_Index = max){
				islast := 1
				nextkey := 0
			} else {
				islast := 0
				nextkey := bo.Buttons[A_Index+1]
			}
			if (key.IsModifier() && (max > A_Index)){
				str .= key.RenderModifier()
			} else {
				str .= key.BuildKeyName()
			}
		}
		return str
	}
	
	; An input event (eg key, mouse, joystick) occured for a bound input
	; This will have come from another thread
	; ipt will be an object of class _InputButton or _InputAxis
	; event will be 0 or 1 for a Button type, or the value of the axis for an axis type
	InputEvent(ipt, state){
		ipt := Object(ipt)	; Resolve input object back from pointer
		ipt.State := state
		if (IsObject(ipt.ChangeStateCallback)){
			; ToDo: don't do this check for axes
			if (ipt.__value.Suppress && state && ipt.State){
				; Suppress repeats option
				return
			}
			ipt.ChangeStateCallback.Call(state)
			; POC for QuickBind replacement - delay all inputs
			;fn := this._DelayCallback.Bind(this, ipt.ChangeStateCallback, state)
			;SetTimer, % fn, -1000
		}
	}
	
	_DelayCallback(cb, state){
		cb.Call(state)
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

	__New(){
		this._BindModeThread:=AhkThread(A_ScriptDir "\Threads\BindModeThread.ahk",,1) ; Loads the AutoHotkey module and starts the script.
		While !this._BindModeThread.ahkgetvar.autoexecute_done
			Sleep 50 ; wait until variable has been set.
		fn := this._ProcessInput.Bind(this)
		this._BindModeCallback := fn	; make sure boundfunc does not go out of scope - the other thread needs it
		this._BindModeThread.ahkExec["BindMapper := new _BindMapper(" &fn ")"]
	}
	
	StartBindMode(hk, callback){
		this._callback := callback
		this._OriginalHotkey := hk
		
		this.SelectedBinding := 0
		this.BindMode := 1
		this.EndKey := 0
		this.HeldModifiers := {}
		this.ModifierCount := 0
		
		; When detecting an output, tell the Bind Handler to ignore physical joysticks...
		; ... as output cannot be "sent" to physical sticks
		this.SetHotkeyState(1, !hk._IsOutput)
	}
	
	; Turns on or off the hotkeys
	SetHotkeyState(state, enablejoystick := 1){
		if (state){
			SplashTextOn, 300, 30, Bind  Mode, Press a key combination to bind
		} else {
			SplashTextOff
		}
		this._BindModeThread.ahkExec["BindMapper.SetHotkeyState(" state "," enablejoystick ")"]
	}
	
	; The BindModeThread calls back here
	_ProcessInput(e, type, code, deviceid){
		;OutputDebug % "e: " e ", type: " type ", code: " code ", deviceid: " deviceid
		; Build Key object and pass to ProcessInput
		i := new _Button({type: type, code: code, deviceid: deviceid})
		this.ProcessInput(i,e)
	}
	
	; Called when a key was pressed
	ProcessInput(i, e){
		if (!this.BindMode)
			return
		if (i.type > 1){
			is_modifier := 0
		} else {
			is_modifier := i.IsModifier()
			; filter repeats
			;if (e && (is_modifier ? ObjHasKey(HeldModifiers, i.code) : EndKey) )
			if (e && (is_modifier ? ObjHasKey(this.HeldModifiers, i.code) : i.code = this.EndKey.code) )
				return
		}

		;~ ; Are the conditions met for end of Bind Mode? (Up event of non-modifier key)
		;~ if ((is_modifier ? (!e && ModifierCount = 1) : !e) && (i.type > 1 ? !ModifierCount : 1) ) {
		; Are the conditions met for end of Bind Mode? (Up event of any key)
		if (!e){
			; End Bind Mode
			this.BindMode := 0
			this.SetHotkeyState(0)
			bindObj := this._OriginalHotkey.value.clone()
			
			bindObj.Buttons := []
			for code, key in this.HeldModifiers {
				bindObj.Buttons.push(key)
			}
			
			bindObj.Buttons.push(this.EndKey)
			bindObj.Type := this.EndKey.Type
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
				if (i.type > 1 && this.ModifierCount){
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
	_IsGlobal := 0
	
	__New(name){
		this.Name := name
		if (this.Name = "global"){
			this._IsGlobal := 1
		}
		this._InputThread := AhkThread(A_ScriptDir "\Threads\ProfileInputThread.ahk",,1) ; Loads the AutoHotkey module and starts the script.
		While !this._InputThread.ahkgetvar.autoexecute_done
			Sleep 50 ; wait until variable has been set.
		fn := UCR._InputHandler.InputEvent.Bind(UCR._InputHandler)
		this._InputEventCallback := fn	; ensure BoundFunc does not go out of scope
		this._InputThread.ahkExec("InputThread := new _InputThread(" &fn ")")
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
		Gui, Add, Edit, % "+Hidden hwndhSpacer y0 w2 h10 x" UCR.PLUGIN_WIDTH + 10
		this.hSpacer := hSpacer
		Gui, Color, 777777
		Gui, % UCR.hwnd ":Add", Gui, % "x0 y" UCR.TOP_PANEL_HEIGHT " w" UCR.PLUGIN_FRAME_WIDTH " ah h" UCR.GUI_MIN_HEIGHT - UCR.TOP_PANEL_HEIGHT, % this.hwnd
		Gui, % hOld ":Default"	; Restore previous default Gui
	}
	
	; The profile became active
	_Activate(){
		this._SetHotkeyState(1)
	}
	
	; The profile went inactive
	_DeActivate(){
		this._SetHotkeyState(0)
	}
	
	_SetHotkeyState(state){
		this._InputThread.ahkExec("InputThread.SetHotkeyState(" state ")")
	}
	
	; Show the GUI
	_Show(){
		Gui, % this.hwnd ":Show"
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
		this.Plugins.Delete(plugin.name)
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
		obj.PluginOrder := this.PluginOrder
		for name, plugin in this.Plugins {
			obj.Plugins[name] := plugin._Serialize()
		}
		return obj
	}
	
	; Load the profile from disk
	_Deserialize(obj){
		Loop % obj.PluginOrder.length() {
			name := obj.PluginOrder[A_Index]
			this.PluginOrder.push(name)
			plugin := obj.Plugins[name]
			cls := plugin.Type
			if (!IsObject(%cls%)){
				msgbox % "Plugin class " cls " not found - removing"
				this.PluginOrder.Pop()
				obj.Plugins.Delete(name)
				continue
			}
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
	GuiControls := {}			; An associative array, indexed by name, of child GuiControls
	InputButtons := {}			; An associative array, indexed by name, of child Input Buttons (aka Hotkeys)
	OutputButtons := {}			; An associative array, indexed by name, of child Output Buttons
	InputAxes := {}				; An associative array, indexed by name, of child Input Axes
	OutputAxes := {}			; An associative array, indexed by name, of child Output (virtual) Axes
	_SerializeList := ["GuiControls", "InputButtons", "OutputButtons", "InputAxes", "OutputAxes"]
	
	; Override this class in your derived class and put your Gui creation etc in here
	Init(){
		
	}

	; === Plugins can call these commands to add various GuiControls to their Gui ===
	; Adds a GuiControl that allows the end-user to choose a value, often used to configure the script
	AddControl(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.GuiControls, name)){
			this.GuiControls[name] := new _GuiControl(this, name, ChangeValueCallback, aParams*)
			return this.GuiControls[name]
		}
	}
	
	; Adds a GuiControl that allows the end-user to pick Button(s) to use as Input(s)
	AddInputButton(name, ChangeValueCallback, ChangeStateCallback, aParams*){
		if (!ObjHasKey(this.InputButtons, name)){
			this.InputButtons[name] := new _InputButton(this, name, ChangeValueCallback, ChangeStateCallback, aParams*)
			return this.InputButtons[name]
		}
	}
	
	; Adds a GuiControl that allows the end-user to pick an Axis to be used as an input
	AddInputAxis(name, ChangeValueCallback, ChangeStateCallback, aParams*){
		if (!ObjHasKey(this.InputAxes,name)){
			this.InputAxes[name] := new _InputAxis(this, name, ChangeValueCallback, ChangeStateCallback, aParams*)
			return this.InputAxes[name]
		}
	}
	
	; Adds a GuiControl that allows the end-user to pick Button(s) to be used as output(s)
	AddOutputButton(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.OutputButtons, name)){
			this.OutputButtons[name] := new _OutputButton(this, name, ChangeValueCallback, aParams*)
			return this.OutputButtons[name]
		}
	}

	; Adds a GuiControl that allows the end-user to pick an Axis to be used as an output
	AddOutputAxis(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.OutputAxes,name)){
			this.OutputAxes[name] := new _OutputAxis(this, name, ChangeValueCallback, aParams*)
			return this.OutputAxes[name]
		}
	}
	
	; === Private ===
	__New(parent, name){
		this.ParentProfile := parent
		this.Name := name
		this._CreateGui()
		this.Init()
		this._ParentGuis()
	}
	
	__Delete(){
		OutputDebug % "Plugin " this.name " in profile " this.ParentProfile.name " fired destructor"
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

	; A GuiControl / Hotkey changed
	_ControlChanged(ctrl){
		OutputDebug % "Plugin " this.Name " --> Profile"
		this.ParentProfile._PluginChanged(this)
	}
	
	; Save plugin to disk
	_Serialize(){
		obj := {Type: this.Type}
		Loop % this._SerializeList.length(){
			key := this._SerializeList[A_Index]
			obj[key] := {}
			for name, ctrl in this[key] {
				obj[key, name] := ctrl._Serialize()
			}
		}
		return obj
	}
	
	; Load plugin from disk
	_Deserialize(obj){
		this.Type := obj.Type
		Loop % this._SerializeList.length(){
			key := this._SerializeList[A_Index]
			for name, ctrl in obj[key] {
				this[key, name]._Deserialize(ctrl)
			}
		}
	}
	
	; The plugin was closed (deleted)
	_Close(){
		; Free resources so destructors fire
		for name, obj in this.InputButtons {
			this.ParentProfile._InputThread.ahkExec("InputThread.SetButtonBinding(" &obj ")")
			obj._KillReferences()
		}
		for name, obj in this.OutputButtons {
			obj._KillReferences()
		}
		for name, obj in this.GuiControls {
			obj._KillReferences()
		}
		this.ParentProfile._RemovePlugin(this)
		try {
			this._KillReferences()
		}
		this.InputButtons := this.OutputButtons := this.GuiControls := ""
	}
}

; ======================================================================== GUICONTROL ===============================================================
; Wraps a GuiControl to make it's value persistent between runs.
class _GuiControl {
	__value := ""	; variable that actually holds value. ._value and .__value handled by Setters / Getters
	__New(parent, name, ChangeValueCallback, aParams*){
		this.ParentPlugin := parent
		this.Name := name
		this.ControlType := aParams[1]
		; Detect what kind of GuiControl this is, so that later operations (eg set of value) work as intended.
		; Decide whether the control type is a "List" type: ListBox, DropDownList (ddl), ComboBox, and Tab (and tab2?)
		if (aParams[1] = "listbox" ||aParams[1] = "ddl" || aParams[1] = "dropdownlist" || aParams[1] = "combobox" || aParams[1] = "tab" || aParams[1] = "tab2"){
			this.IsListType := 1
			; Detect if this List Type uses AltSubmit
			if (InStr(aParams[2], "altsubmit"))
				this.IsAltSubmitType := 1
			else 
				this.IsAltSubmitType := 0
		} else {
			this.IsListType := 0
			this.IsAltSubmitType := 0
		}
		; Set which (internal) function gets called when the control changes value 
		this.ChangeValueFn := this._ChangedValue.Bind(this)
		; Store the user's callback that is to be fired when the Control changes value
		this.ChangeValueCallback := ChangeValueCallback
		; Add the Control
		Gui, % this.ParentPlugin.hwnd ":Add", % aParams[1], % "hwndhwnd " aParams[2], % aParams[3]
		this.hwnd := hwnd
		; Set default value - get this from state of GuiControl before any loading of settings is done
		GuiControlGet, value, % this.ParentPlugin.hwnd ":", % this.hwnd
		this.__value := value
		; Turn on the gLabel
		this._SetGlabel(1)
	}
	
	__Delete(){
		OutputDebug % "GuiControl " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	_KillReferences(){
		this._SetGlabel(0)
		this.ChangeValueFn := ""
		this.ChangeValueCallback := ""
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
			cmd := ""
			if (this.IsListType){
				cmd := (this.IsAltSubmitType ? "choose" : "choosestring")
			}
			GuiControl, % cmd, % this.hwnd, % value
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
		obj := {value: this._value}
		return obj
	}
	
	_Deserialize(obj){
		this._value := obj.value
	}
}

; ======================================================================== BANNER COMBO ===============================================================
; Wraps a ComboBox GuiControl to turn it into a DDL with a "Cue Banner" 1st item, that is re-selected after every choice.
class _BannerCombo {
	__New(ParentHwnd, aParams*){
		this._ParentHwnd := ParentHwnd
		Gui, % this._ParentHwnd ":Add", % "Combobox", % "hwndhwnd " aParams[1], % aParams[2]
		this.hwnd := hwnd
		
		fn := this.__ChangedValue.Bind(this)
		GuiControl, % this._ParentHwnd ":+g", % this.hwnd, % fn
		
		; Get Hwnd of EditBox part of ComboBox
		this._hEdit := DllCall("GetWindow","PTR",this.hwnd,"Uint",5) ;GW_CHILD = 5
		
		; == Hack to stop Mouse Wheel changing option when the control is focused.
		; ToDo: Find better solution (Probably involves changing AHK_H source code)
		; In a scrolling environment, this is really annoying.
		; Not the best solution, as if you scroll while the list is open, the list doesn't move.
		; Get the position of the Editbox
		ControlGetPos,x,y,,,,% "ahk_id " this._hEdit
		; Set the parent of the editbox to the main Gui instead of the Combobox
		DllCall("SetParent","PTR",this._hEdit,"PTR",this._ParentHwnd)
		; Move the Editbox back to where it should be
		ControlMove,,% x,% y,,,% "ahk_id " this._hEdit
		; == End Hack
	}
	
	; Pass an array of strings to set available options
	SetOptions(opts){
		str := "|", max := opts.length()
		Loop % max{
			str .= opts[A_Index]
			if (A_Index != max){
				str .= "|"
			}
		}
		GuiControl,% this._ParentHwnd ":" , % this.hwnd, % str
	}
	
	; Sets the text of the Cue Banner
	SetCueBanner(text){
		static EM_SETCUEBANNER:=0x1501
		DllCall("User32.dll\SendMessageW", "Ptr", this._hEdit, "Uint", EM_SETCUEBANNER, "Ptr", True, "WStr", text)
	}
	
	; The control changed through user interaction
	__ChangedValue(){
		; Find index of dropdown list. Will be really big number if text was typed into the Editbox
		SendMessage 0x147, 0, 0,, % "ahk_id " this.hwnd  ; CB_GETCURSEL
		o := ErrorLevel
		; Reset DDL to position 0 (The "Cue Banner")
		GuiControl, % this._ParentHwnd ":Choose", % this.hwnd, 0
		; Filter typed text
		if (o < 100){
			o++
			this._ChangedValue(o)
		}
	}
	
	; Override
	_ChangedValue(o){
		
	}
}

; ======================================================================== INPUT BUTTON ===============================================================
; A class the script author can instantiate to allow the user to select a hotkey.
class _InputButton extends _BannerCombo {
	; Public vars
	State := -1			; State of the input. -1 is unset. GET ONLY
	; Internal vars describing the bindstring
	__value := ""		; Holds the BindObject class
	; Other internal vars
	_IsOutput := 0
	_DefaultBanner := "Drop down the list to select a binding"
	_OptionMap := {Select: 1, Wild: 2, Block: 3, Suppress: 4, Clear: 5}
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
		this.__value := new _BindObject()
		this.SetComboState()
	}
	
	__Delete(){
		OutputDebug % "Hotkey " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		this.ChangeValueCallback := ""
		this.ChangeStateCallback := ""
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
			this.SetComboState()
		}
	}

	; Builds the list of options in the DropDownList
	_BuildOptions(){
		opts := []
		this._CurrentOptionMap := [this._OptionMap["Select"]]
		opts.push("Select New Binding")
		if (this.__value.Type = 1){
			; Joystick buttons do not have these options
			opts.push("Wild: " (this.__value.wild ? "On" : "Off"))
			this._CurrentOptionMap.push(this._OptionMap["Wild"])
			opts.push("Block: " (this.__value.block ? "On" : "Off"))
			this._CurrentOptionMap.push(this._OptionMap["Block"])
			opts.push("Suppress Repeats: " (this.__value.suppress ? "On" : "Off"))
			this._CurrentOptionMap.push(this._OptionMap["Suppress"])
		}
		opts.push("Clear Binding")
		this._CurrentOptionMap.push(this._OptionMap["Clear"])
		this.SetOptions(opts)
	}

	; Set the state of the GuiControl (Inc Cue Banner)
	SetComboState(){
		this._BuildOptions()
		if (this.__value.Buttons.length()) {
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner			
		}
		this.SetCueBanner(Text)
	}
	
	; An option was selected from the list
	_ChangedValue(o){
		if (o){
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
				mod := {Buttons: []}
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
		UCR._InputHandler.SetButtonBinding(this)
	}
}
; ======================================================================== INPUT AXIS ===============================================================
class _InputAxis extends _BannerCombo {
	AHKAxisList := ["X","Y","Z","R","U","V"]
	__value := new _Axis()
	_OptionMap := []
	
	State := -1
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
		this._Options := []
		Loop 6 {
			this._Options.push("Axis " A_Index " (" this.AHKAxisList[A_Index] ")" )
		}
		Loop 8 {
			this._Options.push("Stick " A_Index )
		}
		this._Options.push("Clear Binding")
		this.SetComboState()
	}
	
	; The Axis Select DDL changed value
	_ChangedValue(o){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		
		; Resolve result of selection to index of full option list
		o := this._OptionMap[o]
		
		if (o <= 6){
			; Axis Selected
			axis := o
		} else if (o <= 14){
			; Stick Selected
			o -= 6
			DeviceID := o
		} else {
			; Clear Selected
			axis := DeviceID := 0
		}
		this.__value.Axis := axis
		this.__value.DeviceID := DeviceID
		this.SetComboState()
		this.value := this.__value
		UCR.RequestAxisBinding(this)
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetComboState(){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		this._OptionMap := []
		opts := []
		if (DeviceID){
			; Show Sticks and Axes
			max := 14
			index_offset := 0
		} else {
			str := "Pick a Stick"
			max := 8
			index_offset := 6
		}
		Loop % max {
			map_index := A_Index + index_offset
			if ((map_index > 6 && map_index <= 14))
				joyinfo := GetKeyState( map_index - 6 "JoyInfo")
			else
				joyinfo := 0
			if ((map_index > 6 && map_index <= 14) && !JoyInfo)
				continue
			opts.push(this._Options[map_index])
			this._OptionMap.push(map_index)
		}
		if (DeviceID || axis){
			opts.push(this._Options[15])
			this._OptionMap.push(15)
		}

		if (DeviceID)
			str := "Stick: " (DeviceID ? DeviceID : "None") ", Axis: " (axis ? axis : "None") (DeviceID && axis ? " (" this.AHKAxisList[axis] ")" : "")

		this.SetOptions(opts)
		this.SetCueBanner(str)
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
			this._value := value
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
			this.SetComboState()
			if (IsObject(this.ChangeValueCallback)){
				this.ChangeValueCallback.Call(this.__value)
			}
		}
	}

	_Serialize(){
		obj := {value: this._value}
		return obj
	}
	
	_Deserialize(obj){
		this._value := obj.value
		UCR.RequestAxisBinding(this)
	}
}

; ======================================================================== OUTPUT BUTTON ===============================================================
; An Output allows the end user to specify which buttons to press as part of a plugin's functionality
Class _OutputButton extends _InputButton {
	_DefaultBanner := "Drop down the list to select an Output"
	_IsOutput := 1
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
		this._OptionMap := {Select: 1, vJoyButton: 2, Clear: 3}
		; Create Select vJoy Button / Hat Select GUI
		Gui, new, HwndHwnd
		Gui -Border
		this.hVjoySelect := hwnd
		Gui, Add, Text, w50 xm Center, Stick
		Gui, Add, Text, w50 xp+55 Center, Button
		Gui, Add, Text, w50 xp+55 Center, Hat
		Gui, Add, ListBox, R11 xm w50 AltSubmit HwndHwnd , None||1|2|3|4|5|6|7|8
		this.hVjoyDevice := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "dev")
		GuiControl +g, % hwnd, % fn
		Gui, Add, ListBox, R11 w50 xp+55 AltSubmit HwndHwnd , None||01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|39|40|41|42|43|44|45|46|47|48|49|50|51|52|53|54|55|56|57|58|59|60|61|62|63|64|65|66|67|68|69|70|71|72|73|74|75|76|77|78|79|80|81|82|83|84|85|86|87|88|89|90|91|92|93|94|95|96|97|98|99|100|101|102|103|104|105|106|107|108|109|110|111|112|113|114|115|116|117|118|119|120|121|122|123|124|125|126|127|128|
		this.hVJoyButton := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "but")
		GuiControl +g, % hwnd, % fn
		Gui, Add, ListBox, R5 w50 xp+55 AltSubmit HwndHwnd , None||Hat 1|Hat 2|Hat 3|Hat 4
		this.hVJoyHatNumber := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "hn")
		GuiControl +g, % hwnd, % fn
		Gui, Add, ListBox, R5 w50 xp y+9 AltSubmit HwndHwnd , None||Up|Right|Down|Left
		this.hVJoyHatDir := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "hd")
		GuiControl +g, % hwnd, % fn
		Gui, Add, Button, xm w75 Center HwndHwnd, Cancel
		this.hVJoyCancel := hwnd
		fn := this.vJoyInputCancelled.Bind(this)
		GuiControl +g, % this.hVJoyCancel, % fn
		Gui, Add, Button, xp+85 w75 Center HwndHwnd, Ok
		this.hVjoyOK := hwnd
		fn := this.vJoyOutputSelected.Bind(this)
		GuiControl +g, % this.hVjoyOK, % fn
	}
	
	; Builds the list of options in the DropDownList
	_BuildOptions(){
		opts := []
		this._CurrentOptionMap := [this._OptionMap["Select"]]
		opts.push("Select New Keyboard / Mouse Output")
		this._CurrentOptionMap.push(this._OptionMap["vJoyButton"])
		opts.push("Select New vJoy Button / Hat")
		this._CurrentOptionMap.push(this._OptionMap["Clear"])
		opts.push("Clear Output")
		this.SetOptions(opts)
	}
	
	; Used by script authors to set the state of this output
	SetState(state){
		max := this.__value.Buttons.Length()
		if (state)
			i := 1
		else
			i := max
		Loop % max{
			key := this.__value.Buttons[i]
			if (key.Type = 2 && key.IsVirtual){
				; Virtual Joystick Button
				UCR.Libraries.vJoy.Devices[key.DeviceID].SetBtn(state, key.code)
			} else if (key.Type >= 3 && key.IsVirtual){
				; Virtual Joystick POV Hat
				; ToDo: Make hat number selection actually work
				if (state = 0)
					state := -1
				else
					state := (key.code - 1) * 9000
				UCR.Libraries.vJoy.Devices[key.DeviceID].SetContPov(state, key.Type - 2)
			} else {
				; Keyboard / Mouse
				name := key.BuildKeyName()
				Send % "{" name (state ? " Down" : " Up") "}"
			}
			if (state)
				i++
			else
				i--
		}
	}
	
	; An option was selected from the list
	_ChangedValue(o){
		if (o){
			o := this._CurrentOptionMap[o]
			
			; Option selected from list
			if (o = 1){
				; Bind
				UCR._RequestBinding(this)
				return
			} else if (o = 2){
				; vJoy
				this._SelectvJoy()
			} else if (o = 3){
				; Clear Binding
				mod := {Buttons: []}
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
	
	; Present a menu to allow the user to select vJoy output
	_SelectvJoy(){
		Gui, % this.hVjoySelect ":Show"
		dev := this.__value.Buttons[1].DeviceId + 1
		GuiControl, % this.hVjoySelect ":Choose", % this.hVjoyDevice, % dev
		if (this.__value.Buttons[1].Type >= 3){
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatNumber, % this.__value.Buttons[1].Type - 1
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatDir, % this.__value.Buttons[1].code + 1
		} else {
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyButton, % this.__value.Buttons[1].code + 1
		}
	}
	
	vJoyOptionSelected(what){
		GuiControlGet, dev, % this.hVjoySelect ":" , % this.hVjoyDevice
		dev--
		GuiControlGet, but, % this.hVjoySelect ":" , % this.hVJoyButton
		but--
		GuiControlGet, hn, % this.hVjoySelect ":" , % this.hVJoyHatNumber
		hn--
		GuiControlGet, hd, % this.hVjoySelect ":" , % this.hVJoyHatDir
		hd--
		if (what = "but" && but){
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatNumber, 1
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatDir, 1
		} else if (what != "dev" && %what%){
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyButton, 1
		}
	}
	
	vJoyOutputSelected(){
		Gui, % this.hVjoySelect ":Submit"
		GuiControlGet, device, % this.hVjoySelect ":" , % this.hVjoyDevice
		device--
		GuiControlGet, button, % this.hVjoySelect ":" , % this.hVJoyButton
		button--
		GuiControlGet, hn, % this.hVjoySelect ":" , % this.hVJoyHatNumber
		hn--
		GuiControlGet, hd, % this.hVjoySelect ":" , % this.hVJoyHatDir
		hd--
		
		bo := new _BindObject()
		
		if (device && button){
			t := 2
		} else if (device && hn && hd) {
			t := 2 + hn
		} else {
			return
		}
		bo.Type := t
		
		key := new _Button()
		key.DeviceID := device
		if (t = 2)
			key.code := button
		else
			key.code := hd
		key.IsVirtual := 1
		key.Type := t
		
		bo.Buttons := [key]
		this.value := bo
	}
	
	vJoyInputCancelled(){
		Gui, % this.hVjoySelect ":Submit"
	}

	_Deserialize(obj){
		; Trigger _value setter to set gui state but not fire change event
		this._value := new _BindObject(obj)
	}
	
	__Delete(){
		OutputDebug % "Output " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		base._KillReferences()
		;~ GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		;~ this.ChangeValueCallback := ""
		;~ this.ChangeStateCallback := ""
	}
}

; ======================================================================== OUTPUT AXIS ===============================================================
class _OutputAxis extends _BannerCombo {
	;__value := {DeviceID: 0, axis: 0}
	__value := new _Axis()
	vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		
		this._Options := []
		Loop 8 {
			this._Options.push("Axis " A_Index " (" this.vJoyAxisList[A_Index] ")" )
		}
		Loop 8 {
			this._Options.push("vJoy Stick " A_Index )
		}
		this._Options.push("Clear Binding")
		this.SetComboState()
	}
	
	; Plugin Authors call this to set the state of the output axis
	SetState(state){
		UCR.Libraries.vJoy.Devices[this.__value.DeviceID].SetAxisByIndex(state, this.__value.Axis)
	}
	
	SetComboState(){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		this._OptionMap := []
		opts := []
		if (DeviceID){
			; Show Sticks and Axes
			max := 16
			index_offset := 0
		} else {
			str := "Pick a Stick"
			max := 10
			index_offset := 8
		}
		Loop % max {
			map_index := A_Index + index_offset
			if (map_index > 8 && map_index <= 16){
				if (!UCR.Libraries.vJoy.Devices[map_index - 8].IsAvailable()){
					continue
				}
			}
			opts.push(this._Options[map_index])
			this._OptionMap.push(map_index)
		}
		if (DeviceID || axis){
			opts.push(this._Options[17])
			this._OptionMap.push(17)
		}

		if (DeviceID)
			str := "Stick: " (DeviceID ? DeviceID : "None") ", Axis: " (axis ? axis : "None") (DeviceID && axis ? " (" this.vJoyAxisList[axis] ")" : "")

		this.SetOptions(opts)
		this.SetCueBanner(str)
	}
	
	_ChangedValue(o){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		
		; Resolve result of selection to index of full option list
		o := this._OptionMap[o]
		
		if (o <= 8){
			; Axis Selected
			axis := o
		} else if (o <= 16){
			; Stick Selected
			o -= 8
			DeviceID := o
		} else {
			; Clear Selected
			axis := DeviceID := 0
		}
		this.__value.Axis := axis
		this.__value.DeviceID := DeviceID
		
		this.SetComboState()
		this.value := this.__value
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
			this._value := value
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
			this.SetComboState()
			if (IsObject(this.ChangeValueCallback)){
				this.ChangeValueCallback.Call(this.__value)
			}
		}
	}

	_Serialize(){
		obj := {value: this._value}
		return obj
	}
	
	_Deserialize(obj){
		this._value := obj.value
	}

}
; ======================================================================== BINDOBJECT ===============================================================
; A BindObject represents a collection of keys / mouse / joystick buttons
class _BindObject {
	Type := 0 ; 0 = Unset, 1 = Key / Mouse, 2 = stick button, 3 = stick hat
	Buttons := []
	Wild := 0
	Block := 0
	Suppress := 0
	
	__New(obj){
		this._Deserialize(obj)
	}
	
	_Serialize(){
		obj := {Buttons: [], Wild: this.Wild, Block: this.Block, Suppress: this.Suppress, Type: this.Type}
		Loop % this.Buttons.length(){
			obj.Buttons.push(this.Buttons[A_Index]._Serialize())
		}
		return obj
	}
	
	_Deserialize(obj){
		for k, v in obj {
			if (k = "Buttons"){
				Loop % v.length(){
					this.Buttons.push(new _Button(v[A_Index]))
				}
			} else {
				this[k] := v
			}
		}
	}
	
	; Builds a human-readable form of the BindObject
	BuildHumanReadable(){
		max := this.Buttons.length()
		str := ""
		Loop % max {
			str .= this.Buttons[A_Index].BuildHumanReadable()
			if (A_Index != max)
				str .= " + "
		}
		return str
	}
}

; ======================================================================== BUTTON ===============================================================
; Represents a single digital input / output - keyboard key, mouse button, (virtual) joystick button or hat direction
class _Button {
	Type := 0 ; 0 = Unset, 1 = Key / Mouse, 2 = stick button, 3 = stick hat
	Code := 0
	DeviceID := 0
	UID := ""
	IsVirtual := 0		; Set to 1 for vJoy stick buttons / hats
	
	_Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
		,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
		,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
		,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	__New(obj){
		this._Deserialize(obj)
	}
	
	; Returns true if this Button is a modifier key on the keyboard
	IsModifier(){
		if (this.Type = 1 && ObjHasKey(this._Modifiers, this.Code))
			return 1
		return 0
	}
	
	; Renders the keycode of a Modifier to it's AHK Hotkey symbol (eg 162 for LCTRL to ^)
	RenderModifier(){
		return this._Modifiers[this.Code].s
	}
	
	; Builds the AHK key name
	BuildKeyName(){
		if this.Type = 1 {
			code := Format("{:x}", this.Code)
			return GetKeyName("vk" code)
		} else if (this.Type = 2){
			return this.DeviceID "Joy" this.code
		} else if (this.Type >= 3){
			return this.DeviceID "JoyPov"
		}
	}
	
	; Builds a human readable version of the key name (Mainly for joysticks)
	BuildHumanReadable(){
		static hat_directions := ["Up", "Right", "Down", "Left"]
		if (this.Type = 1) {
			return this.BuildKeyName()
		} else if (this.Type = 2){
			return (this.IsVirtual ? "Virtual " : "") "Stick " this.DeviceID ", Button " this.code
		} else if (this.Type >= 3){
			return (this.IsVirtual ? "Virtual " : "") "Stick " this.DeviceID ", Hat " this.Type - 2 " " hat_directions[this.code]
		}
	}
	
	_Serialize(){
		return {Type: this.Type, Code: this.Code, DeviceID: this.DeviceID, UID: this.UID, IsVirtual: this.IsVirtual}
	}
	
	_Deserialize(obj){
		for k, v in obj {
			this[k] := v
		}
	}
}

; ======================================================================== AXIS ===============================================================
class _Axis {
	DeviceID := 0
	Axis := 0
}

GuiClose(hwnd){
	UCR.GuiClose(hwnd)
}
