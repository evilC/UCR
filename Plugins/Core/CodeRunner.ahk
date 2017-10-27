/*
Demos persistent guicontrols / callbacks for change of value for a guicontrol
Binds a hotkey to a snippet of AHK code
*/
class CodeRunner extends _UCR.Classes.Plugin {
	Type := "Code Runner"
	Description := "Runs AHK code when you press an Input Button"
	Init(){
		Gui, Add, Text, y+10, % "Input Button"
		this.AddControl("InputButton", "MyHk1", 0, this.MyHkChangedState.Bind(this), "x200 yp-2 w200")
		
		Gui, Add, Text, xm, % "Run this AHK code on button press"
		this.AddControl("Edit", "MyEdit1", this.MyEditChanged.Bind(this), "x200 h100 yp-2 w450")
		
		Gui, Add, Button, xm yp+20 hwndhButtonPress, Test Code
		this.hButtonPress := hButtonPress
		fn := this.MyHkChangedState.Bind(this, 1)
		GuiControl +g, % this.hButtonPress, % fn
		
		Gui, Add, Text, xm, % "Run this AHK code on button release"
		this.AddControl("Edit", "MyEdit2", this.MyEditChanged.Bind(this), "x200 h100 yp-2 w450")
		
		Gui, Add, Button, xm yp+20 hwndhButtonRelease, Test Code
		this.hButtonRelease := hButtonRelease
		fn := this.MyHkChangedState.Bind(this, 0)
		GuiControl +g, % this.hButtonRelease, % fn
	}
	
	MyHkChangedState(e){
		; Only run the command on the down event (e=1)
		try {
			if (e){
				script := this.GuiControls.MyEdit1.Get()
			} else {
				script := this.GuiControls.MyEdit2.Get()
			}
			if (script){
				ahkExec(script)
			}
		}
	}
	
	; In order to free memory when a plugin is closed, we must free references to this object
	OnClose(){
		GuiControl -g, % this.hButtonPress
		GuiControl -g, % this.hButtonRelease
		base.OnClose()
	}
		
}