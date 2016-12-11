class XInput_Common extends _UCR.Classes.IOClasses.IOClassBase {
	static IsInitialized := 1
	static IsAvailable := 1
	static IsAnalog := 0
	
	; Builds a human-readable form of the BindObject
	BuildHumanReadable(){
		return "Blah"
	}
	

}

class XInput_Axis extends _UCR.Classes.IOClasses.XInput_Common {
	static IOClass := "XInput_Axis"
	
	AddMenuItems(){
		Loop 4 {
			menu := this.ParentControl.AddSubMenu("XBox Controller " A_Index, "XInput" A_Index)
			b := A_Index * 10
			menu.AddMenuItem("LT", "LT", this._ChangedValue.Bind(this, b + 5))
			menu.AddMenuItem("RT", "RT", this._ChangedValue.Bind(this, b + 6))
		}
	}
	
	_ChangedValue(o){
		;~ opt := this._OptionNames[o]
		;~ this.BindOptions[opt] := !this.BindOptions[opt]

		;~ bo := this._Serialize()
		;~ bo.Delete("Binding")	; get rid of the binding, so it does not stomp on the current binding
		;~ this.ParentControl.SetBinding(bo)
	}
	
	UpdateMenus(cls){
		;OutputDebug % "UCR| Updatemenus - " this.BindOptions.block
		state := ((cls == this.IOClass) && this.ParentControl.GetBinding().Binding[1])
		for i, item in this._DisableItems {
			item.SetEnableState(state)
			this._DisableItems[i].SetCheckState(this.BindOptions[this._OptionNames[i]])
		}
	}
}