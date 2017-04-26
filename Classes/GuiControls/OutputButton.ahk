; ======================================================================== OUTPUT BUTTON ===============================================================
; An Output allows the end user to specify which buttons to press as part of a plugin's functionality
Class OutputButton extends _UCR.Classes.GuiControls.InputButton {
	static _ControlType := "OutputButton"
	static _DefaultBanner := "Select an Output Button"
	static _BindModeMappings := {AHK_Common: 0, AHK_KBM_Input: "AHK_KBM_Output"}
	static _IOClassNames := ["AHK_KBM_Output", "vJoy_Stick", "vJoy_Button_Output", "vJoy_Hat_Output", "vXBox_Stick", "vXBox_Button_Output", "vXBox_Hat_Output", "TitanOne_Button_Output", "TitanOne_Hat_Output"]

	State := 0
	JoyMenus := []
	
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
		; Create Select vJoy Button / Hat Select GUI
	}
	
	_BuildMenu(){
		this.AddMenuItem("Select Keyboard / Mouse Binding...", "AHK_KBM_Output", this._ChangedValue.Bind(this, 1))
		this.__BuildMenu()
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
	}
	
	; Used by script authors to set the state of this output
	Set(state, delay_done := 0){
		static PovMap := {0: {x:0, y:0}, 1: {x: 0, y: 1}, 2: {x: 1, y: 0}, 3: {x: 0, y: 2}, 4: {x: 2, y: 0}}
		static PovAngles := {0: {0:-1, 1:0, 2:18000}, 1:{0:9000, 1:4500, 2:13500}, 2:{0:27000, 1:31500, 2:22500}}
		static Axes := ["x", "y"]
		if (UCR._CurrentState == 2 && !delay_done){
			fn := this.Set.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.__value.Set(state)
			this.State := state
		}
		this.OnStateChange(state)
	}
	
	; An option was selected from one of the Menus that this class controls
	; Menus in this GUIControl may be handled in an IOClass
	_ChangedValue(o){
		if (o){
			if (o = 1){
				; Bind
				;UCR._RequestBinding(this)
				UCR.RequestBindMode(this._BindModeMappings, this._BindModeEnded.Bind(this)) ;*[UCR]
				return
			} else if (o = 2){
				; Clear Binding
				this.SetBinding(0)
			}
		}
	}
	
	__Delete(){
		OutputDebug % "UCR| OutputButton " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	OnClose(){
		base.OnClose()
		this.JoyMenus := []
		;~ GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
	}
}
