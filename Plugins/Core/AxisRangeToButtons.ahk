/*
Remaps a band on a physical joystick axis to up to 10 of button outputs
*/
class AxisRangeToButtons extends _UCR.Classes.Plugin {
	Type := "Remapper (Axis Range To Buttons)"
	Description := "Maps up to 10 bands in a joystick axis input to a button output"
	LastState := 0
	
	NumBands := 10
	CurrentBand := 0
	
	BandCache := []
	
	; Set up the GUI to allow the user to select inputs and outputs
	Init(){
		iow := 125
		Gui, Add, GroupBox, Center xm ym w240 h70 section, Input Axis
		Gui, Add, Text, % "Center xs+5 yp+15 w" iow, Axis
		Gui, Add, Text, % "Center x+5 w100 ys+15", Preview
		this.AddControl("InputAxis", "InputAxis", 0, this.MyInputChangedState.Bind(this), "xs+5 yp+15")
		this.AddControl("AxisPreview", "", 0, this.IOControls.InputAxis, "x+5 yp+5 w100", 50)

		xpos := 5
		ypos := "ym"
		col_count := 0
		Loop % this.NumBands {
			mid_point := round(this.NumBands / 2)
			col_count++
			if (col_count == 1 || (col_count == mid_point + 1)){
				ypos := "y100"
			} else {
				ypos := "y+20"
			}
			
			if (col_count <= mid_point){
				xpos := "xm"
			} else {
				xpos := "x350"
			}
			
			pos_str := xpos " " ypos
			OutputDebug % "UCR| Band " A_Index " pos = " pos_str
			this.BandCache.Push({Low: "", High: ""})
			Gui, Add, Text, % "w50 " pos_str, % "Band #" A_Index
			this.AddControl("Edit", "Band" A_Index "Low", this.BandChanged.Bind(this, A_Index, "Low"), "x+5 yp-3 w25")
			Gui, Add, Text, x+5 yp+3, % " to "
			this.AddControl("Edit", "Band" A_Index "High", this.BandChanged.Bind(this, A_Index, "High"), "x+5 yp-3 w25")
			this.AddControl("OutputButton", "OB" A_Index, 0, "x+5 yp-10")
			this.AddControl("ButtonPreview", "", 0, this.IOControls["OB" A_Index], "x+5 yp+5")
		}
	}
	
	BandChanged(band, end, value){
		this.BandCache[band, end] := value
	}
	
	; The user moved the selected input axis. Manipulate the output buttons accordingly
	MyInputChangedState(value){
		in_band := 0
		Loop % this.NumBands {
			b := this.BandCache[A_Index]
			if (b.Low == "" || b.High == "")
				continue
			if (value >= b.Low && value <= b.High){
				;OutputDebug % "UCR| axis is in band: " A_Index
				in_band := A_Index
				break
			}
		}
		
		if (this.CurrentBand != in_band){
			this.IOControls["OB" this.CurrentBand].Set(0)
			if (in_band){
				this.IOControls["OB" in_band].Set(1)
			}
		}
		
		this.CurrentBand := in_band
	}
}
