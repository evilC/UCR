; ======================================================================== INPUT BUTTON ===============================================================
; A class the script author can instantiate to allow the user to select a hotkey.
class InputButton extends _UCR.Classes.GuiControls.IOControl {
	static _ControlType := "InputButton"
	static _BindModeMappings := {AHK_Common: 0, AHK_KBM_Input: "AHK_KBM_Input", AHK_JoyBtn_Input: "AHK_JoyBtn_Input", AHK_JoyHat_Input: "AHK_JoyHat_Input"}
	static _IOClassNames := ["AHK_KBM_Input", "AHK_JoyBtn_Input", "AHK_JoyHat_Input", "XInput_Button"]
	static _DefaultBanner := "Select an Input Button"
	
	
	__Delete(){
		OutputDebug % "UCR| InputButton " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	OnClose(remove_binding := 1){
		base.OnClose(remove_binding)
		this._KeyOnlyOptions := ""
	}
	
	_BuildMenu(){
		; Bind mode is used for AHK_KBM_Input, AHK_JoyBtn_Input and AHK_JoyHat_Input, so handle the menu here
		this.AddMenuItem("Select Binding", "SelectBinding", this._ChangedValue.Bind(this, 1))
		this.__BuildMenu()
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
		if (this.IsBound()){
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner
		}
		this.SetCueBanner(Text)
		; Update the Menus etc of all the IOClasses in this control
		for i, cls in this._IOClasses {
			cls.UpdateMenus(this.GetBinding().IOClass)
		}
	}
	
	; An option was selected from one of the Menus that this class controls
	; Menus in this GUIControl may be handled in an IOClass
	_ChangedValue(o){
		if (o){
			; Option selected from list
			if (o = 1){
				; Bind
				UCR.RequestBindMode(this._BindModeMappings, this._BindModeEnded.Bind(this))
				return
			} else if (o == 2){
				this.SetBinding(0)
			}
		}
	}
}
