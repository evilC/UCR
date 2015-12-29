/*
A sample plugin to map a digital input to a digital output
When UCR is finished, valid inputs will be:
Keyboard*, Mouse Buttons/Wheel*, Joystick Buttons, Joystick Hat directions
Modes supported (Key / Mouse only): Block, Wild, Repeat Supression
Valid outputs will be:
Keyboard, Mouse Buttons/Wheel, Virtual Joystick Buttons / Hat directions
*/

; All plugins must derive from the _Plugin class
class ButtonToButton extends _Plugin {
	Type := "Remapper (Button To Button)"
	Description := "Remaps button type inputs (Keys, Mouse buttons, Joystick buttons + hat directions)"
	; The Init() method of a plugin is called when one is added. Use it to create your Gui etc
	Init(){
		; Create the GUI
		Gui, Add, Text, y+10, % "Remap"
		; Add a hotkey, and give it the name "MyHk1". All hotkey objects can be accessed via this.InputButtons[name]
		; Have it call MyHkChangedValue when it changes value, and MyHkChangedState when it changes state.
		; Pass the name of the hotkey when it gets called
		this.AddInputButton("IB1", 0, this.MyHkChangedState.Bind(this, "IB1"), "x+5 yp-2 w200")
		Gui, Add, Text, x+5 yp+2 , % " to "
		; Add an Output, and give it the name "MyOp1". All output objects can be accessed via this.OutputButtons[name]
		this.AddOutputButton("OB1", 0, "x+5 yp-2 w200")
	}
	
	; Called when the hotkey changes state (key is pressed or released)
	MyHkChangedState(Name, e){
		OutputDebug, % Name " changed state to: " (e ? "Down" : "Up")
		;Tooltip % this.OutputButtons[name].value
		; Set the state of the output to match the state of the input
		this.OutputButtons.OB1.SetState(e)
	}
}
