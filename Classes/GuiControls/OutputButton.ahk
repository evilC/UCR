; ======================================================================== OUTPUT BUTTON ===============================================================
; An Output allows the end user to specify which buttons to press as part of a plugin's functionality
Class OutputButton extends _UCR.Classes.GuiControls.InputButton {
	static _ControlType := "OutputButton"
	static _DefaultBanner := "Select an Output Button"
	static _IsOutput := 1
	static _BindTypes := {AHK_Common: 0, AHK_KBM_Input: "AHK_KBM_Output"}
	static _IOClassNames := ["AHK_KBM_Output", "vJoy_Button_Output", "vJoy_Hat_Output", "vXBox_Button_Output", "vXBox_Hat_Output"]

	State := 0
	JoyMenus := []
	
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
		; Create Select vJoy Button / Hat Select GUI
	}
	
	_BuildMenu(){
		this.AddMenuItem("Select Keyboard / Mouse Binding...", "AHK_KBM_Output", this._ChangedValue.Bind(this, 1))
		for i, cls in this._IOClasses {
			cls.AddMenuItems()
		}
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))

	}
	
	; Builds the list of options in the DropDownList
	SetControlState(){
		base.SetControlState()
		; Tell vGen etc to Acquire sticks
		this.__value.UpdateBinding()
		; Update the Menus etc of all the IOClasses in this control
		for i, cls in this._IOClasses {
			cls.UpdateMenus(this.__value.IOClass)
		}
		;joy := (this.__value.Type >= 2 && this.__value.Type <= 6)
		;for n, opt in this.JoyMenus {
		;	opt.SetEnableState(joy)
		;}
	}
	
	; Used by script authors to set the state of this output
	SetState(state, delay_done := 0){
		static PovMap := {0: {x:0, y:0}, 1: {x: 0, y: 1}, 2: {x: 1, y: 0}, 3: {x: 0, y: 2}, 4: {x: 2, y: 0}}
		static PovAngles := {0: {0:-1, 1:0, 2:18000}, 1:{0:9000, 1:4500, 2:13500}, 2:{0:27000, 1:31500, 2:22500}}
		static Axes := ["x", "y"]
		if (UCR._CurrentState == 2 && !delay_done){
			fn := this.SetState.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.__value.SetState(state)
			this.State := state
		}
	}
	
	; An option was selected from one of the Menus that this class controls
	; Menus in this GUIControl may be handled in an IOClass
	_ChangedValue(o){
		if (o){
			if (o = 1){
				; Bind
				;UCR._RequestBinding(this)
				UCR.RequestBindMode(this._BindTypes, this._BindModeEnded.Bind(this)) ;*[UCR]
				return
			} else if (o = 2){
				; Clear Binding
				this.Get()._UnRegister()
				this.__value.Binding := []
				this.__value.DeviceID := 0
				this.SetBinding(this.__value)
			}
		}
	}
	
	; Bind Mode has ended.
	; A "Primitive" BindObject will be passed, along with the IOClass of the detected input.
	; The Primitive contains just the Binding property and optionally the DeviceID property.
	_BindModeEnded(bo){
		this.SetBinding(bo)
	}
	
	; bo is a "Primitive" BindObject
	SetBinding(bo, update_ini := 1){
		;OutputDebug % "UCR| SetBinding: class: " bo.IOClass ", code: " bo.Binding[1] ", wild: " bo.BindOptions.wild
		this._IOClasses[bo.IOClass]._Deserialize(bo)
		this.Set(this._IOClasses[bo.IOClass], update_ini)
	}

	_RequestBinding(){
		; override base and do nothing
	}
	
	__Delete(){
		OutputDebug % "UCR| OutputButton " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		base._KillReferences()
		this.JoyMenus := []
		;~ GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
	}
}
