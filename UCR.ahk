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
	
	; A child profile changed in some way
	_ProfileChanged(profile){
		obj := this._Serialize()
		
		jdata := JSON.Dump(obj, true)
		FileReplace(jdata,this._SettingsFile)
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
		return obj
	}
	
	_Deserialize(obj){
		this.Type := obj.Type
		for name, ctrl in obj.GuiControls {
			this.GuiControls[name]._Deserialize(ctrl)
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

; ======================================================================== SAMPLE PLUGINS ===============================================================

class TestPlugin1 extends _Plugin {
	static Type := "TestPlugin1"
	Init(){
		Gui, Add, Text,, % "Name: " this.Name ", Type: " this.Type
		this.MyEdit1 := this.AddControl("MyEdit1", this.MyEditChanged.Bind(this, "MyEdit1"), "Edit", "xm w200")
		this.MyEdit2 := this.AddControl("MyEdit2", this.MyEditChanged.Bind(this, "MyEdit2"), "Edit", "xm w200")
	}
	
	MyEditChanged(name){
		ToolTip % Name " changed value to: " this[Name].value
	}
}

class TestPlugin2 extends _Plugin {
	static Type := "TestPlugin2"
	Init(){
		Gui, Add, Text,, % "Name: " this.Name ", Type: " this.Type
	}
}
