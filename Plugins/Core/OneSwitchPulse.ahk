/*
A special profile switcher intended for use by disabled people
Allows switching of profiles with only one button.
Will keep showing a menu until you hit a profile with no child profiles.
Will then listen for activity and return to the parent profile...
...if there is none for a given amount of time.

*/

; All plugins must derive from the _Plugin class
class OneSwitchPulse extends _Plugin {
	Type := "OneSwitch Pulse"
	Description := "Profile switcher for use by disabled OneSwitch users. Add to Global profile"
	; The Init() method of a plugin is called when one is added. Use it to create your Gui etc
	Init(){
		; Create the GUI
		Gui, Add, Text, xm y+10, % "Toggle On/Off"
		this.AddInputButton("Toggle", 0, this.Toggle.Bind(this), "x100 yp-2 w200")
		
		Gui, Add, Text, xm y+10, % "Choice"
		this.AddInputButton("Choice1", 0, this.ChoiceChangedState.Bind(this), "x100 yp-2 w200")
		
		Gui, Add, Text, xm y+10, % "Pulse Rate (ms)"
		this.AddControl("PulseRate", 0, "Edit", "x100 yp-2 w40", 500)
		
		Gui, Add, Text, xm y+10, % "Timeout (ms)"
		this.AddControl("TimeOut", 0, "Edit", "x100 yp-2 w40", 5000)
		
		this.PulseFn := this.Pulse.Bind(this)
		
		;~ fn := this.SetPulseState.Bind(this, 0)
		;~ SetTimer,  % fn, -0
		
		this.CurrentSelection := 0
		this.CurrentProfile := 0

		Gui, New, HwndhMenu
		this.hMenu := hMenu
		gui, font, s100
		Gui, Color, EEAA99
		Gui +LastFound +AlwaysOnTop -Caption
		WinSet, TransColor, EEAA99
		Gui, Add, Text, w600 hwndhMenuItem Center
		this.hMenuItem := hMenuItem
		Gui, % this.hMenu ":Show"
	}
	
	ResetTimeOut(){
		this.TimeOut := A_TickCount + this.GuiControls.TimeOut.Value
	}
	
	Pulse(){
		OutputDebug % "Pulse "

		ucr_id := UCR.CurrentProfile.id
		if (this.CurrentProfile != ucr_id){
			this.CurrentProfile := ucr_id
			this.CurrentSelection := 0
			this.SelectedProfile := 0
			this.SetMenuText("")
			this.ResetTimeOut()
		}
		if (A_TickCount > this.TimeOut){
			if (UCR.CurrentProfile.ParentProfile != 0){
				UCR.ChangeProfile(UCR.CurrentProfile.ParentProfile)
				this.CurrentSelection := 0
				return
			} else {
				this.ResetTimeOut()
			}
		}
		node := UCR.ProfileTree[ucr_id]
		if (!node.length()){
			this.SetMenuText("")
			this.CurrentSelection := 0
			return
		}

		if (!this.CurrentSelection){
			this.CurrentSelection := 1
		} else {
			this.CurrentSelection++
			if (this.CurrentSelection > node.length()){
				this.CurrentSelection := 1
			}
		}
		
		this.SelectedProfile := node[this.CurrentSelection]
		OutputDebug % "Pulse - node found : " UCR.Profiles[this.SelectedProfile].Name
		this.SetMenuText(UCR.Profiles[this.SelectedProfile].Name)

	}
	
	SetMenuText(text){
		GuiControl, , % this.hMenuItem, % text
	}
	
	; Called when the hotkey changes state (key is pressed or released)
	ChoiceChangedState(e){
		OutputDebug, % "Choice changed state to: " (e ? "Down" : "Up")
		if (e){
			; Ignore the choice button if we are not in a menu
			if (this.CurrentSelection){
				UCR.ChangeProfile(this.SelectedProfile)
				;UCR.Profiles[node[this.CurrentSelection]]
				this.SelectedProfile := 0
			}
			;this.ResetTimeOut()
		}
	}

	OnActive(){
		;this.SetPulseState(0)
		UCR.SubscribeToInputActivity(this.hwnd, this.ResetTimeOut.Bind(this))
	}
	
	OnInActive(){
		this.SetPulseState(0)
		UCR.UnSubscribeToInputActivity(this.hwnd)
	}
	
	Toggle(e){
		if (e){
			this.SetPulseState(!this.Pulsing)
		}
	}
	
	SetPulseState(state){
		this.Pulsing := state
		fn := this.PulseFn
		if (state){
			Gui, % this.hMenu ":Show"
			this.SetMenuText("")
			SetTimer, % fn, % this.GuiControls.PulseRate.Value
			SoundBeep, 1000, 250
		} else {
			Gui, % this.hMenu ":Hide"
		
			SetTimer, % fn, Off
			SoundBeep, 500, 250
		}
	}
		
}
