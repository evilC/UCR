/*
Demos persistent guicontrols / callbacks for change of value for a guicontrol
Binds a hotkey to a Run command
*/
class CommandRunner extends _Plugin {
	Init(){
		Gui, Add, Text, y+10, % "When I press"
		this.AddHotkey("MyHk1", 0, this.MyHkChangedState.Bind(this, "MyHk1"), "x150 yp-2 w200")
		Gui, Add, Text, xm, % "Run this command"
		this.AddControl("MyEdit1", this.MyEditChanged.Bind(this, "MyEdit1"), "Edit", "x150 yp-2 w330")
		;this.AddControl("MyEdit2", this.MyEditChanged.Bind(this, "MyEdit2"), "Edit", "xm w200")

	}
	
	MyHkChangedState(name, e){
		if (e)
			Run, % this.GuiControls.MyEdit1.value
	}
	
	MyEditChanged(name){
		; All GuiControls are automatically added to this.GuiControls.
		; .value holds the contents of the GuiControl
		ToolTip % Name " changed value to: " this.GuiControls[name].value
	}
}