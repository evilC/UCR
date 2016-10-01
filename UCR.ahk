/*
	UCR Main bootstrap file
	
	The recommended editor for UCR is AHK Studio
	https://autohotkey.com/boards/viewtopic.php?t=300
*/
#SingleInstance force

OutputDebug DBGVIEWCLEAR
SetBatchLines, -1
global UCR	; set UCR as a super-global NOW so that it is super-global while the Constructor is executing
new _UCR()	; The first line of the constructor will store the class instance in the UCR super-global
return

; If you wish to be able to debug plugins, include them in UCRDebug.ahk
; The file does not have to exist, and this line can be safely commented out
#Include *iUCRDebug.ahk

; Include the main classes
#Include Classes\UCRMain.ahk
#Include Classes\Menu.ahk
#Include Classes\Minimizer.ahk
#Include Classes\ProfileToolbox.ahk
#Include Classes\ProfilePicker.ahk
#Include Classes\ProfileTreeBase.ahk
#Include Classes\InputHandler.ahk
#Include Classes\BindModeHandler.ahk
#Include Classes\Profile.ahk

#include Libraries\JSON.ahk
#include Functions\IsEmptyAssoc.ahk

; Called if the user closes the GUI
GuiClose(hwnd){
	UCR.GuiClose(hwnd)
}

; Func allows the MessageHandler thread to register messages in this thread
UCR_OnMessageCreate(msg,hwnd,fnPtr){
	OnMessage(msg+0,hwnd+0,Object(fnPtr+0))
}