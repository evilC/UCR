class XInput_Common extends _UCR.Classes.IOClasses.IOClassBase {
	static IsInitialized := 1
	static IsAvailable := 1
	static IsAnalog := 0
	
	static axisNames := ["LSX", "LSY", "RSX", "RSY", "LT", "RT"]
	static buttonNames := ["A", "B", "X", "Y", "LB", "RB", "LS", "RS", "Back", "Start", "Up", "Right", "Down", "Left"]
	
}

class XInput_Axis extends _UCR.Classes.IOClasses.XInput_Common {
	static IOClass := "XInput_Axis"

	; Builds a human-readable form of the BindObject
	BuildHumanReadable(){
		return "XBox " this.DeviceID ", Axis " this.axisNames[this.Binding[1]]
	}

	AddMenuItems(){
		Loop 4 {
			menu := this.ParentControl.AddSubMenu("XBox Controller " A_Index, "XInput" A_Index)
			b := A_Index * 10
			Loop 6 {
				name := this.axisNames[A_Index]
				menu.AddMenuItem(name, name, this._ChangedValue.Bind(this, b + A_Index))
			}
		}
	}
	
	_ChangedValue(o){
		while (o > 10){
			dev++
			o -= 10
		}
		bo := {IOClass: "XInput_Axis"}
		bo.DeviceID := dev
		bo.Binding := [o]
		this.ParentControl.SetBinding(bo)
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

class XInput_Button extends _UCR.Classes.IOClasses.XInput_Common {
	static IOClass := "XInput_Button"
	static IsAnalog := 0

	BuildHumanReadable(){
		btn := this.Binding[1]
		if (btn > 10){
			return "XBox " this.DeviceID " Dpad " this.buttonNames[btn]
		} else {
			return "XBox " this.DeviceID " Button " this.buttonNames[btn]
		}
	}
	
	AddMenuItems(){
		Loop 4 {
			menu := this.ParentControl.AddSubMenu("XBox Controller " A_Index, "XInput" A_Index)
			buttons := menu.AddSubMenu("Buttons", "Buttons")
			b := A_Index * 100
			Loop 10 {
				name := this.buttonNames[A_Index]
				buttons.AddMenuItem(name, name, this._ChangedValue.Bind(this, b + A_Index))
			}
			dpad := menu.AddSubMenu("DPad", "DPad")
			Loop 4 {
				i := A_Index + 10
				name := this.buttonNames[i]
				dpad.AddMenuItem(name, name, this._ChangedValue.Bind(this, b + i))
			}
		}
	}
	
	ButtonEvent(e){
		this.ParentControl.ChangeStateCallback.Call(e)
	}
	
	_ChangedValue(o){
		while (o > 100){
			dev++
			o -= 100
		}
		bo := {IOClass: "XInput_Button"}
		bo.DeviceID := dev
		bo.Binding := [o]
		this.ParentControl.SetBinding(bo)
	}
}