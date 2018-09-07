; ======================================================================== INPUT AXIS ===============================================================
class InputAxis extends _UCR.Classes.GuiControls.IOControl {
	static _ControlType := "InputAxis"
	static _IOClassNames := ["AHK_JoyAxis_Input", "XInput_Axis"]
	static _Text := "Input"
	
	__Delete(){
		OutputDebug % "UCR| " this._Text "Axis " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	_BuildMenu(){
		this.__BuildMenu()
		this.AddMenuItem("Clear", "Clear", this._ChangedValue.Bind(this, 2))
	}
	
	_ChangedValue(o){
		if (o == 2){
			this.SetBinding(0)
		}
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetControlState(){
		if (this.IsBound()){
			this.SetCueBanner(this.__value.BuildHumanReadable())
		} else {
			this.SetCueBanner("Select an " this._Text " Axis")
		}
		for i, cls in this._IOClasses {
			cls.UpdateMenus(this.__value.IOClass)
		}
	}
}
