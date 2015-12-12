class AxisTest extends _Plugin {
	; The Init() method of a plugin is called when one is added. Use it to create your Gui etc
	Init(){
		this.AddAxisInput("MyAx1", 0, this.MyAxisChangedState.Bind(this))
		Gui, Add, Slider, % "hwndhwnd x+5 yp"
		this.hSlider := hwnd
		this.myStick := UCR.Libraries.vJoy.Devices[1]
	}
	
	MyAxisChangedState(value){
		OutputDebug % "Plugin " value
		GuiControl, , % this.hSlider, % value
		this.myStick.SetAxisByIndex(UCR.Libraries.vJoy.PercentTovJoy(value),1)
	}
}