/*
Allows changing from one profile to another using a hotkey.
*/
class ProfileSwitcher extends _Plugin {
	Type := "Profile Switcher"
	Description := "Changes to a named profile when you hit an Input Button"
	Init(){
		Gui, Add, Text, y+10, % "Hotkey: "
		this.AddInputButton("MyHk1", 0, this.MyHkChangedState.Bind(this), "x150 yp w200")
		
		Gui, Add, Text, xm, % "Change to this profile on press"
		this.AddProfileSelect("Profile1", this.ProfileSelectEvent.Bind(this, 1), "x170 yp-2 w380", 0)
		
		; Button to test profile change
		Gui, Add, Button, x+5 yp-2 hwndhTest1, Test
		this.hTest1 := hTest1
		fn := this.MyHkChangedState.Bind(this, 1)
		GuiControl +g, % this.hTest1, % fn
		
		Gui, Add, Text, xm, % "Change to this profile on release"
		this.AddProfileSelect("Profile0", this.ProfileSelectEvent.Bind(this, 0), "x170 yp-2 w380", 0)		
		
		; Button to test profile change
		Gui, Add, Button, x+5 yp-2 hwndhTest0, Test
		this.hTest0 := hTest0
		fn := this.MyHkChangedState.Bind(this, 0)
		GuiControl +g, % this.hTest0, % fn
	}

	; The hotkey was pressed to change profile
	MyHkChangedState(e){
		if !(UCR.ChangeProfile(this.ProfileSelects["Profile" e].value))
			SoundBeep, 300, 200
	}
	
	OnDelete(){
		
	}
	
	; In order to free memory when a plugin is closed, we must free references to this object
	_KillReferences(){
		GuiControl -g, % this.hTest0
		GuiControl -g, % this.hTest1
	}
		
}