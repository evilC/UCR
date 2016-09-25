; ======================================================================== GUICONTROL ===============================================================
; Wraps a GuiControl to make it's value persistent between runs.
class _GuiControl {
	static _ListTypes := {ListBox: 1, DDL: 1, DropDownList: 1, ComboBox: 1, Tab: 1, Tab2: 1, Tab3: 1}
	__value := ""	; variable that actually holds value. ._value and .__value handled by Setters / Getters
	__New(parent, type, name, ChangeValueCallback, aParams*){
		this.ParentPlugin := parent
		this.Name := name
		this.ControlType := type
		; Detect what kind of GuiControl this is, so that later operations (eg set of value) work as intended.
		; Decide whether the control type is a "List" type: ListBox, DropDownList (ddl), ComboBox, and Tab (and tab2?)
		if (ObjHasKey(this._ListTypes, type)){
			this.IsListType := 1
			; Detect if this List Type uses AltSubmit
			if (InStr(aParams[1], "altsubmit"))
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
		Gui, % this.ParentPlugin.hwnd ":Add", % type, % "hwndhwnd " aParams[1], % aParams[2]
		this.hwnd := hwnd
		; Set default value - get this from state of GuiControl before any loading of settings is done
		GuiControlGet, value, % this.ParentPlugin.hwnd ":", % this.hwnd
		this.__value := value
		; Turn on the gLabel
		this._SetGlabel(1)
		
		; Fire ChangeValueCallback so that any variables that depend on GuiControl values can be initialized
		if (IsObject(ChangeValueCallback))
			ChangeValueCallback.Call(value)
	}
	
	__Delete(){
		OutputDebug % "UCR| GuiControl " this.name " in plugin " this.ParentPlugin.name " fired destructor"
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
			OutputDebug % "UCR| GuiControl " this.Name " called ParentPlugin._ControlChanged()"
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
			this.SetControlState()
		}
	}
	
	Get(){
		return this.__value
	}
	
	Set(value, update_ini := 1, update_guicontrol := 1, fire_callback := 1){
		this.__value := value
		if (update_guicontrol)
			this.SetControlState()
		if (update_ini)
			this.ParentPlugin._ControlChanged(this)
		if (fire_callback && IsObject(this.ChangeValueCallback))
			this.ChangeValueCallback.Call(this.__value)
	}
	
	SetControlState(){
		this._SetGlabel(0)						; Turn off g-label to avoid triggering save
		cmd := ""
		if (this.IsListType){
			cmd := (this.IsAltSubmitType ? "choose" : "choosestring")
		}
		GuiControl, % cmd, % this.hwnd, % this.Get()
		this._SetGlabel(1)						; Turn g-label back on
	}
	
	; The user typed something into the GuiControl
	_ChangedValue(){
		GuiControlGet, value, % this.ParentPlugin.hwnd ":", % this.hwnd
		this.Set(value, 1, 0, 1)
	}
	
	; All Input controls should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		; do nothing
	}
	
	_Serialize(){
		obj := {value: this._value}
		return obj
	}
	
	_Deserialize(obj){
		this.Set(obj.value, 0)
		; Fire callback so plugins can initialize internal vars
		if (IsObject(this.ChangeValueCallback)){
			this.ChangeValueCallback.Call(obj.value)
		}
	}
}
