; ======================================================================== INPUT BUTTON ===============================================================
; A class the script author can instantiate to allow the user to select a hotkey.
class _InputButton extends _BannerMenu {
	; Public vars
	State := -1			; State of the input. -1 is unset. GET ONLY
	; Internal vars describing the bindstring
	__value := 0		; Holds the BindObject class
	; Other internal vars
	_IsOutput := 0
	_BindTypes := {AHK_KBM_Input: "AHK_KBM_Input", AHK_JoyBtn_Input: "AHK_JoyBtn_Input", AHK_JoyHat_Input: "AHK_JoyHat_Input"}
	_IOClassNames := ["AHK_KBM_Input", "AHK_JoyBtn_Input", "AHK_JoyHat_Input"]
	_BindObjects := {}
	
	_DefaultBanner := "Select an Input Button"
	_OptionMap := {Select: 1, Wild: 2, Block: 3, Suppress: 4, Clear: 5}
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ID := UCR.CreateGUID()
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		UCR._RegisterGuiControl(this)

		;this.__value := new _BindObject()
		for i, name in this._IOClassNames {
			this._BindObjects[name] := new %name%(this)
			if (!this._BindObjects.IsInitialized) {
				this._BindObjects[name]._Init()
			}
		}
		this._BuildMenu()
		
		this.SetControlState()
	}
	
	__Delete(){
		OutputDebug % "UCR| InputButton " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		base._KillReferences()
		GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		this.ChangeValueCallback := ""
		this.ChangeStateCallback := ""
		this._KeyOnlyOptions := ""
	}
	
	value[]{
		get {
			return this.__value
		}
		
		set {
			this._value := value	; trigger _value setter to set value and cuebanner etc
			;OutputDebug % "UCR| Hotkey " this.Name " called ParentPlugin._ControlChanged()"
			this.ParentPlugin._ControlChanged(this)
		}
	}
	
	_value[]{
		get {
			return this.__value
		}
		
		; Parent class told this hotkey what it's value is. Set value, but do not fire ParentPlugin._ControlChanged
		set {
			this.__value := value
			this.SetControlState()
		}
	}

	_BuildMenu(){
		this.AddMenuItem("Select Binding", "SelectBinding", this._ChangedValue.Bind(this, 1))
		for i, cls in this._BindObjects {
			cls.AddMenuItems()
		}
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
		if (this.__value.Binding[1] || this.__value.DeviceID){
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner
		}
		this.SetCueBanner(Text)
		; Update the Menus etc of all the IOClasses in this control
		for i, cls in this._BindObjects {
			cls.UpdateMenus(this.__value.IOClass)
		}
	}
	
	; An option was selected from one of the Menus that this class controls
	; Menus in this GUIControl may be handled in an IOClass
	_ChangedValue(o){
		if (o){
			; Option selected from list
			if (o = 1){
				; Bind
				UCR.RequestBindMode(this._BindTypes, this._BindModeEnded.Bind(this))
				return
			} else if (o == 2){
				this.__value.Binding := []
				this.__value.DeviceID := 0
				this.SetBinding(this._value)
			}
		}
	}
	
	; Bind Mode has ended.
	; A "Primitive" BindObject will be passed, along with the IOClass of the detected input.
	; The Primitive contains just the Binding property and optionally the DeviceID property.
	_BindModeEnded(bo){
		if (this.__value.IOClass && this.__value.IOClass != bo.IOClass){
			; There is an existing, different IOClass
			this.Binding := []			; clear the old Binding
			UCR._RequestBinding(this)	; Tell the Input IOClass in the Profile's InputThread to delete the binding
		}
		this.SetBinding(bo)
	}
	
	; All Input controls should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		OutputDebug % "UCR| GuiControl " this.id " Requesting Binding from InputHandler"
		UCR._RequestBinding(this)
	}
	
	GetBinding(){
		return this._Serialize()
	}
	
	SetBinding(bo, update := 1){
		OutputDebug % "UCR| SetBinding: class: " bo.IOClass ", code: " bo.Binding[1] ", wild: " bo.BindOptions.wild
		;this.MergeObject(this._BindObjects[bo.IOClass], bo)
		this._BindObjects[bo.IOClass]._Deserialize(bo)
		this[update ? "value" : "_value"] := this._BindObjects[bo.IOClass]
		
		; ToDo - add in the condition that the binding must have also changed
		; Request the new binding from the Profile's InputThread.
		; If the IOClass was the same as before, the old binding will be deleted automatically
		UCR._RequestBinding(this)
	}
	
	_Serialize(){
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Pass 0 to SetBinding so we don't save while we are loading
		this.SetBinding(obj, 0)
	}
	
	MergeObject(src, patch){
		for k, v in patch {
			if (IsObject(v)){
				this.MergeObject(src[k], v)
			} else {
				src[k] := v
			}
		}
	}

}
