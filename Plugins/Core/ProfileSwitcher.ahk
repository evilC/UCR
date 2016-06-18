/*
Allows changing from one profile to another using a hotkey.
*/
class ProfileSwitcher extends _Plugin {
	Type := "Profile Switcher"
	Description := "Changes to a named profile when you hit an Input Button"
	Init(){
		Gui, Add, Text, y+10, % "Hotkey: "
		;~ this.AddControl("UpDown", 0, "DDL", "x+10 yp-5 w70 AltSubmit", "Release|Press||")
		this.AddInputButton("MyHk1", 0, this.MyHkChangedState.Bind(this), "x150 yp w200")
		;Gui, Add, Text, y+10, % "When I press"
		
		Gui, Add, Text, xm, % "Change to this profile on press"
		; Add Current Profile readout. It is not stored in the profile, it is rebuilt as needed
		Gui, Add, Edit, x170 yp-2 w380 hwndhCurrentProfile1 Disabled
		this.hCurrentProfile1 := hCurrentProfile1

		; Button to test profile change
		Gui, Add, Button, x+5 yp-2 hwndhTest1, Test
		this.hTest1 := hTest1
		fn := this.MyHkChangedState.Bind(this, 1)
		GuiControl +g, % this.hTest1, % fn
		
		; Button to pick a profile to change to
		Gui, Add, Button, x+5 yp hwndhSelectProfile1, Select Profile
		this.hSelectProfile1 := hSelectProfile1
		fn := this.SelectProfile.Bind(this, 1)
		GuiControl +g, % this.hSelectProfile1, % fn

		Gui, Add, Text, xm, % "Change to this profile on release"
		; Add Current Profile readout. It is not stored in the profile, it is rebuilt as needed
		Gui, Add, Edit, x170 yp-2 w380 hwndhCurrentProfile0 Disabled
		this.hCurrentProfile0 := hCurrentProfile0
		
		; Button to test profile change
		Gui, Add, Button, x+5 yp-2 hwndhTest0, Test
		this.hTest0 := hTest0
		fn := this.MyHkChangedState.Bind(this, 0)
		GuiControl +g, % this.hTest0, % fn
		
		; Button to pick a profile to change to
		Gui, Add, Button, x+5 yp hwndhSelectProfile0, Select Profile
		this.hSelectProfile0 := hSelectProfile0
		fn := this.SelectProfile.Bind(this, 0)
		GuiControl +g, % this.hSelectProfile0, % fn

		; Add hidden control to hold the Profile ID and keep it stored in INI file
		this.AddControl("ProfileID1", 0, "Edit", "x+5 yp w70 Disabled Hidden")
		this.AddControl("ProfileID0", 0, "Edit", "x+5 yp w70 Disabled Hidden")

		; Subscribe to profile tree change events, so that if the profile structure or names change, we can update
		UCR.SubscribeToProfileTreeChange(this.hwnd, this.ProfileTreeChanged.Bind(this))
	}

	; Something about the profile tree changed. Rebuild the Current Profile readout
	ProfileTreeChanged(){
		id := this.GuiControls.ProfileID1.value
		this.UpdateCurrentProfile(1, id)
		id := this.GuiControls.ProfileID0.value
		this.UpdateCurrentProfile(0, id)
	}
	
	; The user clicked the Select Profile button
	SelectProfile(state){
		UCR._ProfilePicker.PickProfile(this.ProfileChanged.Bind(this, state), this.GuiControls["ProfileID" state].value)
	}
	
	; A new selection was made in the Profile Picker
	ProfileChanged(state, id){
		OutputDebug % "UCR| state : " state
		this.UpdateCurrentProfile(state, id)
		this.GuiControls["ProfileID" state].value := id
	}
	
	; Called when the currently selected profile changes
	UpdateCurrentProfile(state, id){
		;OutputDebug % "UCR| Profile change called on plugin. old: " this.GuiControls.ProfileID.value ", new: " id
		; Update profile's list of "Linked" profiles...
		; .. these are the profiles that this profile may need to switch to quickly...
		; ... so they need to be kept in memory.
		this.ParentProfile.UpdateLinkedProfiles(this.id, this.GuiControls["ProfileID" state].value, 0)
		this.ParentProfile.UpdateLinkedProfiles(this.id, id, 1)
		; Update readout GuiControl
		GuiControl, , % this["hCurrentProfile" state], % UCR.BuildProfilePathName(id)
	}
	
	; The hotkey was pressed to change profile
	MyHkChangedState(e){
		;~ ; Only run the command on the down event (e=1)
		;~ if (e == (this.GuiControls.UpDown.value - 1) ){
			;~ if !(UCR.ChangeProfile(this.GuiControls.ProfileID.value))
				;~ SoundBeep, 300, 200
		;~ }
		if !(UCR.ChangeProfile(this.GuiControls["ProfileID" e].value))
			SoundBeep, 300, 200
	}
	
	OnDelete(){
		this.ParentProfile.UpdateLinkedProfiles(this.name, this.GuiControls.ProfileID.value, 0)
	}
	
	; In order to free memory when a plugin is closed, we must free references to this object
	_KillReferences(){
		GuiControl -g, % this.hTest0
		GuiControl -g, % this.hSelectProfile0
		GuiControl -g, % this.hTest1
		GuiControl -g, % this.hSelectProfile1
		UCR.UnSubscribeToProfileTreeChange(this.hwnd)
	}
		
}