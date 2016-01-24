/*
Demos persistent guicontrols / callbacks for change of value for a guicontrol
Binds a hotkey to a snippet of AHK code
*/
class ProfileSwitcher extends _Plugin {
	Type := "Profile Switcher"
	Description := "Changes to a named profile when you hit an Input Button"
	Init(){
		Gui, Add, Text, y+10, % "When I press"
		this.AddInputButton("MyHk1", 0, this.MyHkChangedState.Bind(this), "x150 yp-2 w200")
		
		Gui, Add, Text, xm, % "Change to this profile"
		this.AddControl("MyEdit1", this.MyEditChanged.Bind(this), "Edit", "x150 yp-2 w330")
		
		Gui, Add, Button, x+5 yp-2 hwndhButton, Test
		this.hButton := hButton
		fn := this.MyHkChangedState.Bind(this, 1)
		GuiControl +g, % this.hButton, % fn
	}
	
	MyHkChangedState(e){
		; Only run the command on the down event (e=1)
		if (e){
			if !(UCR.ChangeProfile(this.GuiControls.MyEdit1.value))
				SoundBeep, 300, 200
		}
	}
	
	; In order to free memory when a plugin is closed, we must free references to this object
	_KillReferences(){
		GuiControl -g, % this.hButton
	}
		
}