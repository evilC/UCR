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

Gui, Add, ListView, % "vlvEvents w" GUI_WIDTH " h200 xm yp+" (GUI_HEIGHT / 2) + 20, Device|Subdevice|Input Type|New Value
LV_ModifyCol(1, 100)
LV_ModifyCol(2, 200)
LV_ModifyCol(3, 100)

Gui, Add, Checkbox, xm Section Checked vHideMouseWheel gOptionChanged, Don't Log Mouse Wheel
Gui, Add, Checkbox, ys Section Checked vHideLeftMouse gOptionChanged , Don't Log Left Mouse
Gui, Add, Checkbox, ys Section CheckevHideRightMouse gOptionChanged, Don't Log Right Mouse
Gui, Add, Checkbox, ys Section vHideStickAxes gOptionChanged, Ignore Stick Axes

Gui, ListView, lvSticks

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

Gui, Show, % "w" GUI_WIDTH + 20 " h" GUI_HEIGHT + 50


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
	Gui, ListView, lvEvents
	return

; converts to hex, pads to 4 digits, chops off 0x
ToHex(dec, padding := 4){
	return Substr(Convert2Hex(dec,padding),3)
}

InputMsg(wParam, lParam) {
    Local r, h
    Critical    ;Or otherwise you could get ERROR_INVALID_HANDLE
    r := AHKHID_GetInputInfo(lParam, II_DEVTYPE) 
    If (r = -1)
        OutputDebug %ErrorLevel%
    If (r = RIM_TYPEMOUSE) {
		; Filter mouse movement
		flags := AHKHID_GetInputInfo(lParam, II_MSE_BUTTONFLAGS)
		if (flags){
			; IMPORTANT NOTE!
			; EVENT COULD CONTAIN MORE THAN ONE BUTTON CHANGE!!!
			;Get flags and add to listbox
			s := ""
			If (flags & RI_MOUSE_LEFT_BUTTON_DOWN)
				if (!HideLeftMouse){
					LV_ADD(,"Mouse", "", "Left Button", "Down")
				}
			If (flags & RI_MOUSE_LEFT_BUTTON_UP)
				if (!HideLeftMouse){
					LV_ADD(,"Mouse", "", "Left Button", "Up")
				}
			If (flags & RI_MOUSE_RIGHT_BUTTON_DOWN)
				if (!HideRightMouse){
					LV_ADD(,"Mouse", "", "Right Button", "Down")
				}
			If (flags & RI_MOUSE_RIGHT_BUTTON_UP)
				if (!HideRightMouse){
					LV_ADD(,"Mouse", "", "Right Button", "Up")
				}
			If (flags & RI_MOUSE_MIDDLE_BUTTON_DOWN)
				LV_ADD(,"Mouse", "", "Middle Button", "Down")
			If (flags & RI_MOUSE_MIDDLE_BUTTON_UP)
				LV_ADD(,"Mouse", "", "Middle Button", "Up")
			If (flags & RI_MOUSE_BUTTON_4_DOWN)
				LV_ADD(,"Mouse", "", "XButton1", "Down")
			If (flags & RI_MOUSE_BUTTON_4_UP)
				LV_ADD(,"Mouse", "", "XButton1", "Up")
			If (flags & RI_MOUSE_BUTTON_5_DOWN)
				LV_ADD(,"Mouse", "", "XButton2", "Down")
			If (flags & RI_MOUSE_BUTTON_5_UP)
				LV_ADD(,"Mouse", "", "XButton2", "Up")
			If (flags & RI_MOUSE_WHEEL)
				if (!HideMouseWheel){
					LV_ADD(,"Mouse", "", "Wheel", Round(AHKHID_GetInputInfo(lParam, II_MSE_BUTTONDATA) / 120))
				}
			
			SetToolTip(s)
		}
    } Else If (r = RIM_TYPEKEYBOARD) {
		vk := AHKHID_GetInputInfo(lParam, II_KBD_VKEY)
		keyname := GetKeyName("vk" ToHex(vk,2))
		flags := AHKHID_GetInputInfo(lParam, II_KBD_FLAGS)
		makecode := AHKHID_GetInputInfo(lParam, II_KBD_MAKECODE)
		s := ""
		if (vk == 17) {
			; Control
			if (flags < 2){
				; LControl
				s := "Left "
			} else {
				; RControl
				s := "Right "
				flags -= 2
			
			}
			; One of the control keys
			;if ()
			;SoundBeep
		} else if (vk == 18) {
			; Alt
			if (flags < 2){
				; LAlt
				s := "Left "
			} else {
				; RAlt
				s := "Right "
				flags -= 3	; RALT REPORTS DIFFERENTLY!
			
			}
		} else if (vk == 16){
			; Shift
			if (makecode == 42){
				; LShift
				s := "Left "
			} else {
				; RShift
				s := "Right "
			}
		} else if (vk == 91 || vk == 92) {
			; Windows key
			flags -= 2
			if (makecode == 91){
				; LWin
				s := "Left "
			} else {
				; RWin
				s := "Right "
			}
		}
		s .= keyname
		
		;SetToolTip("Keyboard: " kn " " ev)
		LV_ADD(,"Keyboard", "", s, (flags ? "Up" : "Down") )
		; keyboard input
    } Else If (r = RIM_TYPEHID) {
		; Other - joysticks etc
		h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE )
		r := AHKHID_GetInputData(lParam, uData)
		vid := AHKHID_GetDevInfo(h, DI_HID_VENDORID, True)
		name := AHKHID_GetDevName(h,1)
		; If stick is the one selected
		if (name == StickID){
			;SetToolTip("Stick Changed")
			LV_ADD(,"Joystick", "")
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