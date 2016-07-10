#SingleInstance force

#include Libraries\JSON.ahk
OutputDebug DBGVIEWCLEAR
SetBatchLines, -1
global UCR	; set UCR as a super-global
new UCRMain()
return

#Include Classes\UCRMain.ahk
#Include Classes\ProfileToolbox.ahk
#Include Classes\ProfilePicker.ahk
#Include Classes\ProfileTreeBase.ahk
#Include Classes\InputHandler.ahk
#Include Classes\BindModeHandler.ahk
#Include Classes\Profile.ahk
#Include Classes\Plugin.ahk
#Include Classes\GuiControls\GuiControl.ahk
#Include Classes\GuiControls\BannerCombo.ahk
#Include Classes\GuiControls\ProfileSelect.ahk
#Include Classes\GuiControls\InputButton.ahk
#Include Classes\GuiControls\InputAxis.ahk
#Include Classes\GuiControls\InputDelta.ahk
#Include Classes\GuiControls\OutputButton.ahk
#Include Classes\GuiControls\OutputAxis.ahk
#Include Classes\GuiControls\BindObject.ahk
#Include Classes\Button.ahk
#Include Classes\Axis.ahk
GuiClose(hwnd){
	UCR.GuiClose(hwnd)
}

UCR_OnMessageCreate(msg,hwnd,fnPtr){
	OnMessage(msg+0,hwnd+0,Object(fnPtr+0))
}