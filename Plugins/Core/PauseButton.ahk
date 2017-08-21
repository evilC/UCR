class PauseButton extends _UCR.Classes.Plugin {
	Type := "PauseButton"
	Description := "Pauses / Unpauses all other inputs. Add one to the SuperGlobal profile"

	Init(){
		Gui, Add, GroupBox, Center xm ym w140 h60 section, Input Button
		this.AddControl("InputButton", "IB1", 0, this.MyHkChangedState.Bind(this), "xs+5 ys+20")
		text := "When the Input Button is pressed, all profiles (except the SuperGlobal profile) will Activate/DeActivate.`n`nWARNING! You should only use this plugin in the SuperGlobal profile`nIf you use it in any other profile, you will be able to Pause, but you will not be able to unpause."
		Gui, Add, Text, x+25 ym, % text
	}
	
	MyHkChangedState(e){
		if (!e)
			return
		new_state := UCR.TogglePauseState()
		fn := this.AsynchBeep.Bind(this, new_state)
		SetTimer, % fn, -0
	}
	
	AsynchBeep(new_state){
		if (new_state){
			SoundBeep, 500, 200
		} else {
			SoundBeep, 1000, 200
		}
	}
}