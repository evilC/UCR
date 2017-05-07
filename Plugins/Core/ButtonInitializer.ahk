/*
Sets a button to a specified state.
*/
class ButtonInitializer extends _UCR.Classes.Plugin {
	Type := "Remapper (Button Initializer)"
	Description := "Sets a button output to a specified state when the profile activates"
	; Set up the GUI to allow the user to select input and output axes
	Init(){
		Gui, Add, Text, x+3 ym, Output Button
		this.AddControl("OutputButton", "OutputButton", this.MyOutputChangedValue.Bind(this), "x+5 yp-5 w300")

		Gui, Add, Text, x+10 yp+10, State
		this.AddControl("DDL", "State", this.StateChanged.Bind(this), "x+10 yp-3 Altsubmit", "Released||Pressed|")
	}
	
	MyOutputChangedValue(value){
		this.Set()
	}
	
	OnActive(){
		this.Set()
	}
	
	StateChanged(){
		this.Set()
	}
	
	Set(){
		this.IOControls.OutputButton.Set(this.GuiControls.State.Get()-1)
	}
}
