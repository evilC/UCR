; ======================================================================== GUICONTROL ===============================================================
; Wraps a GuiControl to make it's value persistent between runs.
class GuiControl {
	static _ListTypes := {ListBox: 1, DDL: 1, DropDownList: 1, ComboBox: 1, Tab: 1, Tab2: 1, Tab3: 1}
	__value := ""	; variable that actually holds value.
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
		this.Set(value, 0)
	}
	
	__Delete(){
		OutputDebug % "UCR| GuiControl " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	OnClose(){
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
		return this.Get()
	}
	
	_Deserialize(obj){
		this.Set(obj, 0)
	}
}
