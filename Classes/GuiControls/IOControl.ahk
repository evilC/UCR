class _IOControl extends _BannerMenu {
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