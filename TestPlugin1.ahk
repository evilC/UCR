class TestPlugin1 extends _Plugin {
	static Type := "TestPlugin1"
	Init(){
		hClose:=this.Gui("Add", "Button", "", "Close")
		this.GuiControl("+g", hClose, this.Close.Bind(this))
		this.Gui("Add", "Text", "xm", "Name: " this.Name "`t`tType: " this.Type)
		this.Gui("Add", "Text", "xm", "Send the following text")
		this.AddControl("MyEdit1", this.MyEditChanged.Bind(this, "MyEdit1"), "Edit", "x150 h400 yp-2 w330")
		;this.AddControl("MyEdit2", this.MyEditChanged.Bind(this, "MyEdit2"), "Edit", "xm w200")

	}
	
	Close(){
		Loop {
			ToolTip % A_TickCount
			Sleep 100
		}
		this.ParentProfile._RemovePlugin(this)
	}
	
	MyEditChanged(name){
		; All GuiControls are automatically added to this.GuiControls.
		; .value holds the contents of the GuiControl
		ToolTip % Name " changed value to: " this.GuiControls[name].value
	}
}