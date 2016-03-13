/*
Allows changing from one profile to another using a hotkey.
*/
class ProfileSwitcher extends _Plugin {
	Type := "Profile Switcher"
	Description := "Changes to a named profile when you hit an Input Button"
	Init(){
		Gui, Add, Text, y+10, % "When I press"
		this.AddInputButton("MyHk1", 0, this.MyHkChangedState.Bind(this), "x150 yp-2 w200")
		
		Gui, Add, Text, xm, % "Change to this profile"
		; Add Current Profile readout. It is not stored in the profile, it is rebuilt as needed
		Gui, Add, Edit, x150 yp-2 w400 hwndhCurrentProfile Disabled
		this.hCurrentProfile := hCurrentProfile
		
		; Button to test profile change
		Gui, Add, Button, x+5 yp-2 hwndhTest, Test
		this.hTest := hTest
		fn := this.MyHkChangedState.Bind(this, 1)
		GuiControl +g, % this.hTest, % fn
		
		; Button to pick a profile to change to
		Gui, Add, Button, x+5 yp hwndhSelectProfile, Select Profile
		this.hSelectProfile := hSelectProfile
		fn := this.SelectProfile.Bind(this)
		GuiControl +g, % this.hSelectProfile, % fn

		; Add hidden control to hold the Profile ID and keep it stored in INI file
		this.AddControl("ProfileID", 0, "Edit", "x+5 yp w70 Disabled Hidden")

		; Subscribe to profile tree change events, so that if the profile structure or names change, we can update
		UCR.SubscribeToProfileTreeChange(this.hwnd, this.ProfileTreeChanged.Bind(this))
	}

	; Something about the profile tree changed. Rebuild the Current Profile readout
	ProfileTreeChanged(){
		id := this.GuiControls.ProfileID.value
		this.UpdateCurrentProfile(id)
	}
	
	; The user clicked the Select Profile button
	SelectProfile(){
		UCR._ProfilePicker.PickProfile(this.ProfileChanged.Bind(this), this.GuiControls.ProfileID.value)
	}
	
	; A new selection was made in the Profile Picker
	ProfileChanged(id){
		this.UpdateCurrentProfile(id)
		this.GuiControls.ProfileID.value := id
	}
	
	; Updates the GuiControl that displays the current profile
	UpdateCurrentProfile(id){
		GuiControl, , % this.hCurrentProfile, % UCR.BuildProfilePathName(id)
		;GuiControl, , % this.GuiControls.ProfileID.hwnd, % id
	}
	
	; The hotkey was pressed to change profile
	MyHkChangedState(e){
		; Only run the command on the down event (e=1)
		if (e){
			if !(UCR.ChangeProfile(this.GuiControls.ProfileID.value))
				SoundBeep, 300, 200
		}
	}
	
	; In order to free memory when a plugin is closed, we must free references to this object
	_KillReferences(){
		GuiControl -g, % this.hTest
		GuiControl -g, % this.hSelectProfile
		UCR.UnSubscribeToProfileTreeChange(this.hwnd)
	}
		
}