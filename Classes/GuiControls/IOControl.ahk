class IOControl extends _UCR.Classes.GuiControls._BannerMenu {
	State := -1		; Holds current state of Input
	_IOClasses := {}
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		UCR._RegisterGuiControl(this)

		for i, name in this._IOClassNames {
			call:= _UCR.Classes.IOClasses[name]
			this._IOClasses[name] := new call(this)

			if (!this._IOClasses.IsInitialized) {
				this._IOClasses[name]._Init()
			}
		}
		this._BuildMenu()
		
		this.SetControlState()
	}
	
	GetBinding(){
		return this.__value
	}
	
	SetBinding(bo, update_ini := 1, update_guicontrol := 1, fire_callback := 1){
		if (bo.IOClass != this.GetBinding().IOClass)
			this.RemoveBinding()
		this._IOClasses[bo.IOClass]._Deserialize(bo)
		this.__value := this._IOClasses[bo.IOClass]
		if (update_guicontrol)
			this.SetControlState()
		if (update_ini){
			this.ParentPlugin._ControlChanged(this)
			this._RequestBinding()
		}
		if (fire_callback && IsObject(this.ChangeValueCallback))
			this.ChangeValueCallback.Call(this.__value)
	}

	RemoveBinding(){
		this.__value.Binding := []			; clear the old Binding
		; Do not clear DeviceID, so vGen etc know which device to release
		this._RequestBinding()	; Tell the Input IOClass in the Profile's InputThread to delete the binding
	}
	
	IsBound(){
		return this.GetBinding().IsBound()
	}
	
	Get(){
		return this.State
	}
	
	Set(state){
		this.State := state
	}

	
	; All IOControls should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		bo := this.GetBinding()
		if (IsObject(bo)){
			;OutputDebug % "UCR| GuiControl " this.id " Requesting Binding from InputHandler"
			if (bo.IOType){
				; Output Type
				bo.UpdateBinding()
			} else {
				; Input Type
				UCR._RequestBinding(this)
			}
		}
	}

	; Bind Mode has ended.
	; A "Primitive" BindObject will be passed, along with the IOClass of the detected input.
	; The Primitive contains just the Binding property and optionally the DeviceID property.
	_BindModeEnded(bo){
		if (this.__value.IOClass && this.__value.IOClass != bo.IOClass){
			; There is an existing, different IOClass
			this.RemoveBinding()	; Tell the Input IOClass in the Profile's InputThread to delete the binding
		}
		this.SetBinding(bo)
	}
	
	; Called by InputThread when an Input changes state
	OnStateChange(e){
		if (this.ChangeStateCallback != 0){
			;OutputDebug % "UCR| IOControl class firing state change callback"
			this.State := e
			this.ChangeStateCallback.Call(e)
		}
	}
	
	OnClose(remove_binding := 1){
		;OutputDebug % "UCR| IOControl " this.id " fired OnClose event"
		;GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		this.ChangeValueCallback := ""
		this.ChangeStateCallback := ""
		this._IOClasses := ""
		base.OnClose()
		if (remove_binding){
			this.RemoveBinding()
		}
	}
	
	_Serialize(){
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Pass 0 to Set so we don't save while we are loading
		this.SetBinding(obj, 0)
	}
}