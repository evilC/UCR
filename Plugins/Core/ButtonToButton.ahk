/*
A sample plugin to map a digital input to a digital output
When UCR is finished, valid inputs will be:
Keyboard*, Mouse Buttons/Wheel*, Joystick Buttons, Joystick Hat directions
Modes supported (Key / Mouse only): Block, Wild, Repeat Supression
Valid outputs will be:
Keyboard, Mouse Buttons/Wheel, Virtual Joystick Buttons / Hat directions
*/

; All plugins must derive from the _Plugin class
class ButtonToButton extends _UCR.Classes.Plugin {
	Type := "Remapper (Button To Button)"
	Description := "Remaps button type inputs (Keys, Mouse buttons, Joystick buttons + hat directions)"
	; The Init() method of a plugin is called when one is added. Use it to create your Gui etc
	Init(){
		; Create the GUI
		Gui, Add, GroupBox, Center xm ym w170 h60 section, Input Button
		this.AddControl("InputButton", "IB1", 0, this.MyHkChangedState.Bind(this), "xs+5 ys+20")
		this.AddControl("ButtonPreview", "", 0, this.IOControls.IB1, "x+5 yp+5")
		;Gui, Add, Text, y+10, % "Remap"
		Gui, Add, GroupBox, Center x190 ym w170 h60 section, Output Button
		this.AddControl("OutputButton", "OB1", 0, "xs+5 ys+20")
		this.AddControl("ButtonPreview", "", 0, this.IOControls.OB1, "x+5 yp+5")
		
		Gui, Add, GroupBox, Center x370 ym w100 h60 section, Settings
		this.AddControl("Checkbox", "Toggle", 0, "xs+10 yp+30", "Toggle mode")
	}
	
	; Called when the hotkey changes state (key is pressed or released)
	MyHkChangedState(e){
		;OutputDebug, % "UCR| Plugin" this.Name " changed state to: " (e ? "Down" : "Up")
		if (this.GuiControls.Toggle.Get()){
			; Toggle mode - Toggle the state of the output when the input goes down
			if (e){
				this.IOControls.OB1.Set(!this.IOControls.OB1.Get())
			}
		} else {
			; Normal mode - Set the state of the output to match the state of the input
			this.IOControls.OB1.Set(e)
		}
	}
}
