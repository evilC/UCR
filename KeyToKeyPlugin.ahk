class KeyToKeyPlugin extends _Plugin {
	static Type := "KeyToKeyPlugin"
	Init(){
		this.Gui("Add", "Text", "","Remap Key -> Key Plugin.`t`tName: " this.Name)
		this.Gui("Add", "Text", "y+10","Remap")
		this.AddHotkey("MyHk1", this.MyHkChangedValue.Bind(this, "MyHk1"), this.MyHkChangedState.Bind(this, "MyHk1"), "x+5 yp-2 w200")
		this.Gui("Add", "Text", "x+5 yp+2"," to ")
		this.AddOutput("MyOp1", this.MyOpChangedValue.Bind(this, "MyOp1"), "x+5 yp-2 w200")
	}
	
	MyHkChangedValue(name){
		ToolTip % Name " changed value to: " this.Hotkeys[name].value.BuildHumanReadable()
	}
	
	MyHkChangedState(Name, e){
		ToolTip % Name " changed state to: " (e ? "Down" : "Up")
		;Tooltip % this.Outputs[name].value
		this.Outputs["MyOp1"].SetState(e)
	}
	
	MyOpChangedValue(name){
		;SoundBeep
	}
}
