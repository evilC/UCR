; Designed to sit right against the left or right edge of an IOControl and indicate status
class ButtonPreviewThin {
	state := -1
	__New(plugin, name, callback, control, options){
		Gui, Add, Picture, % "hwndhImage BackgroundTrans AltSubmit w3 h34 " options
		this.hImage := hImage
		this.SetState(0)
		control.PreviewControl := this
	}
	
	SetState(state){
		if (state == this.state)
			return
		GuiControl, , % this.hImage, % "Resources\icons\" (state ? "light-iocontrol-on.png" : "light-iocontrol-neutral.png")
		this.state := state
	}
}