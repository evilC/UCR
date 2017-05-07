/*
Demos persistent guicontrols / callbacks for change of value for a guicontrol
Binds a hotkey to a snippet of AHK code
*/
class Notes extends _UCR.Classes.Plugin {
	Type := "Notes"
	Description := "Store notes about profile setup"
	Init(){
		Gui, Add, Text, xm, % "Notes"
		this.AddControl("Edit", "Notes", this.MyEditChanged.Bind(this), "xm h200 w650")
	}
}