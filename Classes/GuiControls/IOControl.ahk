; IOControls keep an _IOClasses array containing one class for each IOClass of binding that they support, plus a base BindObject class (for "Unbound")
; As the user selects different kinds of Input or Output from the control, the appropriate class is swapped out from the array into .__value
; This allow the various options etc for each class to persist if the user swaps around IOClasses in one session.
; It also means that classes do not have to be instantiated on the fly

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
		this.__value := new _UCR.Classes.IOClasses.BindObject()
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
	
	; Changes the binding of an IOControl
	; 
	SetBinding(bo := 0, update_ini := 1, update_guicontrol := 1, fire_callback := 1){
		if (bo == 0){
			bo := new _UCR.Classes.IOClasses.BindObject()
		}
		cb := this.GetBinding()
		if (bo.IOClass != cb.IOClass || bo.DeviceID != cb.DeviceID){
			cb.ClearBinding()
			this._RequestBinding()	; Tell the Input IOClass in the Profile's InputThread to delete the binding
		}
		if (bo.IOType == 0){
			; Plain BindObject (Unbound)
			this.__value := bo
		} else {
			; Bound IOClass
			this._IOClasses[bo.IOClass]._Deserialize(bo)
			this.__value := this._IOClasses[bo.IOClass]
		}
		if (update_guicontrol)
			this.SetControlState()
		if (update_ini){
			this.ParentPlugin._ControlChanged(this)
			this._RequestBinding()
		}
		if (fire_callback && IsObject(this.ChangeValueCallback))
			this.ChangeValueCallback.Call(this.__value)
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

	; Handles updating of Bindings for IOControls
	; For Input bindings, this will be a request to the Input Thread
	; For Output bindings, this will be a request to the IOClass itself
	_RequestBinding(){
		bo := this.GetBinding()
		if (!bo.IOType)
			return	; Do not request BindObject class bindings - clearing a binding is done with the appropriate IOClass
		if (IsObject(bo)){
			if (bo.IOType == 2){
				; Output Type
				OutputDebug % "UCR| IOControl _RequestBinding - " this.name " Calling UpdateBinding on BindObject - IOType: " bo.IOType
				bo.UpdateBinding()
			} else if (bo.IOType == 1){
				; Input Type
				UCR._RequestBinding(this)
				OutputDebug % "UCR| IOControl _RequestBinding - " this.name " Requesting Binding from InputHandler - IOType: " bo.IOType
			} else {
				OutputDebug % "UCR| IOControl _RequestBinding - " this.name " WARNING: Not recognized IOType of " bo.IOType
			}
		}
	}

	; Bind Mode has ended.
	; A "Primitive" BindObject will be passed, along with the IOClass of the detected input.
	; The Primitive contains just the Binding property and optionally the DeviceID property.
	_BindModeEnded(bo){
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
			this.SetBinding(0, 0, 0, 0)
		}
	}
	
	_Serialize(){
		return this.GetBinding()._Serialize()
	}
	
	_Deserialize(obj){
		; Pass 0 to Set so we don't save while we are loading
		if (IsObject(obj)){
			this.SetBinding(obj, 0)
		}
	}
}