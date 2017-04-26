/*
Merges two physical axes into one virtual axis
Requires the StickOps library and the vJoy library
*/
class AxisMerger extends _UCR.Classes.Plugin {
	Type := "Remapper (Axis Merger)"
	Description := "Merges two input axes into one output virtual axis"
	vAxis := 0
	vDevice := 0
	; Set up the GUI to allow the user to select input and output axes
	Init(){
		Gui, Add, Text, % "xm w125 Center", Input Axis 1
		Gui, Add, Text, % "x+5 w125 Center", Input Axis 2
		this.AddControl("InputAxis", "InputAxis1", 0, this.MyInputChangedState.Bind(this), "xm w125")
		this.AddControl("InputAxis", "InputAxis2", 0, this.MyInputChangedState.Bind(this), "Section x+5 w125")
		
		Gui, Add, Text, % "xm w125 Center", Input 1 Preview
		Gui, Add, Text, % "x+5 yp w125 Center", Input 2 Preview
		this.AddControl("AxisPreview", "", 0, this.IOControls.InputAxis1, "xm w125", 50)
		this.AddControl("AxisPreview", "", 0, this.IOControls.InputAxis2, "x+5 yp w125", 50)
		Gui, Add, Text, % "x50", Invert
		this.AddControl("CheckBox", "Invert1", this.MyEditChanged.Bind(this), "x+5 yp")
		
		Gui, Add, Text, % "x180 yp", Invert
		this.AddControl("CheckBox", "Invert2", this.MyEditChanged.Bind(this), "x+5 yp")
		
		Gui, Add, Text, % "x270 y40 w70 Center", Mode
		Gui, Add, Text, % "x+5 y40 w50 Center", Deadzone
		Gui, Add, Text, % "x+5 yp w50 Center", Sensitivity
		Gui, Add, Text, % "x+0 yp w125 Center", Output Virtual Axis
		Gui, Add, Text, % "x+5 yp w100 Center", Output Preview
		
		this.AddControl("DDL", "MergeMode", this.MyEditChanged.Bind(this), "x270 yp+20 w70 AltSubmit", "Average||Greatest||Sum")
		this.AddControl("Edit", "Deadzone", this.MyEditChanged.Bind(this), "x+15 yp w30", "0")
		Gui, Add, Text, % "x+0 yp+3", `%
		this.AddControl("Edit", "Sensitivity", this.MyEditChanged.Bind(this), "x+15 yp-3 w30", "100")
		Gui, Add, Text, % "x+0 yp+3", `%
		this.AddControl("OutputAxis", "OutputAxis", this.MyOutputChangedValue.Bind(this), "x+5 yp-3 w125")
		this.AddControl("AxisPreview", "", 0, this.IOControls.OutputAxis, " x+5 yp w100", 50)
	}
	
	; The user changed options - store stick and axis selected for fast retreival
	MyOutputChangedValue(value){
		this.vAxis := value.Binding[1]
		this.vDevice := value.DeviceID
	}
	
	; The user moved the selected input axis. Manipulate the output axis accordingly
	MyInputChangedState(value){
		outval := 0
		value1 := UCR.Libraries.StickOps.AHKToInternal(this.IOControls.InputAxis1.Get())
		value2 := UCR.Libraries.StickOps.AHKToInternal(this.IOControls.InputAxis2.Get())
		
		; Apply input axis inversions
		if (this.GuiControls.Invert1.Get())
			value1 := UCR.Libraries.StickOps.Invert(value1)
		if (this.GuiControls.Invert2.Get())
			value2 := UCR.Libraries.StickOps.Invert(value2)
		
		; Do the merge
		if (this.GuiControls.MergeMode.Get() = 1){
			; Average
			outval := (value1 + value2) / 2
		} else if (this.GuiControls.MergeMode.Get() = 2){
			; Greatest
			v1 := value1 - 50, v2 := value2 + 50, a1 := abs(v1), a2 := abs(v2)
			if (a1 == a2)
				outval := 0
			else if (a1 > a2)
				outval := v1 / 2
			else
				outval := v2 / 2
		} else if (this.GuiControls.MergeMode.Get() = 3){
			; Sum
			outval := value1 + value2
		}
		; Set the output axis
		if (this.vAxis && this.vDevice){
			; Apply Deadzone / Sensitivity
			if (this.GuiControls.Deadzone.Get())
				outval := UCR.Libraries.StickOps.Deadzone(outval, this.GuiControls.Deadzone.Get())
			if (this.GuiControls.Sensitivity.Get())
				outval := UCR.Libraries.StickOps.Sensitivity(outval, this.GuiControls.Sensitivity.Get())
			outval := UCR.Libraries.StickOps.InternalToAHK(outval)
			this.IOControls.OutputAxis.Set(outval)
		}
	}
}
