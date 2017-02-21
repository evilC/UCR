class ButtonPreview {
	state := -1
	__New(plugin, name, callback, control, options){
		Gui, Add, Picture, % "hwndhImage BackgroundTrans AltSubmit w25 h25 " options
		this.hImage := hImage
		this.SetState(0)
		control.PreviewControl := this
	}
	
	SetState(state){
		if (state == this.state)
			return
		GuiControl, , % this.hImage, % "Resources\icons\" (state ? "light-on.png" : "light-neutral.png")
		this.state := state
	}
}