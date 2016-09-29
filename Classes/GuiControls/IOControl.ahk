class IOControl extends _UCR.Classes.GuiControls._BannerMenu {
	State := -1		; Holds current state of Input
	
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
	
	; Called by InputThread when an Input changes state
	OnStateChange(e){
		if (this.ChangeStateCallback != 0){
			this.State := e
			this.ChangeStateCallback.Call(e)
		}
	}
	
	_Serialize(){
		;val := this.__value._Serialize()
		;val._ControlType := this._ControlType
		;return val
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Pass 0 to Set so we don't save while we are loading
		this.Set(obj, 0)
	}
}