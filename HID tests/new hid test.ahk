/*
All sizeof() comments are 32-bit sizes.
A_PtrSize for x86 is 4, so divide all sizeof() results by 4, feed result into ps()
*/
#singleinstance force

global SIZE_RAWINPUTDEVICELIST := ps(2)
global SIZE_HANDLE := ps(1)
global TYPE_RIM := {0: "Mouse", 1: "Keyboard", 2: "Other"}

dl := 0
GetRawInputDeviceList(dl, iCount)
VarSetCapacity(dl, iCount * SIZE_RAWINPUTDEVICELIST)
dl := 1
GetRawInputDeviceList(dl, iCount)

DeviceList := []

s := ""
Loop % iCount {
	c := A_Index - 1
	DeviceList[c] := {}
	DeviceList[c].Handle := NumGet(dl, (c * SIZE_RAWINPUTDEVICELIST), "Uint")
	DeviceList[c].Type := NumGet(dl, (c * SIZE_RAWINPUTDEVICELIST) + SIZE_HANDLE, "Uint")
	s .= "#" c " - Handle: " DeviceList[c].Handle ", Type: " TYPE_RIM[DeviceList[c].Type] "`n"
}
msgbox % s


return

ps(c := 1){
	return c * A_PtrSize
}

GetRawInputDeviceList(ByRef pRawInputDeviceList, ByRef iCount){
	/*
	https://msdn.microsoft.com/en-us/library/windows/desktop/ms645598%28v=vs.85%29.aspx
	
	UINT WINAPI GetRawInputDeviceList(
	  _Out_opt_  PRAWINPUTDEVICELIST pRawInputDeviceList,		// An array of RAWINPUTDEVICELIST structures for the devices attached to the system.
																// If NULL, the number of devices are returned in *puiNumDevices
	  _Inout_    PUINT puiNumDevices,							// If pRawInputDeviceList is NULL, the function populates this variable with the number of devices attached to the system;
																// otherwise, this variable specifies the number of RAWINPUTDEVICELIST structures that can be contained in the buffer to which
																// pRawInputDeviceList points. If this value is less than the number of devices attached to the system,
																// the function returns the actual number of devices in this variable and fails with ERROR_INSUFFICIENT_BUFFER.
	  _In_       UINT cbSize									// The size of a RAWINPUTDEVICELIST structure, in bytes
	);

	struct tagRAWINPUTDEVICELIST {
	  HANDLE hDevice;
	  DWORD  dwType;
	} RAWINPUTDEVICELIST, *PRAWINPUTDEVICELIST;

	sizeof(RAWINPUTDEVICELIST) = 8
	*/
	
    ;Get the device count
    r := DllCall("GetRawInputDeviceList", "Ptr", &pRawInputDeviceList, "UInt*", iCount, "UInt", ps(2) )
	
    ;Check for error
    If (r = -1) Or ErrorLevel {
        ErrorLevel = GetRawInputDeviceList call failed.`nReturn value: %r%`nErrorLevel: %ErrorLevel%`nLine: %A_LineNumber%`nLast Error: %A_LastError%
        Return -1
    } Else Return iCount
}