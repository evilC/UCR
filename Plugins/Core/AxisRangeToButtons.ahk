/*
Remaps a range on a physical joystick axis to up to 10 of button outputs
*/
class AxisRangeToButtons extends _UCR.Classes.Plugin {
	Type := "Remapper (Axis Range To Buttons)"
	Description := "Maps up to 10 ranges in a joystick axis input to a button output"
	LastState := 0
	
	NumRanges := 10
	CurrentRange := 0
	TapModeState := 0
	TapModeDur := 50
	
	RangeCache := []
	
	; Set up the GUI to allow the user to select inputs and outputs
	Init(){
		iow := 125
		Gui, Add, GroupBox, Center xm ym w240 h70 section, Input Axis
		Gui, Add, Text, % "Center xs+5 yp+15 w" iow, Axis
		Gui, Add, Text, % "Center x+5 w100 ys+15", Preview
		this.AddControl("InputAxis", "InputAxis", 0, this.MyInputChangedState.Bind(this), "xs+5 yp+15")
		this.AddControl("AxisPreview", "", 0, this.IOControls.InputAxis, "x+5 yp+5 w100", 50)
		this.AddControl("CheckBox", "TapModeState", this.TapModeChanged.Bind(this), "x+20 y40", "Tap Button for ")
		this.AddControl("Edit", "TapModeDur", this.TapModeChanged.Bind(this), "w30 x+5 yp-3", "50")
		Gui, Add, Text, % "x+5 yp+3", ms
		
		xpos := 5
		ypos := "ym"
		col_count := 0
		Loop % this.NumRanges {
			mid_point := round(this.NumRanges / 2)
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
			;OutputDebug % "UCR| Range " A_Index " pos = " pos_str
			this.RangeCache.Push({Low: "", High: ""})
			Gui, Add, Text, % "w60 " pos_str, % "Range #" A_Index
			this.AddControl("Edit", "Range" A_Index "Low", this.RangeChanged.Bind(this, A_Index, "Low"), "x+5 yp-3 w25")
			Gui, Add, Text, x+5 yp+3, % " to "
			this.AddControl("Edit", "Range" A_Index "High", this.RangeChanged.Bind(this, A_Index, "High"), "x+5 yp-3 w25")
			this.AddControl("OutputButton", "OB" A_Index, 0, "x+5 yp-10")
			this.AddControl("ButtonPreview", "", 0, this.IOControls["OB" A_Index], "x+5 yp+5")
		}
	}
	
	RangeChanged(range, end, value){
		this.RangeCache[range, end] := value
	}
	
	TapModeChanged(){
		this.TapModeState := this.GuiControls.TapModeState.Get()
		this.TapModeDur := this.GuiControls.TapModeDur.Get()
		this.IOControls["OB" this.CurrentRange].Set(!this.TapModeState)
	}
	
	; The user moved the selected input axis. Manipulate the output buttons accordingly
	MyInputChangedState(value){
		value := round(value)
		in_range := 0
		OutputDebug % "UCR| axis: " value
		Loop % this.NumRanges {
			b := this.RangeCache[A_Index]
			if (b.Low == "" || b.High == "")
				continue
			if (value >= b.Low && value <= b.High){
				;OutputDebug % "UCR| axis is in range: " A_Index
				in_range := A_Index
				break
			}
		}
		
		if (this.CurrentRange != in_range){
			if (!this.TapModeState){
				this.IOControls["OB" this.CurrentRange].Set(0)
			}
			if (in_range){
				this.IOControls["OB" in_range].Set(1)
				if (this.TapModeState){
					fn := this.ReleaseButton.Bind(this, "OB" in_range)
					SetTimer, % fn, % "-" this.TapModeDur
				}
			}
		}
		
		this.CurrentRange := in_range
	}
	
	ReleaseButton(btn){
		this.IOControls[btn].Set(0)
	}
}
