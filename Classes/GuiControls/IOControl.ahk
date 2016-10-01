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
	
	SetBinding(value, update_ini := 1, update_guicontrol := 1, fire_callback := 1){
		this._IOClasses[value.IOClass]._Deserialize(value)
		this.__value := this._IOClasses[value.IOClass]
		if (update_guicontrol)
			this.SetControlState()
		if (update_ini){
			this.ParentPlugin._ControlChanged(this)
			this._RequestBinding()
		}
		if (fire_callback && IsObject(this.ChangeValueCallback))
			this.ChangeValueCallback.Call(this.__value)
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
		if (IsObject(this.__value)){
			;OutputDebug % "UCR| GuiControl " this.id " Requesting Binding from InputHandler"
			UCR._RequestBinding(this)
		}
	}

	; Bind Mode has ended.
	; A "Primitive" BindObject will be passed, along with the IOClass of the detected input.
	; The Primitive contains just the Binding property and optionally the DeviceID property.
	_BindModeEnded(bo){
		if (this.__value.IOClass && this.__value.IOClass != bo.IOClass){
			; There is an existing, different IOClass
			this.Binding := []			; clear the old Binding
			this._RequestBinding()	; Tell the Input IOClass in the Profile's InputThread to delete the binding
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
	
	_Serialize(){
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Pass 0 to Set so we don't save while we are loading
		this.SetBinding(obj, 0)
	}
}