#SingleInstance force
;#!ahk_h_v2
#include JSON_H.ahk

global UCR_PLUGIN_WIDTH := 500, UCR_PLUGIN_FRAME_WIDTH := 540

global UCR
UCR := new UCRMain()
return

GuiClose:
	ExitApp

Class UCRMain {
	;_SerializeValues := ["CurrentProfile"]
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
		
		; Add Plugin
		Gui, % this.hwnd ":Add", Text, xm y+10, Plugin Selection:
		Gui, % this.hwnd ":Add", DDL, % "x100 yp-5 hwndhPluginSelect w300"
		this.hPluginSelect := hPluginSelect

		Gui, % this.hwnd ":Add", Button, % "hwndhAddPlugin x+5 yp", Add Plugin
		this.hAddPlugin := hAddPlugin
		fn := this._AddPlugin.Bind(this)
		GuiControl % this.hwnd ":+g", % this.hAddPlugin, % fn
	}
	
	_ProfileSelectChanged(){
		GuiControlGet, name, % this.hwnd ":", % this.hProfileSelect
		this._ChangeProfile(name)
	}
	
	_AddPlugin(){
		this.CurrentProfile._AddPlugin()
	}
	
	_ChangeProfile(name){
		if (IsObject(this.CurrentProfile))
			this.CurrentProfile._DeActivate()
		this.CurrentProfile := this.Profiles[name]
		this.CurrentProfile._Activate()
		this._ProfileChanged(this.CurrentProfile)
	}
	
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
	
	_AddProfile(name){
		if (ObjHasKey(this.Profiles, name)){
			return false
		}
		this.Profiles[name] := new _Profile(name)
		
	}
	
	_LoadPluginList(){
		this.PluginList := ["TestPlugin1", "TestPlugin2"]
	}
	
	_LoadSettings(){
		this._LoadPluginList()
		this._UpdatePluginSelect()
		
		;this._AddProfile("Global")
		;this._AddProfile("Default")
		;this.CurrentProfile := this.Profiles.Default
		FileRead, j, % this._SettingsFile
		j := JSON.Load(j)
		this._Deserialize(j)
		
		this._UpdateProfileSelect()
		this._ChangeProfile(this.CurrentProfile.Name)
	}
	
	_Serialize(){
		obj := {}
		for idx, key in this._SerializeValues {
			obj[key] := this[key]
		}
		obj := {CurrentProfile: this.CurrentProfile.Name}
		obj.Profiles := {}
		for name, profile in this.Profiles {
			obj.Profiles[name] := profile._Serialize()
		}
		return obj
	}

	_Deserialize(obj){
		for idx, key in this._SerializeValues {
			this[key] := obj[key]
		}
		this.Profiles := {}
		for name, profile in obj.Profiles {
			this.Profiles[name] := new _Profile(name)
			this.Profiles[name]._Deserialize(profile)
		}
		this.CurrentProfile := this.Profiles[obj.CurrentProfile]
		
		
	}
	
	_ProfileChanged(profile){
		obj := this._Serialize()
		
		jdata := JSON.Dump(obj, true)
		FileReplace(jdata,this._SettingsFile)
		;FileOpen("A_Script
	}
}

Class _Profile {
	Name := ""
	Plugins := {}
	AssociatedApss := 0
	
	__New(name){
		this.UCR := parent
		this.Name := name
		this._CreateGui()
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
		;ToolTip % "Profile Activated: " this.Name
		Gui, % this.hwnd ":Show"
	}
	
	_DeActivate(){
		Gui, % this.hwnd ":Hide"
	}
	
	_AddPlugin(){
		GuiControlGet, plugin, % UCR.hwnd ":", % UCR.hPluginSelect
		suggestedname := name := this._GetUniqueName(%plugin%)
		choosename := 1
		prompt := "Enter a Name for the plugin"
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
		for idx, key in this._SerializeValues {
			obj[key] := this[key]
		}
		obj.Plugins := {}
		for name, plugin in this.Plugins {
			obj.Plugins[name] := plugin._Serialize()
		}
		return obj
	}
	
	_Deserialize(obj){
		for idx, key in this._SerializeValues {
			this[key] := obj[key]
		}
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

Class _Plugin {
	_SerializeValues := ["Type"]
	static Type := "BASE PLUGIN"
	ParentProfile := 0
	Name := ""
	Hotkeys := {}
	GuiControls := {}
	
	AddControl(name, ChangeValueCallback, aParams*){
		;this.ParentProfile
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
	
	Init(){
		
	}
	
	Show(){
		Gui, % this.ParentProfile.hwnd ":Add", Gui, % "w" UCR_PLUGIN_WIDTH, % this.hwnd
	}
	
	_ControlChanged(ctrl){
		this.ParentProfile._PluginChanged(this)
	}
	
	_Serialize(){
		obj := {}
		for idx, key in this._SerializeValues {
			obj[key] := this[key]
		}
		obj.GuiControls := {}
		for name, ctrl in this.GuiControls {
			obj.GuiControls[name] := ctrl._Serialize()
		}
		return obj
	}
	
	_Deserialize(obj){
		for idx, key in this._SerializeValues {
			this[key] := obj[key]
		}
		for name, ctrl in obj.GuiControls {
			this.GuiControls[name]._Deserialize(ctrl)
		}
		
	}

}

class _GuiControl {
	_SerializeValues := ["_value"]
	__New(parent, name, ChangeValueCallback, aParams*){
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		Gui, % this.ParentPlugin.hwnd ":Add", % aParams[1], % "hwndhwnd " aParams[2], % aParams[3]
		this.hwnd := hwnd
		fn := this._ChangedValue.Bind(this)
		GuiControl, % this.ParentPlugin.hwnd ":+g", % this.hwnd, % fn
	}
	
	value[]{
		get {
			return this.__value
		}
		
		set {
			this.__value := value
			this.ParentPlugin._ControlChanged(this)
		}
	}
	
	_value[]{
		get {
			return this.__value
		}
		set {
			this.__value := value
			GuiControl, , % this.hwnd, % value
		}
	}
	
	_ChangedValue(){
		GuiControlGet, value, % this.ParentPlugin.hwnd ":", % this.hwnd
		this.value := value
		this.ParentPlugin._ControlChanged(this)
		if (IsObject(this.ChangeValueCallback)){
			this.ChangeValueCallback.()
		}
	}
	
	_Serialize(){
		obj := {}
		for idx, key in this._SerializeValues {
			obj[key] := this[key]
		}
		return obj
	}
	
	_Deserialize(obj){
		for idx, key in this._SerializeValues {
			this[key] := obj[key]
		}
	}

}

; ============================================================================================

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
