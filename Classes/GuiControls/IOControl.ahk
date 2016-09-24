class _IOControl extends _BannerMenu {
	_Serialize(){
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Pass 0 to SetBinding so we don't save while we are loading
		this.SetBinding(obj, 0)
	}
}