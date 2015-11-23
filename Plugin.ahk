; ======================================================================== PLUGIN ===============================================================
; The _Plugin class itself is never instantiated.
; Instead, plugins derive from the base _Plugin class.
Class _Plugin {
	static Type := "_Plugin"	; Change this to match the name of your class. It MUST be unique amongst ALL plugins.
	
	ParentProfile := 0			; Will point to the parent profile
	Name := ""					; The name the user chose for the plugin
	Hotkeys := {}				; An associative array, indexed by name, of child Hotkeys
	Outputs := {}				; An associative array, indexed by name, of child Outputs
	GuiControls := {}			; An associative array, indexed by name, of child GuiControls
	
	; Override this class in your derived class and put your Gui creation etc in here
	Init(){
		
	}
	
	; ------------------------------- PRIVATE -------------------------------------------
	; Do not override methods in here unless you know what you are doing!
	__New(parent, name){
		;this.ParentProfile := parent
		this.ParentProfile := Object(parent)
		this.Name := name
		this._CreateGui()
	}
	
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
	
	GuiControl(SubCommand,ControlID:="",aParam3:=""){
		GuiControl % this.hwnd ":" SubCommand,% ControlID,% aParam3
	}
	
	Gui(aParams*){
		Gui % this.hwnd ":" aParams.1,% aParams.2,% "hwndhwnd " aParams.3,% aParams.4
		return hwnd
	}
	
	; An Output is a sequence of keys to be pressed, often in reaction to a hotkey being pressed
	AddOutput(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.Outputs, name)){
			this.Outputs[name] := new _Output(this, name, ChangeValueCallback, aParams*)
			return this.Outputs[name]
		}
	}
	
	_CreateGui(){
		Gui, new, HwndHwnd
		this.hwnd := hwnd
		Gui % this.hwnd ":+LabelGui"
		;Gui, +ToolWindow
		Gui -Caption
	}
	
	Show(options){
		;Gui, % this.ParentProfile.hwnd ":Add", Gui, % "w" UCR.PLUGIN_WIDTH, % this.hwnd
		Gui, % this.hwnd ":+Parent" this.ParentProfile.hwnd
		;Gui, % this.hwnd ":Show", x0 y50
		Gui, % this.hwnd ":Show", % options
	}
	
	_ControlChanged(ctrl){
		OutputDebug % "Plugin " this.Name " --> Profile"
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
		for name, ctrl in this.Outputs {
			obj.Outputs[name] := ctrl._Serialize()
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
		for name, ctrl in obj.Outputs {
			this.Outputs[name]._Deserialize(ctrl)
		}
		
	}

}