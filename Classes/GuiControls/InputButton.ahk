; ======================================================================== INPUT BUTTON ===============================================================
; A class the script author can instantiate to allow the user to select a hotkey.
class _InputButton extends _BannerMenu {
	; Public vars
	State := -1			; State of the input. -1 is unset. GET ONLY
	; Internal vars describing the bindstring
	__value := 0		; Holds the BindObject class
	; Other internal vars
	_IsOutput := 0
	_BindTypes := {AHK_KBM_Input: "AHK_KBM_Input", AHK_Joy_Buttons: "AHK_Joy_Buttons"}
	_IOClassNames := ["AHK_KBM_Input", "AHK_Joy_Buttons"]
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
			this.SetControlState()
		}
	}

	_BuildMenu(){
		this.AddMenuItem("Select Binding", "SelectBinding", this._ChangedValue.Bind(this, 1))
		wild := this.AddMenuItem("Wild", "Wild", this._ChangedValue.Bind(this, 2))
		block := this.AddMenuItem("Block", "Block", this._ChangedValue.Bind(this, 3))
		suppress := this.AddMenuItem("Suppress Repeats", "SuppressRepeats", this._ChangedValue.Bind(this, 4))
		this._KeyOnlyOptions := {wild: wild, block: block, suppress: suppress}
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 5))
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
		/*
		ko := (this.__value.Type == 1 && this.__value.Buttons.length())
		for n, opt in this._KeyOnlyOptions {
			opt.SetEnableState(ko)
			opt.SetCheckState(this.__value[n])
		}
		if ( this.__value.Buttons.length()) {
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner			
		}
		this.SetCueBanner(Text)
		*/
		Text := this.__value.BuildHumanReadable()
		this.SetCueBanner(Text)
	}
	
	; An option was selected from the list
	_ChangedValue(o){
		if (o){
			;o := this._CurrentOptionMap[o]
			
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
				;mod := {Buttons: []}
				val := this.__value.clone()
				val.Binding := []
				this.value := val
				return
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
		;this._value := new _BindObject(obj)
		cls := obj.IOClass
		this._value := new %cls%(this, obj)
		; Register hotkey on load
		;UCR._InputHandler.SetButtonBinding(this)
	}
}
