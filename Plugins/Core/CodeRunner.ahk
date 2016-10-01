/*
Demos persistent guicontrols / callbacks for change of value for a guicontrol
Binds a hotkey to a snippet of AHK code
*/
class CodeRunner extends _UCR.Classes.Plugin {
	Type := "Code Runner"
	Description := "Runs AHK code when you press an Input Button"
	Init(){
		Gui, Add, Text, y+10, % "When I press"
		this.AddControl("InputButton", "MyHk1", 0, this.MyHkChangedState.Bind(this), "x150 yp-2 w200")
		
		Gui, Add, Text, xm, % "Run this AHK code"
		this.AddControl("Edit", "MyEdit1", this.MyEditChanged.Bind(this), "x150 h100 yp-2 w330")
		
		Gui, Add, Button, xm yp+20 hwndhButton, Test Code
		this.hButton := hButton
		fn := this.MyHkChangedState.Bind(this, 1)
		GuiControl +g, % this.hButton, % fn
	}
	
	MyHkChangedState(e){
		; Only run the command on the down event (e=1)
		if (e){
			try {
				ahkExec(this.GuiControls.MyEdit1.Get())
			} catch {
				MsgBox Error
			}
		}
	}
	
	; In order to free memory when a plugin is closed, we must free references to this object
	OnClose(){
		GuiControl -g, % this.hButton
		base.OnClose()
	}
		
}