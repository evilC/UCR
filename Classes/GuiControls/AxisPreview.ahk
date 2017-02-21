class AxisPreview {
	__New(plugin, name, callback, control, options, state){
		Gui, Add, Slider, % "hwndhwnd " options, % state
		this.hwnd := hwnd
		control.PreviewControl := this
	}
	
	SetState(state){
		GuiControl, , % this.hwnd, % state
	}
}