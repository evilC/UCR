; ======================================================================== INPUT DELTA ===============================================================
; An input that reads delta move information from the mouse
class InputDelta extends _UCR.Classes.GuiControls.IOControl {
	static _ControlType := "InputDelta"
	static _DefaultBanner := "Select a Mouse"
	static _IOClassNames := ["RawInput_Mouse_Delta"]
	static SeenMice := {}
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*)
	}
	
	_BuildMenu(){
		for i, cls in this._IOClasses {
			cls.AddMenuItems()
		}
		this.AddMenuItem("Any Mouse", "Any", this._ChangedValue.Bind(this, 1))
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
		
	}

	AddItem(Name,ID){
		this.AddMenuItem(Name, ID, this._ChangedValue.Bind(this, ID))
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
		if (this.__value.Binding[1] || this.__value.DeviceID){
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner
		}
		this.SetCueBanner(Text)
	}
	
	_ChangedValue(o){
		if (o == 1){
			; Fake dummy BindObject for now
			bo := {}
			bo.Binding := [1]
			bo.DeviceID := -1
			bo.IOClass := "RawInput_Mouse_Delta"
			this.SetBinding(bo)
		} else if (o == 2){
			bo := this._IOClasses.RawInput_Mouse_Delta
			bo.Binding := []
			bo.DeviceID := 0
			this.SetBinding(bo)
		} else{
			bo := {}
			bo.Binding := [o]
			bo.DeviceID := o
			bo.IOClass := "RawInput_Mouse_Delta"
			this.SetBinding(bo)
		}
	}
	
	; Override base OnStateChange, so we can update list of seen mice
	OnStateChange(e){
		try {
			base.OnStateChange(e)
			if (!ObjHasKey(this.SeenMice, e.MouseID)){
				this.SeenMice[e.MouseID] := 1
				this.AddItem(e.MouseID, e.MouseID)		
			}
		}
	}
}
