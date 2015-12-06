class AxisTest extends _Plugin {
	Init(){
		;Gui, Add, Text, xm ym w500 h500, % "Axis Test"
		;this.AddAxis("MyAx1", 0, this.MyHkChangedState.Bind(this, "MyHk1"), "x+5 yp-2 w200")
		this.AddAxis("MyAx1", 0, this.MyHkChangedState.Bind(this, "MyHk1"), "")
	}
	
	MyHkChangedState(val){
		SoundBeep
	}
}