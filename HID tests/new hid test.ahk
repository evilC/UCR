/*
All sizeof() comments are 32-bit sizes.
A_PtrSize for x86 is 4, so divide all sizeof() results by 4, feed result into ps()
*/
; DEPENDENCIES:
; _Struct():  https://raw.githubusercontent.com/HotKeyIt/_Struct/master/_Struct.ahk - docs: http://www.autohotkey.net/~HotKeyIt/AutoHotkey/_Struct.htm
; sizeof(): https://raw.githubusercontent.com/HotKeyIt/_Struct/master/sizeof.ahk - docs: http://www.autohotkey.net/~HotKeyIt/AutoHotkey/sizeof.htm
#singleinstance force
#Include <_Struct>
global RAWINPUTDEVICELIST := "HANDLE hDevice,DWORD  dwType"
global RIDI_DEVICENAME := 0x20000007, RIDI_DEVICEINFO := 0x2000000b, RIDI_PREPARSEDDATA := 0x20000005
global TYPE_RIM := {0: "Mouse", 1: "Keyboard", 2: "Other"}

iCount := GetRawInputDeviceList(0,iCount)
DeviceList := new _Struct("RAWINPUTDEVICELIST[" iCount "]")
GetRawInputDeviceList(DeviceList, iCount)

Loop %  iCount {
	s .= "#" A_Index " - Handle: " DeviceList[A_Index].hDevice ", Type: " TYPE_RIM[DeviceList[A_Index].dwType] "`n"
}

msgbox % s
return

GetRawInputDeviceList(ByRef DeviceList:="", ByRef iCount:=0){
	if (IsByRef(DeviceList)){
		; DeviceList contains a struct, not a number
		dl := DeviceList[]
	} else {
		; Contains nothing, or a number - requesting count
		dl := 0
	}
	
    ; Perform the call
    r := DllCall("GetRawInputDeviceList", "Ptr", dl, "UInt*", iCount, "UInt", sizeof(RAWINPUTDEVICELIST) )
	
    ;Check for error
    If (r = -1) Or ErrorLevel {
        ErrorLevel = GetRawInputDeviceList call failed.`nReturn value: %r%`nErrorLevel: %ErrorLevel%`nLine: %A_LineNumber%`nLast Error: %A_LastError%
        Return -1
    } Else Return iCount
}

GetRawInputDeviceInfo(hDevice, uiCommand := -1, ByRef pData := 0, ByRef pcbSize := 0){
	/*
	https://msdn.microsoft.com/en-us/library/windows/desktop/ms645597%28v=vs.85%29.aspx
	
	UINT WINAPI GetRawInputDeviceInfo(
	  _In_opt_     HANDLE hDevice,		// A handle to the raw input device. This comes from the lParam of the WM_INPUT message, from the hDevice member of RAWINPUTHEADER
										// or from GetRawInputDeviceList.
	  _In_         UINT uiCommand,		// Specifies what data will be returned in pData. This parameter can be one of the following values:
										// RIDI_DEVICENAME 0x20000007 -		pData points to a string that contains the device name.
										//									For this uiCommand only, the value in pcbSize is the character count (not the byte count).
										// RIDI_DEVICEINFO 0x2000000b -		pData points to an RID_DEVICE_INFO structure.
										// RIDI_PREPARSEDDATA 0x20000005 -	pData points to the previously parsed data.
	  _Inout_opt_  LPVOID pData,		// A pointer to a buffer that contains the information specified by uiCommand.
										// If uiCommand is RIDI_DEVICEINFO, set the cbSize member of RID_DEVICE_INFO to sizeof(RID_DEVICE_INFO) before calling GetRawInputDeviceInfo.
	  _Inout_      PUINT pcbSize		// The size, in bytes, of the data in pData
	);
	
	typedef struct tagRID_DEVICE_INFO {
	  DWORD cbSize;
	  DWORD dwType;
	  union {
		RID_DEVICE_INFO_MOUSE    mouse;
		RID_DEVICE_INFO_KEYBOARD keyboard;
		RID_DEVICE_INFO_HID      hid;
	  };
	} RID_DEVICE_INFO, *PRID_DEVICE_INFO, *LPRID_DEVICE_INFO;
	*/
	
	if (uiCommand = -1){
		uiCommand := RIDI_DEVICEINFO
	}
	r := DllCall("GetRawInputDeviceInfo", "Ptr", h, "UInt", uiCommand, "Ptr", 0, "UInt*", iLength)
	If (r = -1) Or ErrorLevel {
		ErrorLevel = GetRawInputDeviceInfo call failed.`nReturn value: %r%`nErrorLevel: %ErrorLevel%`nLine: %A_LineNumber%`nLast Error: %A_LastError%
		Return -1
	}
		
}