; ======================================================================== PLUGIN ===============================================================
; The _Plugin class itself is never instantiated.
; Instead, plugins derive from the base _Plugin class.
Class _Plugin {
	Type := "_Plugin"			; The class of the plugin
	ParentProfile := 0			; Will point to the parent profile
	ID := 0						; Unique ID for the plugin
	Name := ""					; The name the user chose for the plugin
	GuiControls := {}			; An associative array, indexed by name, of child GuiControls
	InputButtons := {}			; An associative array, indexed by name, of child Input Buttons (aka Hotkeys)
	InputDeltas := {}
	OutputButtons := {}			; An associative array, indexed by name, of child Output Buttons
	InputAxes := {}				; An associative array, indexed by name, of child Input Axes
	OutputAxes := {}			; An associative array, indexed by name, of child Output (virtual) Axes
	ProfileSelects := {}		; An associative array, indexed by name, of Profile Select GuiControls
	_SerializeList := ["GuiControls", "InputButtons", "InputDeltas", "OutputButtons", "InputAxes", "OutputAxes", "ProfileSelects"]
	_CustomControls := {InputButton: 1, InputDelta: 1, OutputButton: 1, InputAxis: 1, OutputAxis: 1, ProfileSelect: 1}
	
	; Override this class in your derived class and put your Gui creation etc in here
	Init(){
		
	}
	
	; === Plugins can call these commands to add various GuiControls to their Gui ===
	; Adds a GuiControl that allows the end-user to choose a value, often used to configure the script
	AddControl(type, name, ChangeValueCallback, aParams*){
		if (ObjHasKey(this._CustomControls, type)){
			this.GuiControls[name] := new %type%(this, name, ChangeValueCallback, aParams*)
		} else {
			this.GuiControls[name] := new _GuiControl(this, type, name, ChangeValueCallback, aParams*)
		}
		return this.GuiControls[name]
	}
	
	AddInputDelta(name, ChangeStateCallback, aParams*){
		if (!ObjHasKey(this.InputDeltas,name)){
			this.InputDeltas[name] := new _InputDelta(this, name, ChangeStateCallback, aParams*)
			return this.InputDeltas[name]
		}
	}
	
	; Adds a Profile Select GuiControl
	AddProfileSelect(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.ProfileSelects,name)){
			this.ProfileSelects[name] := new _ProfileSelect(this, name, ChangeValueCallback, aParams*)
			return this.ProfileSelects[name]
		}
	}
	
	; === Private ===
	__New(id, name, parent){
		this.ParentProfile := parent
		this.ID := id
		this.Name := name
		this._CreateGui()
		this.Init()
		this._ParentGuis()
	}
	
	_Delete(){
		; delete plugin requested
	}
	
	__Delete(){
		OutputDebug % "UCR| Plugin " this.name " in profile " this.ParentProfile.name " fired destructor"
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
		OutputDebug % "UCR| Plugin " this.Name " called ParentProfile._PluginChanged()"
		this.ParentProfile._PluginChanged()
	}
	
	; Save plugin to disk
	_Serialize(){
		obj := {Type: this.Type, name: this.Name}
		obj.GuiControls := {}
		for name, ctrl in this.GuiControls {
			obj.GuiControls[name] := ctrl._Serialize()
		}
		/*
		Loop % this._SerializeList.length(){
			key := this._SerializeList[A_Index]
			obj[key] := {}
			for name, ctrl in this[key] {
				obj[key, name] := ctrl._Serialize()
			}
		}
		*/
		return obj
	}
	
	; Load plugin from disk
	_Deserialize(obj){
		this.Type := obj.Type
		for name, ctrl in obj.GuiControls {
			this.GuiControls[name]._Deserialize(ctrl)
		}
		/*
		Loop % this._SerializeList.length(){
			key := this._SerializeList[A_Index]
			for name, ctrl in obj[key] {
				this[key, name]._Deserialize(ctrl)
			}
		}
		*/
	}
	
	_OnActive(){
		; Call user's OnInactive method (if it exists)
		if (IsFunc(this["OnActive"])){
			this.OnActive()
		}
	}
	
	; Called when a plugin becomes inactive (eg profile changed)
	_OnInActive(){
		for k, v in this.OutputButtons{
			if (v.State == 1)
				v.SetState(0)
		}
		; Call user's OnInactive method (if it exists)
		if (IsFunc(this["OnInActive"])){
			this.OnInActive()
		}
	}
	
	; Call _RequestBinding on all child controls
	_RequestBinding(){
		Loop % this._SerializeList.length(){
			key := this._SerializeList[A_Index]
			for name, ctrl in this[key] {
				ctrl._RequestBinding()
			}
		}
	}
	
	; The plugin was closed (deleted)
	_Close(){
		; Call plugin's OnDelete method, if it exists
		if (IsFunc(this["OnDelete"])){
			this.OnDelete()
		}
		; Remove input bindings etc here
		; Some attempt is also made to free resources so destructors fire, though this is a WIP
		this.InputButtons := ""
		for Name, obj in this.InputAxes {
			UCR._InputHandler.SetAxisBinding(obj, 1)
			obj._KillReferences()
		}
		for name, obj in this.GuiControls {
			obj._KillReferences()
		}
		this.GuiControls := ""
		this.ParentProfile._RemovePlugin(this)
		try {
			this._KillReferences()
		}
	}
}
