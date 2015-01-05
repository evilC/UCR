; AHKHID test script
#include <AHKHID>
#SingleInstance force

;Intercept WM_INPUT
OnMessage(0x00FF, "InputMsg")


joysticks := {}

GUI_WIDTH := 600
GUI_HEIGHT := 400

Gui, +Resize -MaximizeBox -MinimizeBox +LastFound
Gui, Add, ListView, % "vlvSticks gOptionChanged AltSubmit w" GUI_WIDTH " h200", Device|VID (Hex)|PID (Hex)|Usage Page|Usage|Unique Name
LV_ModifyCol(1, 200)
LV_ModifyCol(2, 100)
LV_ModifyCol(3, 100)

;Get count
iCount := AHKHID_GetDevCount()
Loop %iCount% {
    ;Get device handle, type and name
    _Handle := AHKHID_GetDevHandle(A_Index)
    _Type   := AHKHID_GetDevType(A_Index)
    _Name   := AHKHID_GetDevName(A_Index)
    
	type := ""
	
    ;Get device info
    
	If (_Type = RIM_TYPEHID) {
        _VendorID      := AHKHID_GetDevInfo(A_Index, DI_HID_VENDORID)
        _ProductID     := AHKHID_GetDevInfo(A_Index, DI_HID_PRODUCTID)
        _VersionNumber := AHKHID_GetDevInfo(A_Index, DI_HID_VERSIONNUMBER)
        _UsagePage     := AHKHID_GetDevInfo(A_Index, DI_HID_USAGEPAGE)
        _Usage         := AHKHID_GetDevInfo(A_Index, DI_HID_USAGE)
		
		vid := ToHex(_VendorID)
		pid := ToHex(_ProductID)
		key := "SYSTEM\CurrentControlSet\Control\MediaProperties\PrivateProperties\Joystick\OEM\VID_" vid "&PID_" pid
		Regread, human_name, HKLM, % key, OEMName

		if (human_name){
			LV_ADD(,human_name, _VendorID " (" vid ")", _ProductID  " (" pid ")", _UsagePage, _Usage, _Name)
			joysticks[_Name] := {human_name: human_name, page: _UsagePage, usage: _Usage, vid: _VendorID , pid: _ProductID}
		}

    }

}
Gui, Show, % "w" GUI_WIDTH + 20 " h" GUI_HEIGHT + 20


;Keep handle
GuiHandle := WinExist()

Gosub, Register
Return

GuiEscape:
GuiClose:
ExitApp
Return

Register:
    Gui, Submit, NoHide    ;Put the checkbox in associated var

	count := 0
	for key, value in joysticks {
		count++
	}
    AHKHID_AddRegister(2 + count)
	AHKHID_AddRegister(1,2,GuiHandle,RIDEV_INPUTSINK)
	AHKHID_AddRegister(1,6,GuiHandle,RIDEV_INPUTSINK)
	for name, obj in joysticks {
		;msgbox % obj.human_name
		AHKHID_AddRegister(obj.page, obj.usage, GuiHandle, RIDEV_INPUTSINK)
	}
	AHKHID_Register()
Return

Unregister:
    AHKHID_Register(1,2,0,RIDEV_REMOVE)    ;Although MSDN requires the handle to be 0, you can send GuiHandle if you want.
Return                                    ;AHKHID will automatically put 0 for RIDEV_REMOVE.

Clear:
    If A_GuiEvent = DoubleClick
        GuiControl,, %A_GuiControl%,|
Return

OptionChanged:
	Gui, Submit, NoHide
	Gui, ListView, lvSticks
	CurrentStick := LV_GetNext()
	if (CurrentStick){
		LV_GetText(StickID, CurrentStick , 6)
	} else {
		StickID := ""
	}
	
	return

; converts to hex, pads to 4 digits, chops off 0x
ToHex(dec){
	return Substr(Convert2Hex(dec,4),3)
}

InputMsg(wParam, lParam) {
    Local r, h
    Critical    ;Or otherwise you could get ERROR_INVALID_HANDLE
    r := AHKHID_GetInputInfo(lParam, II_DEVTYPE) 
    If (r = -1)
        OutputDebug %ErrorLevel%
    If (r = RIM_TYPEMOUSE) {
		if (AHKHID_GetInputInfo(lParam, II_MSE_BUTTONFLAGS) ){
			; mouse input
		}
    } Else If (r = RIM_TYPEKEYBOARD) {
		; keyboard input
    } Else If (r = RIM_TYPEHID) {
		; Other - joysticks etc
		h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE )
		r := AHKHID_GetInputData(lParam, uData)
		vid := AHKHID_GetDevInfo(h, DI_HID_VENDORID, True)
		name := AHKHID_GetDevName(h,1)
		; If stick is the one selected
		if (name == StickID){
			SetToolTip("Stick Changed")
		}
    }
}

SetToolTip(tip){
		ToolTip % tip
		SetTimer, RemoveToolTip, 500
}

RemoveToolTip:
	ToolTip
	SetTimer, RemoveToolTip, Off
	return

Convert2Hex(p_Integer,p_MinDigits=0)
    {
    ;-- Workaround for AutoHotkey Basic
    PtrType:=(A_PtrSize=8) ? "Ptr":"UInt"
 
    ;-- Negative?
    if (p_Integer<0)
        {
        l_NegativeChar:="-"
        p_Integer:=-p_Integer
        }
 
    ;-- Determine the width (in characters) of the output buffer
    nSize:=(p_Integer=0) ? 1:Floor(Ln(p_Integer)/Ln(16))+1
    if (p_MinDigits>nSize)
        nSize:=p_MinDigits+0
 
    ;-- Build Format string
    l_Format:="`%0" . nSize . "I64X"
 
    ;-- Create and populate l_Argument
    VarSetCapacity(l_Argument,8)
    NumPut(p_Integer,l_Argument,0,"Int64")
 
    ;-- Convert
    VarSetCapacity(l_Buffer,A_IsUnicode ? nSize*2:nSize,0)
    DllCall(A_IsUnicode ? "msvcrt\_vsnwprintf":"msvcrt\_vsnprintf"
        ,"Str",l_Buffer             ;-- Storage location for output
        ,"UInt",nSize               ;-- Maximum number of characters to write
        ,"Str",l_Format             ;-- Format specification
        ,PtrType,&l_Argument)       ;-- Argument
 
    ;-- Assemble and return the final value
    Return l_NegativeChar . "0x" . l_Buffer
    }