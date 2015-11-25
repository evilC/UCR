/*
A sample plugin to map a digital input to a digital output
When UCR is finished, valid inputs will be:
Keyboard*, Mouse Buttons/Wheel*, Joystick Buttons, Joystick Hat directions
Modes supported (Key / Mouse only): Block, Wild, Repeat Supression
Valid outputs will be:
Keyboard, Mouse Buttons/Wheel, Virtual Joystick Buttons / Hat directions
*/

; All plugins must derive from the _Plugin class
class KeyToKeyPlugin extends _Plugin {
	; The Init() method of a plugin is called when one is added. Use it to create your Gui etc
	Init(){
		; Create the GUI
		Gui Add, Text,, % "Remap Key -> Key Plugin.`t`tName: " this.Name
		Gui, Add, Text, y+10, % "Remap"
		; Add a hotkey, and give it the name "MyHk1". All hotkey objects can be accessed via this.Hotkeys[name]
		; Have it call MyHkChangedValue when it changes value, and MyHkChangedState when it changes state.
		; Pass the name of the hotkey when it gets called
		this.AddHotkey("MyHk1", 0, this.MyHkChangedState.Bind(this, "MyHk1"), "x+5 yp-2 w200")
		Gui, Add, Text, x+5 yp+2 , % " to "
		; Add an Output, and give it the name "MyOp1". All output objects can be accessed via this.Outputs[name]
		this.AddOutput("MyOp1", 0, "x+5 yp-2 w200")
	}
	
	; Called when the hotkey changes state (key is pressed or released)
	MyHkChangedState(Name, e){
		ToolTip % Name " changed state to: " (e ? "Down" : "Up")
		;Tooltip % this.Outputs[name].value
		; Set the state of the output to match the state of the input
		this.Outputs["MyOp1"].SetState(e)
	}
}
