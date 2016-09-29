class GameBind extends _UCR.Classes.Plugin {
	Type := "GameBind Toggler"
	Description := "Makes binding outputs to game functions easier by introducing a delay"
	_DelayInGameBindMode := 0
	Init(){
		Text = 
		(LTrim
		If you cannot hide your input from a game's bind menu, then you can use GameBind to insert a delay between your input and UCR's output.
		1) Bind a Button to the `"Toggle GameBind`" input.
		If the GameBind plugin is in the Global Profile, afterwards switch to the Profile you wish to use.
		2) Go into the game's bind menu and hit the Toggle GameBind button you bound in the previous step.
		3) Move the input (press button, move axis etc) that corresponds to the output you wish to bind to the game function.
		4) Quickly enable bind mode for the function you wish to bind in the game.
		5) After the amount of time specified by the `"GameBind Delay`" Editbox, the Output will change state, and the game should bind to it.
		)
		Gui, Add, Text, xm ym, % text
		Gui, Add, Text, xm, Toggle GameBind
		this.AddControl("InputButton", "GameBind", 0, this.ToggleGameBind.Bind(this), "x+5 yp-3 w200")
		Gui, Add, Text, x+25 yp+3, GameBind Delay
		this.AddControl("Edit", "GameBindDelay", this.DelayChanged.Bind(this), "x+5 yp-3 w70", "2000")
	}
	
	DelayChanged(value){
		
	}
	
	ToggleGameBind(e){
		if (!e)
			return
		static GameBind := 0
		GameBind := !GameBind
		
		SoundBeep, 500 + (GameBind * 500)
		UCR._GameBindDuration := this.GuiControls.GameBindDelay.Get()
		UCR.SetGameBindstate(GameBind)
	}
}
