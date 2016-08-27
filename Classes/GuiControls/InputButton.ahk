; ======================================================================== INPUT BUTTON ===============================================================
; A class the script author can instantiate to allow the user to select a hotkey.
class _InputButton extends _BannerCombo {
	; Public vars
	State := -1			; State of the input. -1 is unset. GET ONLY
	; Internal vars describing the bindstring
	__value := ""		; Holds the BindObject class
	; Other internal vars
	_IsOutput := 0
	_DefaultBanner := "Drop down the list to select a binding"
	_OptionMap := {Select: 1, Wild: 2, Block: 3, Suppress: 4, Clear: 5}
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ID := UCR.CreateGUID()
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
		this.__value := new _BindObject()
		this.SetComboState()
	}
	
	__Delete(){
		OutputDebug % "UCR| Hotkey " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		this.ChangeValueCallback := ""
		this.ChangeStateCallback := ""
	}
	
	value[]{
		get {
			return this.__value
		}
		
		set {
			this._value := value	; trigger _value setter to set value and cuebanner etc
			OutputDebug % "UCR| Hotkey " this.Name " called ParentPlugin._ControlChanged()"
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
			this.SetComboState()
		}
	}

	; Builds the list of options in the DropDownList
	_BuildOptions(){
		opts := []
		this._CurrentOptionMap := [this._OptionMap["Select"]]
		opts.push("Select New Binding")
		if (this.__value.Type = 1){
			; Joystick buttons do not have these options
			opts.push("Wild: " (this.__value.wild ? "On" : "Off"))
			this._CurrentOptionMap.push(this._OptionMap["Wild"])
			opts.push("Block: " (this.__value.block ? "On" : "Off"))
			this._CurrentOptionMap.push(this._OptionMap["Block"])
			opts.push("Suppress Repeats: " (this.__value.suppress ? "On" : "Off"))
			this._CurrentOptionMap.push(this._OptionMap["Suppress"])
		}
		opts.push("Clear Binding")
		this._CurrentOptionMap.push(this._OptionMap["Clear"])
		this.SetOptions(opts)
	}

	; Set the state of the GuiControl (Inc Cue Banner)
	SetComboState(){
		this._BuildOptions()
		if (this.__value.Buttons.length()) {
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner			
		}
		this.SetCueBanner(Text)
	}
	
	; An option was selected from the list
	_ChangedValue(o){
		if (o){
			o := this._CurrentOptionMap[o]
			
			; Option selected from list
			if (o = 1){
				; Bind
				UCR._RequestBinding(this)
				return
			} else if (o = 2){
				; Wild
				mod := {wild: !this.__value.wild}
			} else if (o = 3){
				; Block
				mod := {block: !this.__value.block}
			} else if (o = 4){
				; Suppress
				mod := {suppress: !this.__value.suppress}
			} else if (o = 5){
				; Clear Binding
				mod := {Buttons: []}
			} else {
				; not one of the options from the list, user must have typed in box
				return
			}
			if (IsObject(mod)){
				UCR._RequestBinding(this, mod)
				return
			}
		}
	}
	
	; All Input controls should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		UCR._InputHandler.SetButtonBinding(this)
	}
	
	_Serialize(){
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Trigger _value setter to set gui state but not fire change event
		this._value := new _BindObject(obj)
		; Register hotkey on load
		;UCR._InputHandler.SetButtonBinding(this)
	}
}
