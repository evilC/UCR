#SingleInstance force

global UCR
new UCR()

; Set up the test mappings system that feeds the GuiControls with sample mappings to simulate Bind Mode
; A sample keyboard mapping as it would come from the INI file
KeyMapping := {"Block": 0,"Buttons": [{"Code": 123,"DeviceID": 0,"IsVirtual": 0,"Type": 1,"UID": ""}],"Suppress": 0,"Type": 1,"Wild": 0}
; A sample input joystick mapping as it would come from the INI file
InputJoyBtnMapping := {"Block": 0, "Buttons": [{"Code": "1","DeviceID": 2,"IsVirtual": 0,"Type": 2,"UID": ""}],"Suppress": 0,"Type": 2,"Wild": 0}
UCR.AddTestMappings({TestIB: [KeyMapping, InputJoyBtnMapping], TestOB: [KeyMapping]})

; Add a Mock Plugin
UCR.plug := new MockPlugin()

; Show the Mock GUI
Gui, Show, x0 y0, Bind Control Sandbox
return

GuiClose:
	ExitApp

; Mock Plugin that adds mock GuiControls
Class MockPlugin extends _UCRBase {
	__New(){
		Gui, +HwndhMain
		this.hwnd := hMain
		ib := new _InputButton(this, "TestIB", 0, 0, "w300")
		
		ob := new _OutputButton(this, "TestOB", 0, "w300")
		
		ia := new _InputAxis(this, "TestIA", 0, 0, "w300")
		
		oa := new _OutputAxis(this, "TestIA", 0, "w300")
		
		ps := new _ProfileSelect(this, "TestPS", 0, "w300")
	}
}

; Mock UCR - handles binding requests etc
#include MockUCR.ahk

; The new menu system
#include Menu.ahk

; Normal UCR classes that are needed
#include ..\Classes\GuiControls\BindObject.ahk
#include ..\Classes\Button.ahk
#include ..\Classes\Axis.ahk

; Classes that are being worked on
#include ..\Classes\GuiControls\BannerMenu.ahk
#include ..\Classes\GuiControls\InputButton.ahk
#include ..\Classes\GuiControls\OutputButton.ahk
#include ..\Classes\GuiControls\InputAxis.ahk
#include ..\Classes\GuiControls\OutputAxis.ahk
#include ..\Classes\GuiControls\ProfileSelect.ahk
