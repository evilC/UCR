class AxisSplitter extends _UCR.Classes.Plugin {
	Type := "Remapper (Axis Splitter)"
	Description := "Splits one axis into two axes"

	Init(){
		iow := 125
		Gui, Add, GroupBox, Center xm ym w160 h110 section, Input Axis
		Gui, Add, Text, % "Center Section xs+5 ys+15 w" iow, Axis
		this.AddControl("InputAxis", "IA1", 0, this.InputChangedState.Bind(this), "xs ys+15")
		Gui, Add, Slider, % "hwndhwnd xp y+10 w" iow, 50
		this.hSliderIn := hwnd
		
		Gui, Add, GroupBox, Center x180 ym w270 h110 section, Output Axes
		Gui, Add, Text, % "Center Section xs+5 ys+15 w" iow, Low
		Gui, Add, Text, % "Center x+10 yp w" iow, High
		
		this.AddControl("OutputAxis", "OA1", 0, "xs+5 ys+15")
		this.AddControl("OutputAxis", "OA2", 0, "x+5 yp")
		
		Gui, Add, Slider, % "hwndhwnd xs+5 y+10 w" iow, 50
		this.hSliderOut1 := hwnd
		Gui, Add, Slider, % "hwndhwnd x+5 yp w" iow, 50
		this.hSliderOut2 := hwnd
	}
	
	InputChangedState(value){
		GuiControl, , % this.hSliderIn, % value
		value := UCR.Libraries.StickOps.AHKToInternal(value)
		values := [0,0]
		if (value < 0){
			value *= -1
			values[1] := UCR.Libraries.StickOps.InternalToAHK((value - 25) * 2)
			;GuiControl, , % this.hSliderIn, % value
			values[2] := 0
		} else if (value > 0){
			values[1] := 0
			values[2] := UCR.Libraries.StickOps.InternalToAHK((value - 25) * 2)
		}
		this.IOControls.OA1.Set(values[1])
		GuiControl, , % this.hSliderOut1, % values[1]
		this.IOControls.OA2.Set(values[2])
		GuiControl, , % this.hSliderOut2, % values[2]
	}
}