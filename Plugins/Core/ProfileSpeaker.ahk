/*
Profile Speaker plugin - Uses Text-to-Speech to speak a string when the plugin is Activated
*/

; All plugins must derive from the _Plugin class
class ProfileSpeaker extends _UCR.Classes.Plugin {
	Type := "Profile Speaker"
	Description := "Uses Text-to-Speech to speak some text when the plugin is Activated."
	; The Init() method of a plugin is called when one is added. Use it to create your Gui etc
	Init(){
		Gui, % this.hwnd ":Add", Text, xm, % "Speech Text"
		this.AddControl("Edit", "SpeechText", 0, "x100 yp-3 w500", this.ParentProfile.Name)
	}
	
	; Called when plugin (ie profile) becomes active
	OnActive(){
		UCR.Libraries.TTS.Speak(this.GuiControls.SpeechText.Get())
	}
	
	OnInActive(){
		
	}
}
