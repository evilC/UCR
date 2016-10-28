/*
Holds an axis at a specified position.
Useful eg for things expecting axes to be xbox triggers.
*/
class AxisInitializer extends _UCR.Classes.Plugin {
	Type := "Remapper (Axis Initializer)"
	Description := "Sets an axis output to a specified position when the profile activates"
	vAxis := 0
	vDevice := 0
	; Set up the GUI to allow the user to select input and output axes
	Init(){
		Gui, Add, Text, x+3 ym, Output Axis
		this.AddControl("OutputAxis", "OutputAxis", this.MyOutputChangedValue.Bind(this), "x+5 yp-5 w300")

		Gui, Add, Text, x+10 yp+5, Position (0 --> 100)
		this.AddControl("Edit", "Position", this.PositionChanged.Bind(this), "x+10 yp-3 w30", "50")
	}
	
	; The user changed options - store stick and axis selected for fast retreival
	MyOutputChangedValue(value){
		;this.vAxis := value.axis
		;this.vDevice := value.DeviceID
		this.Set()
	}
	
	OnActive(){
		this.Set()
	}
	
	PositionChanged(){
		this.Set()
	}
	
	Set(){
		this.IOControls.OutputAxis.Set(this.GuiControls.Position.Get())
	}
}
