class GameBind extends _Plugin {
	_DelayInGameBindMode := 0
	Init(){
		Gui, Add, Text, xm ym, Toggle GameBind
		this.AddInputButton("GameBind", 0, this.ToggleGameBind.Bind(this), "x+5 yp-3 w200")
		Gui, Add, Text, x+25 yp+3, GameBind Delay
		this.AddControl("GameBindDelay", this.DelayChanged.Bind(this), "Edit", "x+5 yp-3 w70", "2000")
	}
	
	DelayChanged(value){
		
	}
	
	ToggleGameBind(e){
		if (!e)
			return
		static GameBind := 0
		GameBind := !GameBind
		
		SoundBeep, 500 + (GameBind * 500)
		UCR._GameBindDuration := this.GuiControls.GameBindDelay.value
		UCR.SetGameBindstate(GameBind)
	}
}
