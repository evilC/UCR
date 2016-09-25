class IOControl extends _UCR._ControlClasses.GuiControls._BannerMenu {
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
	
	_Serialize(){
		;val := this.__value._Serialize()
		;val._ControlType := this._ControlType
		;return val
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Pass 0 to SetBinding so we don't save while we are loading
		this.SetBinding(obj, 0)
	}
}