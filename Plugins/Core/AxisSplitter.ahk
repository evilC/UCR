class AxisSplitter extends _UCR.Classes.Plugin {
	Type := "Remapper (Axis Splitter)"
	Description := "Splits one axis into two axes"

	Init(){
		iow := 125
		Gui, Add, GroupBox, Center xm ym w320 h140 section, Input Axis
		Gui, Add, Text, % "Center Section xs+5 ys+15 w" iow, Axis
		Gui, Add, Text, % "x+55 yp w40 Center", Deadzone

		this.AddControl("InputAxis", "IA1", 0, this.InputChangedState.Bind(this), "xs ys+15")
		this.AddControl("AxisPreview", "", 0, this.IOControls.IA1, "xp y+10 w" iow, 50)
		this.AddControl("Edit", "Deadzone", 0, "x+60 ys+15 w30", "0")
		
		Gui, Add, GroupBox, Center x360 ym w270 h140 section, Output Axes
		Gui, Add, Text, % "Center Section xs+5 ys+15 w" iow, Low
		Gui, Add, Text, % "Center x+10 yp w" iow, High
		
		this.AddControl("OutputAxis", "OA1", 0, "xs+5 ys+15")
		this.AddControl("OutputAxis", "OA2", 0, "x+5 yp")
		this.AddControl("CheckBox", "InvertL", this.InvertChanged.Bind(this, 1), "xs+5 y+10 w" iow, "Invert")
		this.AddControl("CheckBox", "InvertH", this.InvertChanged.Bind(this, 2), "x+5 yp w" iow, "Invert")
		
		this.AddControl("AxisPreview", "", 0, this.IOControls.OA1, "xs+5 y+10 w" iow, 50)
		this.AddControl("AxisPreview", "", 0, this.IOControls.OA2, "x+5 yp w" iow, 50)
		
		this.InvertState := [0,0]
	}
	
	InvertChanged(i, value){
		this.InvertState[i] := value
		this.InputChangedState(this.IOControls.IA1.Get())
	}
	
	InputChangedState(value){
		value := UCR.Libraries.StickOps.AHKToInternal(value)
		values := [0,0]
		if (this.GuiControls.Deadzone.Get()){
			value := UCR.Libraries.StickOps.Deadzone(value, this.GuiControls.Deadzone.Get())
		}
		if (value < 0){
			thisAxis := 1
			otherAxis := 2
			value *= -1
		} else if (value > 0) {
			thisAxis := 2
			otherAxis := 1
		}
		values[thisAxis] := (value - 25) * 2
		values[otherAxis] := -50
		if (this.InvertState[thisAxis]){
			values[thisAxis] *= -1
		}
		if (this.InvertState[otherAxis]){
			values[otherAxis] *= -1
		}
		values[thisAxis] := UCR.Libraries.StickOps.InternalToAHK(values[thisAxis])
		values[otherAxis] := UCR.Libraries.StickOps.InternalToAHK(values[otherAxis])
		
		this.IOControls.OA1.Set(values[1])
		this.IOControls.OA2.Set(values[2])
	}
}