; ======================================================================== INPUT BUTTON ===============================================================
; A class the script author can instantiate to allow the user to select a hotkey.
class InputButton extends _UCR.Classes.GuiControls.IOControl {
	static _ControlType := "InputButton"
	static _IsOutput := 0
	static _BindTypes := {AHK_Common: 0, AHK_KBM_Input: "AHK_KBM_Input", AHK_JoyBtn_Input: "AHK_JoyBtn_Input", AHK_JoyHat_Input: "AHK_JoyHat_Input"}
	static _IOClassNames := ["AHK_KBM_Input", "AHK_JoyBtn_Input", "AHK_JoyHat_Input"]
	static _DefaultBanner := "Select an Input Button"
	
	; Public vars
	State := -1			; State of the input. -1 is unset. GET ONLY
	; Internal vars describing the bindstring
	__value := 0		; Holds the BindObject class
	; Other internal vars
	_IOClasses := {}
	
	
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
	
	_BuildMenu(){
		this.AddMenuItem("Select Binding", "SelectBinding", this._ChangedValue.Bind(this, 1))
		for i, cls in this._IOClasses {
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
		for i, cls in this._IOClasses {
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
				this.SetBinding(this.__value)
			}
		}
	}
}
