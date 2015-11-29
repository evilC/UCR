/*
Demos persistent guicontrols / callbacks for change of value for a guicontrol
Binds a hotkey to a snippet of AHK code
*/
class CodeRunner extends _Plugin {
	Init(){
		Gui, Add, Text, y+10, % "When I press"
		this.AddHotkey("MyHk1", 0, this.MyHkChangedState.Bind(this), "x150 yp-2 w200")
		
		Gui, Add, Text, xm, % "Run this AHK code"
		this.AddControl("MyEdit1", this.MyEditChanged.Bind(this), "Edit", "x150 h100 yp-2 w330")
	}
	
	MyHkChangedState(e){
		; Only run the command on the down event (e=1)
		if (e){
			try {
				ahkExec(this.GuiControls.MyEdit1.value)
			} catch {
				MsgBox Error
			}
		}
	}
}