; ======================================================================== INPUT DELTA ===============================================================
; An input that reads delta move information from the mouse
class _InputDelta {
	__New(parent, name, ChangeStateCallback, aParams*){
		this._Ptr := &this
		this.ChangeStateCallback := ChangeStateCallback
		this.ParentPlugin := parent
		this.Name := name
		this.ID := UCR.CreateGUID()
		this.hwnd := parent.hwnd	; no gui for this input, so use hwnd of parent for unique id
		this.value := 0
	}
	
	Register(){
		UCR._InputHandler.SetDeltaBinding(this)
	}
	
	UnRegister(){
		UCR._InputHandler.SetDeltaBinding(this, 1)
	}
	
	; All Input controls should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		this.Register()
	}
	
	_Serialize(){
		obj := {value: this.value}
		return obj
	}
	
	_Deserialize(obj){
		this.value := obj.value
	}
}
