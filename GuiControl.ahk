; ======================================================================== GUICONTROL ===============================================================
; Wraps a GuiControl to make it's value persistent between runs.
class _GuiControl {
	__value := ""	; variable that actually holds value. ._value and .__value handled by Setters / Getters
	__New(parent, name, ChangeValueCallback, aParams*){
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueFn := this._ChangedValue.Bind(this)
		this.ChangeValueCallback := ChangeValueCallback
		h := this.ParentPlugin.hwnd
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
