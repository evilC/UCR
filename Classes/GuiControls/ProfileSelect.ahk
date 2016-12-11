; ======================================================================== PROFILE SLECT ===============================================================
class ProfileSelect extends _UCR.Classes.GuiControls._BannerMenu {
	; Public vars
	State := -1			; State of the input. -1 is unset. GET ONLY
	; Internal vars describing the bindstring
	__value := 0		; Holds the Profile ID
	; Other internal vars
	_DefaultBanner := "Select a profile"
	
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.name := name
		this.ChangeValueCallback := ChangeValueCallback
		
		this._BuildMenu()
		
		this.SetControlState()
		UCR.SubscribeToProfileTreeChange(this.hwnd, this.SetControlState.Bind(this))
	}
	
	__Delete(){
		OutputDebug % "UCR| ProfileSelect " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	_BuildMenu(){
		this.AddMenuItem("Select Profile", "SelectProfile", this._ChangedValue.Bind(this, 1))
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
		if (this.__value){
			; Has current binding
			this.SetCueBanner(UCR.BuildProfilePathName(this.__value))
		} else {
			this.SetCueBanner(this._DefaultBanner)
		}
	}
	
	_ChangedValue(o){
		if (o == 1){
			UCR._ProfilePicker.PickProfile(this.ProfileChanged.Bind(this), this.__value)
		} else {
			this.Set(0)
		}
	}

	; A new selection was made in the Profile Picker
	ProfileChanged(id){
		this.Set(id)
	}
	
	Get(){
		return this.__value
	}

	Set(value, update_ini := 1, update_guicontrol := 1, fire_callback := 1){
		if (this.__value)
			this.ParentPlugin.ParentProfile.UpdateLinkedProfiles(this.ParentPlugin.id, this.__value, 0)
		this.__value := value
		if (value)
			this.ParentPlugin.ParentProfile.UpdateLinkedProfiles(this.ParentPlugin.id, value, 1)
		if (update_guicontrol)
			this.SetControlState()
		if (update_ini)
			this.ParentPlugin._ControlChanged(this)
		if (fire_callback && IsObject(this.ChangeValueCallback))
			this.ChangeValueCallback.Call(this.__value)
	}
	
	; Kill references so destructor can fire
	OnClose(){
		base.OnClose()
		this.ChangeValueCallback := ""
		UCR.UnSubscribeToProfileTreeChange(this.hwnd)
	}
	
	_Serialize(){
		return this.__value
	}
	
	_Deserialize(obj){
		; Pass 0 to Set so we don't save while we are loading
		this.Set(obj, 0)
	}
}