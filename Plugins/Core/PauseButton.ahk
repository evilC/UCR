class PauseButton extends _UCR.Classes.Plugin {
	Type := "PauseButton"
	Description := "Pauses / Unpauses all other inputs. Add one to the SuperGlobal profile"

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