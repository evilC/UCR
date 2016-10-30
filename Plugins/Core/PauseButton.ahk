class PauseButton extends _UCR.Classes.Plugin {
	Type := "PauseButton"
	Description := "One copy is always present in the global profile"

	Init(){
		Gui, Add, GroupBox, Center xm ym w140 h60 section, Input Button
		this.AddControl("InputButton", "IB1", 0, this.MyHkChangedState.Bind(this), "xs+5 ys+20")
	}
	
	MyHkChangedState(e){
		if (!e)
			return
		UCR.TogglePauseState()
	}
}