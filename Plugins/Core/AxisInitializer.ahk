/*
Holds an axis at a specified position.
Useful eg for things expecting axes to be xbox triggers.
*/
class AxisInitializer extends _Plugin {
	Type := "Remapper (Axis Initializer)"
	Description := "Sets an axis output to a specified position when the profile activates"
	vAxis := 0
	vDevice := 0
	; Set up the GUI to allow the user to select input and output axes
	Init(){
		Gui, Add, Text, x+3 ym, Output Axis
		this.AddOutputAxis("OutputAxis", this.MyOutputChangedValue.Bind(this), "x+5 yp-5 w300")

		Gui, Add, Text, x+10 yp+5, Position (0 --> 100)
		this.AddControl("Position", this.PositionChanged.Bind(this), "Edit", "x+10 yp-3 w30", "50")
	}
	
	; The user changed options - store stick and axis selected for fast retreival
	MyOutputChangedValue(value){
		;this.vAxis := value.axis
		;this.vDevice := value.DeviceID
		this.SetState()
	}
	
	OnActive(){
		this.SetState()
	}
	
	PositionChanged(){
		this.SetState()
	}
	
	SetState(){
		value := UCR.Libraries.StickOps.AHKToVjoy(this.GuiControls.Position.value)
		this.OutputAxes.OutputAxis.SetState(value)
	}
	
	/*
	; The user moved the selected input axis. Manipulate the output axis accordingly
	MyInputChangedState(value){
		GuiControl, , % this.hSliderIn, % value
		value := UCR.Libraries.StickOps.AHKToInternal(value)
		if (this.vAxis && this.vDevice){
			if (this.GuiControls.Deadzone.value){
				value := UCR.Libraries.StickOps.Deadzone(value, this.GuiControls.Deadzone.value)
			}
			if (this.GuiControls.Sensitivity.value){
				if (this.GuiControls.Linear.value)
					value *= (this.GuiControls.Sensitivity.value / 100)
				else
					value := UCR.Libraries.StickOps.Sensitivity(value, this.GuiControls.Sensitivity.value)
				
			}
			if (this.GuiControls.Invert.value){
				value := UCR.Libraries.StickOps.Invert(value)
			}
			value := UCR.Libraries.StickOps.InternalToAHK(value)
			GuiControl, , % this.hSliderOut, % value
			value := UCR.Libraries.StickOps.AHKToVjoy(value)
			this.OutputAxes.OutputAxis.SetState(value)
		}
	}
	*/
}
