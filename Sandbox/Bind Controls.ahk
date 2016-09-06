#SingleInstance force
/*
Mock UCR + Plugin for testing and development of Input / Output GuiControls
*/

global UCR
new MockUCR()

Gui, Show
return

GuiClose:
	ExitApp


Class MockPlugin{
	__New(){
		Gui, +HwndhMain
		this.hwnd := hMain
		ib := new _InputButton(this, "TestIB", 0, 0)
		ib._Deserialize(UCR.ButtonMappings[1])		
	}
}

class MockUCR {
	; A sample keyboard mapping as it would come from the INI file
	KeyMapping := {"Block": 1,"Buttons": [{"Code": 123,"DeviceID": 0,"IsVirtual": 0,"Type": 1,"UID": ""}],"Suppress": 0,"Type": 1,"Wild": 0}
	; A sample joystick mapping as it would come from the INI file
	JoyBtnMapping := {"Block": 0, "Buttons": [{"Code": "1","DeviceID": 2,"IsVirtual": 0,"Type": 2,"UID": ""}],"Suppress": 0,"Type": 2,"Wild": 0}
	; An array to switch between the fake bindings.
	ButtonMappings := [this.KeyMapping, this.JoyBtnMapping]
	CurrentButtonMapping := 1
	
	__New(){
		UCR := this	; Set super-global at START of Ctor!
		this.plug := new MockPlugin()
	}
	
	; The user selected the "Bind" option from an Input/OutputButton GuiControl,
	;  or changed an option such as "Wild" in an InputButton
	_RequestBinding(hk, delta := 0){
		if (delta = 0){
			this.CurrentButtonMapping++
			if (this.CurrentButtonMapping > this.ButtonMappings.length()){
				this.CurrentButtonMapping := 1
			}
			bo := new _BindObject()
			bo._Deserialize(this.ButtonMappings[this.CurrentButtonMapping])
			hk.value := bo
		} else {
			; Change option (eg wild, passthrough) requested
			bo := hk.value.clone()
			for k, v in delta {
				bo[k] := v
			}
			;~ if (this._InputHandler.IsBindable(hk, bo)){
				hk.value := bo	; Triggers setter on guicontrol, which causes settings save
				;~ this._InputHandler.SetButtonBinding(hk)
			;~ }
		}
	}
	
	; By jNizM - https://autohotkey.com/boards/viewtopic.php?f=6&t=4732&p=87497#p87497
	CreateGUID(){
		VarSetCapacity(foo_guid, 16, 0)
		if !(DllCall("ole32.dll\CoCreateGuid", "Ptr", &foo_guid))
		{
			VarSetCapacity(tmp_guid, 38 * 2 + 1)
			DllCall("ole32.dll\StringFromGUID2", "Ptr", &foo_guid, "Ptr", &tmp_guid, "Int", 38 + 1)
			fin_guid := StrGet(&tmp_guid, "UTF-16")
		}
		return SubStr(fin_guid, 2, 36)
	}
}