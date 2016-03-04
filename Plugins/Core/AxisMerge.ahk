/*
Merges two physical axes into one virtual axis
Requires the StickOps library and the vJoy library
*/
class AxisMerge extends _Plugin {
	Type := "Remapper (Axis Merger)"
	Description := "Merges two input axes into one output virtual axis"
	vAxis := 0
	vDevice := 0
	; Set up the GUI to allow the user to select input and output axes
	Init(){
		Gui, Add, Text, % "xm w125 Center", Input Axis 1
		Gui, Add, Text, % "x+5 w125 Center", Input Axis 2
		this.AddInputAxis("InputAxis1", 0, this.MyInputChangedState.Bind(this), "xm w125")
		this.AddInputAxis("InputAxis2", 0, this.MyInputChangedState.Bind(this), "Section x+5 w125")
		
		Gui, Add, Text, % "xm w125 Center", Input 1 Preview
		Gui, Add, Text, % "x+5 yp w125 Center", Input 2 Preview
		Gui, Add, Slider, % "hwndhwnd xm w125"
		this.hSliderIn1 := hwnd
		Gui, Add, Slider, % "hwndhwnd x+5 yp w125"
		this.hSliderIn2 := hwnd
		Gui, Add, Text, % "x50", Invert
		this.AddControl("Invert1", this.MyEditChanged.Bind(this), "CheckBox", "x+5 yp")
		
		Gui, Add, Text, % "x180 yp", Invert
		this.AddControl("Invert2", this.MyEditChanged.Bind(this), "CheckBox", "x+5 yp")
		
		Gui, Add, Text, % "x270 y40 w70 Center", Mode
		Gui, Add, Text, % "x+5 y40 w50 Center", Deadzone
		Gui, Add, Text, % "x+5 yp w50 Center", Sensitivity
		Gui, Add, Text, % "x+0 yp w125 Center", Output Virtual Axis
		Gui, Add, Text, % "x+5 yp w100 Center", Output Preview
		
		this.AddControl("MergeMode", this.MyEditChanged.Bind(this), "DDL", "x270 yp+20 w70 AltSubmit", "Average||Greatest")
		this.AddControl("Deadzone", this.MyEditChanged.Bind(this), "Edit", "x+15 yp w30", "0")
		Gui, Add, Text, % "x+0 yp+3", `%
		this.AddControl("Sensitivity", this.MyEditChanged.Bind(this), "Edit", "x+15 yp-3 w30", "100")
		Gui, Add, Text, % "x+0 yp+3", `%
		this.AddOutputAxis("OutputAxis", this.MyOutputChangedValue.Bind(this), "x+5 yp-3 w125")
		Gui, Add, Slider, % "hwndhwnd x+5 yp w100"
		this.hSliderOut := hwnd
	}
	
	; The user changed options - store stick and axis selected for fast retreival
	MyOutputChangedValue(value){
		this.vAxis := value.axis
		this.vDevice := value.DeviceID
		this.OutAxis := this.OutputAxes.OutputAxis
	}
	
	; The user moved the selected input axis. Manipulate the output axis accordingly
	MyInputChangedState(value){
		static StickOps := UCR.Libraries.StickOps

		outval := 0
		value1 := StickOps.AHKToInternal(this.InputAxes.InputAxis1.State)
		value2 := StickOps.AHKToInternal(this.InputAxes.InputAxis2.State)
		
		; Apply input axis inversions
		if (this.GuiControls.Invert1.value)
			value1 := StickOps.Invert(value1)
		if (this.GuiControls.Invert2.value)
			value2 := StickOps.Invert(value2)
		
		; Do the merge
		if (this.GuiControls.MergeMode.value = 1){
			; Average
			outval := (value1 + value2) / 2
		} else if (this.GuiControls.MergeMode.value = 2){
			; Greatest
			v1 := value1 - 50, v2 := value2 + 50, a1 := abs(v1), a2 := abs(v2)
			if (a1 == a2)
				outval := 0
			else if (a1 > a2)
				outval := v1 / 2
			else
				outval := v2 / 2
		}
		
		; Set the output axis
		if (this.vAxis && this.vDevice){
			; Apply Deadzone / Sensitivity
			if (this.GuiControls.Deadzone.value)
				outval := StickOps.Deadzone(outval, this.GuiControls.Deadzone.value)
			if (this.GuiControls.Sensitivity.value)
				outval := StickOps.Sensitivity(outval, this.GuiControls.Sensitivity.value)
			outval := StickOps.InternalToAHK(outval)
			GuiControl, , % this.hSliderOut, % outval
			outval := StickOps.AHKToVjoy(outval)
			this.OutAxis.SetState(outval)
		}
		GuiControl, , % this.hSliderIn1, % StickOps.InternalToAHK(value1)
		GuiControl, , % this.hSliderIn2, % StickOps.InternalToAHK(value2)
	}
}
