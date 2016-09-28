; ======================================================================== INPUT DELTA ===============================================================
; An input that reads delta move information from the mouse
class InputDelta extends _UCR.Classes.GuiControls.IOControl {
	static _ControlType := "InputDelta"
	static _DefaultBanner := "Any Mouse"
	static _IOClassNames := ["RawInput_Mouse_Delta"]
	
	__New(parent, name, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this._Ptr := &this
		this.ChangeStateCallback := ChangeStateCallback
		this.ParentPlugin := parent
		this.Name := name
		this.ID := UCR.CreateGUID()
		this.hwnd := parent.hwnd	; no gui for this input, so use hwnd of parent for unique id
		

		UCR._RegisterGuiControl(this)
		for i, name in this._IOClassNames {
			;this._IOClasses[name] := new %name%(this)
			call:= _UCR.Classes.IOClasses[name]
			this._IOClasses[name] := new call(this)

			if (!this._IOClasses.IsInitialized) {
				this._IOClasses[name]._Init()
			}
		}
		; Fake dummy BindObject for now
		this._IOClasses.RawInput_Mouse_Delta.Binding := [1]
		this._IOClasses.RawInput_Mouse_Delta.DeviceID := 1
		this.__value := this._IOClasses.RawInput_Mouse_Delta
		this._BuildMenu()
		
		this.SetControlState()
	}

	_BuildMenu(){
		for i, cls in this._IOClasses {
			cls.AddMenuItems()
		}
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
	}

	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
		;~ if (this.__value.Binding[1] || this.__value.DeviceID){
			;~ Text := this.__value.BuildHumanReadable()
		;~ } else {
			;~ Text := this._DefaultBanner
		;~ }
		;~ this.SetCueBanner(Text)
		this.SetCueBanner(this._DefaultBanner)
	}
	
	_ChangedValue(o){
		
	}
	
	; All Input controls should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		UCR._RequestBinding(this)
	}
	
	Set(value, aParams*){
		this._IOClasses.RawInput_Mouse_Delta._Deserialize(value)
		this.__value := this._IOClasses.RawInput_Mouse_Delta
		this._RequestBinding()
	}
}
