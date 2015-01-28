; AHKHID test script
#include <AHKHID>
#SingleInstance force

RIDI_PREPARSEDDATA := 0x20000005	; WinUser.h

;Intercept WM_INPUT
OnMessage(0x00FF, "InputMsg")

joysticks := {}

GUI_WIDTH := 600
GUI_HEIGHT := 400

Gui, +Resize -MaximizeBox -MinimizeBox +LastFound
Gui, Add, ListView, % "vlvSticks gOptionChanged AltSubmit w" GUI_WIDTH " h200", Device|VID (Hex)|PID (Hex)|Usage Page|Usage|Unique Name
LV_ModifyCol(1, 150)
LV_ModifyCol(2, 100)
LV_ModifyCol(3, 100)

Gui, Add, ListView, % "vlvEvents w" GUI_WIDTH " h200 xm yp+" (GUI_HEIGHT / 2) + 20, Device|Subdevice|Input Type|New Value
LV_ModifyCol(1, 60)
LV_ModifyCol(2, 150)
LV_ModifyCol(3, 80)

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
			joysticks[_Name] := {enabled: 1, human_name: human_name, page: _UsagePage, usage: _Usage, vid: _VendorID , pid: _ProductID}
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
	Local r, h, wwaswheel
	;global RIDI_PREPARSEDDATA
	Critical    ;Or otherwise you could get ERROR_INVALID_HANDLE
	r := AHKHID_GetInputInfo(lParam, II_DEVTYPE)
	waslogged := 0
	waswheel := 0
	If (r = -1)
		OutputDebug %ErrorLevel%
	If (r = RIM_TYPEMOUSE) {
		; Mouse Input ==============
		; Filter mouse movement
		flags := AHKHID_GetInputInfo(lParam, II_MSE_BUTTONFLAGS)
		if (flags){
			; IMPORTANT NOTE!
			; EVENT COULD CONTAIN MORE THAN ONE BUTTON CHANGE!!!
			;Get flags and add to listbox
			s := ""
			If (flags & RI_MOUSE_LEFT_BUTTON_DOWN){
				if (!HideLeftMouse){
					LV_ADD(,"Mouse", "", "Left Button", "Down")
				}
			}
			If (flags & RI_MOUSE_LEFT_BUTTON_UP){
				if (!HideLeftMouse){
					LV_ADD(,"Mouse", "", "Left Button", "Up")
				}
			}
			If (flags & RI_MOUSE_RIGHT_BUTTON_DOWN){
				if (!HideRightMouse){
					LV_ADD(,"Mouse", "", "Right Button", "Down")
				}
			}
			If (flags & RI_MOUSE_RIGHT_BUTTON_UP){
				if (!HideRightMouse){
					LV_ADD(,"Mouse", "", "Right Button", "Up")
				}
			}
			If (flags & RI_MOUSE_MIDDLE_BUTTON_DOWN){
				LV_ADD(,"Mouse", "", "Middle Button", "Down")
			}
			If (flags & RI_MOUSE_MIDDLE_BUTTON_UP){
				LV_ADD(,"Mouse", "", "Middle Button", "Up")
			}
			If (flags & RI_MOUSE_BUTTON_4_DOWN) {
				LV_ADD(,"Mouse", "", "XButton1", "Down")
			}
			If (flags & RI_MOUSE_BUTTON_4_UP) {
				LV_ADD(,"Mouse", "", "XButton1", "Up")
			}
			If (flags & RI_MOUSE_BUTTON_5_DOWN) {
				LV_ADD(,"Mouse", "", "XButton2", "Down")
			}
			If (flags & RI_MOUSE_BUTTON_5_UP) {
				LV_ADD(,"Mouse", "", "XButton2", "Up")
			}
			If (flags & RI_MOUSE_WHEEL) {
				waswheel := 1
				if (!HideMouseWheel){
					LV_ADD(,"Mouse", "", "Wheel", Round(AHKHID_GetInputInfo(lParam, II_MSE_BUTTONDATA) / 120))
				}
			}
			waslogged := 1
		}
	} Else If (r = RIM_TYPEKEYBOARD) {
		; keyboard input ======================
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
		waslogged := 1
		LV_ADD(,"Keyboard", "", s, (flags ? "Up" : "Down") )
	} Else If (r = RIM_TYPEHID) {
		; Stick Input ==============
		; reference material: http://www.codeproject.com/Articles/185522/Using-the-Raw-Input-API-to-Process-Joystick-Input
		; same-ish: http://www.wenda.io/questions/5585134/native-way-to-get-the-feature-report-descriptor-of-hid-device.html
		h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE )
		name := AHKHID_GetDevName(h,1)
		if (name == StickID){
			; sizeof(HIDP_CAPS) = 64
			; sizeof(HIDP_VALUE_CAPS) = 72
			; sizeof(HIDP_BUTTON_CAPS) = 72
			; sizeof(USAGE) = 2
			; sizeof(HIDP_REPORT_TYPE) = 4
			; HidP_Input = 0
			HIDP_STATUS_SUCCESS := 1114112
			
			/*
			// Parse the raw input header to read its size.
			UINT bufferSize;
			GetRawInputData(HRAWINPUT)lParam, RID_INPUT, NULL, &bufferSize, sizeof(RAWINPUTHEADER));

			// Allocate memory for the raw input data and retrieve it
			PRAWINPUT = (PRAWINPUT)HeapAlloc(GetProcessHeap(), 0, bufferSize);
			GetRawInputData(HRAWINPUT)lParam, RID_INPUT, rawInput /* NOT NULL */, &bufferSize, sizeof(RAWINPUTHEADER));
			*/
			r := AHKHID_GetInputData(lParam, uData)
			
			i := AHKHID_GetDevIndex(h)
			dev_handle := AHKHID_GetDevHandle(i)

			res := GetRIDI_PREPARSEDDATA(dev_handle, preparsedData)
			
			;C++ PHIDP_PREPARSED_DATA preparsedData = (PHIDP_PREPARSED_DATA)HeapAlloc(heap, 0, bufferSize);
			;VarSetCapacity(preparsedData, iSize)
			
			;C++ GetRawInputDeviceInfo(rawInput->header.hDevice, RIDI_PREPARSEDDATA, preparsedData, &bufferSize);
			;res := DllCall("GetRawInputDeviceInfo", "UInt", dev_handle, "UInt", RIDI_PREPARSEDDATA, "Ptr", &preparsedData, "UInt*", iSize, "UInt", 8 + A_PtrSize * 2)
			
			/*
			// Create a structure that will hold the values
			HidP_GetCaps(preparsedData, &caps);
			USHORT capsLength = caps.NumberInputValueCaps;
			PHIDP_VALUE_CAPS valueCaps = (PHIDP_VALUE_CAPS)HeapAlloc(heap, 0, capsLength*sizeof(HIDP_VALUE_CAPS));
			HidP_GetValueCaps(HidP_Input, valueCaps, &capsLength, preparsedData);
			*/
	
			;C++ HidP_GetCaps(preparsedData, &caps);
			/*
			sizeof(HIDP_CAPS) = 64
			offsetof(HIDP_CAPS, NumberLinkCollectionNodes) = 44
			
			typedef struct _HIDP_CAPS {
			00	  USAGE  Usage;
			02	  USAGE  UsagePage;
			04	  USHORT InputReportByteLength;
			06	  USHORT OutputReportByteLength;
			08	  USHORT FeatureReportByteLength;
			10 0  USHORT Reserved[17];
			12 1
			14 2
			16 3
			18 4
			20 5
			22 6
			24 7
			26 8
			28 9
			30 10
			32 11
			34 12
			36 13
			38 14
			40 16
			42 17 -- isn't 0-16 17 items? However without this line, length is not 64
			44	  USHORT NumberLinkCollectionNodes;
			46	  USHORT NumberInputButtonCaps;
			48	  USHORT NumberInputValueCaps;
			50	  USHORT NumberInputDataIndices;
			52	  USHORT NumberOutputButtonCaps;
			54	  USHORT NumberOutputValueCaps;
			56	  USHORT NumberOutputDataIndices;
			58	  USHORT NumberFeatureButtonCaps;
			60	  USHORT NumberFeatureValueCaps;
			62	  USHORT NumberFeatureDataIndices;
			64 - end
			}
			*/
			VarSetCapacity(caps, 64) ; sizeof(HIDP_CAPS) = 64
			res := DllCall("Hid\HidP_GetCaps", "Ptr", &preparsedData, "Ptr", &caps)

			;C++ USHORT capsLength = caps.NumberInputValueCaps;
			capsLength := NumGet(caps, 48, "UShort")
			
			;C++ PHIDP_VALUE_CAPS valueCaps = (PHIDP_VALUE_CAPS)HeapAlloc(heap, 0, capsLength*sizeof(HIDP_VALUE_CAPS));
			VarSetCapacity(valueCaps, 72 * capsLength)
			
			/*
			C++ 
			CHECK( HidP_GetCaps(pPreparsedData, &Caps) == HIDP_STATUS_SUCCESS )
			CHECK( pButtonCaps = (PHIDP_BUTTON_CAPS)HeapAlloc(hHeap, 0, sizeof(HIDP_BUTTON_CAPS) * Caps.NumberInputButtonCaps) );

			capsLength = Caps.NumberInputButtonCaps;
			CHECK( HidP_GetButtonCaps(HidP_Input, pButtonCaps, &capsLength, pPreparsedData) == HIDP_STATUS_SUCCESS )
			g_NumberOfButtons = pButtonCaps->Range.UsageMax - pButtonCaps->Range.UsageMin + 1;
			*/
			/*
			HidP_GetButtonCaps(
			  _In_     HIDP_REPORT_TYPE ReportType,
			  _Out_    PHIDP_BUTTON_CAPS ButtonCaps,
			  _Inout_  PUSHORT ButtonCapsLength,
			  _In_     PHIDP_PREPARSED_DATA PreparsedData
			);
			*/
			
			/*
				typedef struct _HIDP_BUTTON_CAPS {
			00	  USAGE   UsagePage;
			02	  UCHAR   ReportID;
			03	  BOOLEAN IsAlias;
			04	  USHORT  BitField;
			06	  USHORT  LinkCollection;
			08	  USAGE   LinkUsage;
			10	  USAGE   LinkUsagePage;
			12	  BOOLEAN IsRange;
			13	  BOOLEAN IsStringRange;
			14	  BOOLEAN IsDesignatorRange;
			15	  BOOLEAN IsAbsolute;
				  ULONG   Reserved[10];
				  union {
					struct {
			56		  USAGE  UsageMin;
			58		  USAGE  UsageMax;
			60		  USHORT StringMin;
			62		  USHORT StringMax;
			64		  USHORT DesignatorMin;
			66		  USHORT DesignatorMax;
			68		  USHORT DataIndexMin;
			70		  USHORT DataIndexMax;
					} Range;
					struct {
			56		  USAGE  Usage;
			58		  USAGE  Reserved1;
			60		  USHORT StringIndex;
			62		  USHORT Reserved2;
			64		  USHORT DesignatorIndex;
			66		  USHORT Reserved3;
			68		  USHORT DataIndex;
			70		  USHORT Reserved4;
					} NotRange;
				  };
				}
			*/

			NumberInputButtonCaps := NumGet(Caps, 46, "UShort")
			VarSetCapacity(pButtonCaps, NumberInputButtonCaps * 72)
			res := DllCall("Hid\HidP_GetButtonCaps", "Uint", 0, "Ptr", &pButtonCaps, "Ptr", &NumberInputButtonCaps, "Ptr",  &preparsedData)
			UsageMin := NumGet(pButtonCaps, 56, "UShort")
			UsageMax := NumGet(pButtonCaps, 58, "UShort")
			UsagePage := NumGet(pButtonCaps, 0, "UShort")
			UsageLength := (UsageMax - UsageMin) + 1
			buttons := UsageLength


			/*
			//
			// Get the pressed buttons
			//

			usageLength = g_NumberOfButtons;
			CHECK(
				HidP_GetUsages(
					HidP_Input, pButtonCaps->UsagePage, 0, usage, &usageLength, pPreparsedData, (PCHAR)pRawInput->data.hid.bRawData, pRawInput->data.hid.dwSizeHid
				) == HIDP_STATUS_SUCCESS );

			ZeroMemory(bButtonStates, sizeof(bButtonStates));
			for(i = 0; i < usageLength; i++)
				bButtonStates[usage[i] - pButtonCaps->Range.UsageMin] = TRUE;

			*/

			/*
			HidP_GetUsages(
			  _In_     HIDP_REPORT_TYPE ReportType,
			  _In_     USAGE UsagePage,
			  _In_     USHORT LinkCollection,
			  _Out_    PUSAGE UsageList,
			  _Inout_  PULONG UsageLength,
			  _In_     PHIDP_PREPARSED_DATA PreparsedData,
			  _Out_    PCHAR Report,
			  _In_     ULONG ReportLength
			);
			*/
			
			LinkCollection := NumGet(Caps, 6, "UShort")
			VarSetCapacity(UsageList, 128)
			;UsageList := 4
			ReportLength := NumGet(caps, 4, "UShort")
			;VarSetCapacity(Report, ReportLength)
			;                                     ReportType,           UsagePage,    LinkCollection,         UsageList,        UsageLength,         PreparsedData,         Report,    ReportLength
			res := DllCall("Hid\HidP_GetUsages", "UShort", 0, "UShort", UsagePage,       "UShort", 0, "Ptr", &UsageList, "Ptr", &UsageLength, "Ptr", &preparsedData, "Ptr", &uData, "Uint", ReportLength)
			val := NumGet(UsageList,0,"UShort")
			msgbox % val
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			; C++ HidP_GetValueCaps(HidP_Input, valueCaps, &capsLength, preparsedData);
			/*
			https://msdn.microsoft.com/en-us/library/windows/hardware/ff539754(v=vs.85).aspx
			HidP_GetValueCaps(
			  _In_     HIDP_REPORT_TYPE ReportType,
			  _Out_    PHIDP_VALUE_CAPS ValueCaps,
			  _Inout_  PUSHORT ValueCapsLength,
			  _In_     PHIDP_PREPARSED_DATA PreparsedData
			)
			
			ReportType [in] - Specifies a HIDP_REPORT_TYPE enumerator value that identifies the report type.
			ValueCaps [out] - Pointer to a caller-allocated buffer in which the routine returns a value capability array for the specified report type.
			ValueCapsLength [in, out] - Specifies the length, on input, in array elements, of the ValueCaps buffer.
			                            On output, the routine sets ValueCapsLength to the number of elements that the it actually returns.
			PreparsedData [in] - Pointer to a top-level collection's preparsed data.
			);
			*/
			; The HidP_GetValueCaps routine returns a VALUE CAPABILITY ARRAY that describes all the HID control values in a top-level collection for a specified type of HID report.
			VarSetCapacity(ValueCapsLength, 2) ; USHORT
			res := DllCall("Hid\HidP_GetValueCaps", "Uint", 0, "Ptr", &valueCaps, "Ptr", &capsLength, "ptr", &preparsedData)
			
			/*
			typedef struct _HIDP_VALUE_CAPS {
			00	  USAGE   UsagePage;
			02	  UCHAR   ReportID;
			03	  BOOLEAN IsAlias;
			04	  USHORT  BitField;
			06	  USHORT  LinkCollection;
			08	  USAGE   LinkUsage;
			10	  USAGE   LinkUsagePage;
			12	  BOOLEAN IsRange;
			13	  BOOLEAN IsStringRange;
			14	  BOOLEAN IsDesignatorRange;
			15	  BOOLEAN IsAbsolute;
			16	  BOOLEAN HasNull;
			17	  UCHAR   Reserved;
			18	  USHORT  BitSize;
			20	  USHORT  ReportCount;
			22	  USHORT  Reserved2[5];
			32	  ULONG   UnitsExp;
			36	  ULONG   Units;
			40	  LONG    LogicalMin;
			44	  LONG    LogicalMax;
			48	  LONG    PhysicalMin;
			52	  LONG    PhysicalMax;
			*/
			
			/*
				//
				// Get the state of discrete-valued-controls
				//

				for(i = 0; i < Caps.NumberInputValueCaps; i++)
				{
					CHECK(
						HidP_GetUsageValue(
							HidP_Input, pValueCaps[i].UsagePage, 0, pValueCaps[i].Range.UsageMin, &value, pPreparsedData,
							(PCHAR)pRawInput->data.hid.bRawData, pRawInput->data.hid.dwSizeHid
						) == HIDP_STATUS_SUCCESS );

					switch(pValueCaps[i].Range.UsageMin)
					{
					case 0x30:	// X-axis
						lAxisX = (LONG)value - 128;
						break;

					case 0x31:	// Y-axis
						lAxisY = (LONG)value - 128;
						break;

					case 0x32: // Z-axis
						lAxisZ = (LONG)value - 128;
						break;

					case 0x35: // Rotate-Z
						lAxisRz = (LONG)value - 128;
						break;

					case 0x39:	// Hat Switch
						lHat = value;
						break;
					}
				}
			*/

			;UsagePage := NumGet(valueCaps, 0, "UShort")
			;LinkCollection := NumGet(valueCaps, 6, "Uchar")
			;Usage := 4
			;VarSetCapacity(UsageValue,4)
			
			;msgbox % test

			/*
			// Read sample value
			HidP_GetUsageValue(HidP_Input, valueCaps[i].UsagePage, 0, valueCaps[i].Range.UsageMin, &value, preparsedData, 
			
			NTSTATUS __stdcall HidP_GetUsageValue(
			  _In_   HIDP_REPORT_TYPE ReportType,
			  _In_   USAGE UsagePage,
			  _In_   USHORT LinkCollection,
			  _In_   USAGE Usage,
			  _Out_  PULONG UsageValue,
			  _In_   PHIDP_PREPARSED_DATA PreparsedData,
			  _In_   PCHAR Report,
			  _In_   ULONG ReportLength
			);
			*/

			;res := DllCall("Hid\HidP_GetUsageValue", "Uint", 0, "UShort", UsagePage, "UShort", LinkCollection, "UShort", 4, "Ptr", &UsageValue, "Ptr", &preparsedData, "Ptr", )
			;msgbox % Errorlevel

			; Decode preparsed data. Step 3, code block #2 @ http://www.codeproject.com/Articles/185522/Using-the-Raw-Input-API-to-Process-Joystick-Input
			;HidP_GetCaps(pPreparsedData, &Caps)
			; HID_CAPS: http://msdn.microsoft.com/en-us/library/windows/hardware/ff539697(v=vs.85).aspx
			; 16 16-bit numbers - should be 256 size?
			;VarSetCapacity(Caps, 256)
			;ret := DllCall("Hid\HidP_GetCaps", "Ptr", &pPreparsedData, "Ptr", &Caps)
			;ret := DllCall("Hid\HidP_GetCaps", "Ptr", &pPreparsedData, "UInt*", Caps)
			;msgbox % "EL: " ErrorLevel "`nRet: " ret "`nCaps: " Caps

			;returns -1072627711
			
			/*
			Error Codes:
			#ifndef FACILITY_HID_ERROR_CODE
			#define FACILITY_HID_ERROR_CODE 0x11
			#endif

			; NTSTATUS is a LONG ?
			#define HIDP_ERROR_CODES(SEV, CODE) \
					((NTSTATUS) (((SEV) << 28) | (FACILITY_HID_ERROR_CODE << 16) | (CODE)))
			
			;																 ret: -1072627711 = 11000000000100010000000000000001
			#define HIDP_STATUS_SUCCESS                  (HIDP_ERROR_CODES(0x0,0)) 1114112    = 00000000000100010000000000000000
			#define HIDP_STATUS_NULL                     (HIDP_ERROR_CODES(0x8,1)) 2148597761 = 10000000000100010000000000000001
			#define HIDP_STATUS_INVALID_PREPARSED_DATA   (HIDP_ERROR_CODES(0xC,1)) 3435973836 = 11001100 11001100 11001100 11001100
																				   3222339585 = 11000000000100010000000000000001
			#define HIDP_STATUS_INVALID_REPORT_TYPE      (HIDP_ERROR_CODES(0xC,2)) 3222339586 = 11000000000100010000000000000010
			#define HIDP_STATUS_INVALID_REPORT_LENGTH    (HIDP_ERROR_CODES(0xC,3)) 3222339587
			#define HIDP_STATUS_USAGE_NOT_FOUND          (HIDP_ERROR_CODES(0xC,4)) 3222339588
			#define HIDP_STATUS_VALUE_OUT_OF_RANGE       (HIDP_ERROR_CODES(0xC,5)) 3222339589
			#define HIDP_STATUS_BAD_LOG_PHY_VALUES       (HIDP_ERROR_CODES(0xC,6)) 3222339590
			#define HIDP_STATUS_BUFFER_TOO_SMALL         (HIDP_ERROR_CODES(0xC,7)) 3222339591
			#define HIDP_STATUS_INTERNAL_ERROR           (HIDP_ERROR_CODES(0xC,8)) 3222339592
			#define HIDP_STATUS_I8042_TRANS_UNKNOWN      (HIDP_ERROR_CODES(0xC,9)) 3222339593
			#define HIDP_STATUS_INCOMPATIBLE_REPORT_ID   (HIDP_ERROR_CODES(0xC,0xA)) 3222339594
			#define HIDP_STATUS_NOT_VALUE_ARRAY          (HIDP_ERROR_CODES(0xC,0xB)) 3222339595
			#define HIDP_STATUS_IS_VALUE_ARRAY           (HIDP_ERROR_CODES(0xC,0xC)) 3222339596
			#define HIDP_STATUS_DATA_INDEX_NOT_FOUND     (HIDP_ERROR_CODES(0xC,0xD)) 3222339597
			#define HIDP_STATUS_DATA_INDEX_OUT_OF_RANGE  (HIDP_ERROR_CODES(0xC,0xE)) 3222339598
			#define HIDP_STATUS_BUTTON_NOT_PRESSED       (HIDP_ERROR_CODES(0xC,0xF)) 3222339599
			#define HIDP_STATUS_REPORT_DOES_NOT_EXIST    (HIDP_ERROR_CODES(0xC,0x10)) 3222339600
			#define HIDP_STATUS_NOT_IMPLEMENTED          (HIDP_ERROR_CODES(0xC,0x20)) 3222339616
			*/
			
			;pButtonCaps = (PHIDP_BUTTON_CAPS)HeapAlloc(hHeap, 0, sizeof(HIDP_BUTTON_CAPS) * Caps.NumberInputButtonCaps)

			;HidP_GetButtonCaps(HidP_Input, pButtonCaps, &capsLength, pPreparsedData

			;g_NumberOfButtons = pButtonCaps->Range.UsageMax - pButtonCaps->Range.UsageMin + 1;

			; Add to log
			;LV_ADD(,"Joystick", joysticks[name].human_name, "", Bin2Hex(&uData, r))
			;LV_ADD(,"Joystick", joysticks[name].human_name, "", Bin2Hex(&uData, r))
			LV_ADD(,"Joystick", joysticks[name].human_name, "", "Buttons: " buttons)
		}
	}
	
	
	if (waslogged && !waswheel){
		; Scroll LV to end
		LV_Modify(LV_GetCount(), "Vis")
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

Convert2Hex(p_Integer,p_MinDigits=0) {
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

;By Laszlo, adapted by TheGood
;http://www.autohotkey.com/forum/viewtopic.php?p=377086#377086
Bin2Hex(addr,len) {
	Static fun, ptr 
	If (fun = "") {
		If A_IsUnicode
			If (A_PtrSize = 8)
				h=4533c94c8bd14585c07e63458bd86690440fb60248ffc2418bc9410fb6c0c0e8043c090fb6c00f97c14180e00f66f7d96683e1076603c8410fb6c06683c1304180f8096641890a418bc90f97c166f7d94983c2046683e1076603c86683c13049ffcb6641894afe75a76645890ac366448909c3
			Else h=558B6C241085ED7E5F568B74240C578B7C24148A078AC8C0E90447BA090000003AD11BD2F7DA66F7DA0FB6C96683E2076603D16683C230668916240FB2093AD01BC9F7D966F7D96683E1070FB6D06603CA6683C13066894E0283C6044D75B433C05F6689065E5DC38B54240833C966890A5DC3
		Else h=558B6C241085ED7E45568B74240C578B7C24148A078AC8C0E9044780F9090F97C2F6DA80E20702D1240F80C2303C090F97C1F6D980E10702C880C1308816884E0183C6024D75CC5FC606005E5DC38B542408C602005DC3
		VarSetCapacity(fun, StrLen(h) // 2)
		Loop % StrLen(h) // 2
			NumPut("0x" . SubStr(h, 2 * A_Index - 1, 2), fun, A_Index - 1, "Char")
		ptr := A_PtrSize ? "Ptr" : "UInt"
		DllCall("VirtualProtect", ptr, &fun, ptr, VarSetCapacity(fun), "UInt", 0x40, "UInt*", 0)
	}
	VarSetCapacity(hex, A_IsUnicode ? 4 * len + 2 : 2 * len + 1)
	DllCall(&fun, ptr, &hex, ptr, addr, "UInt", len, "CDecl")
	VarSetCapacity(hex, -1) ; update StrLen
	Return hex
}


GetRIDI_PREPARSEDDATA(hDevice, ByRef pData){
	/*
	// Again, read the data size, allocate then retrieve
	GetRawInputDeviceInfo(rawInput->header.hDevice, RIDI_PREPARSEDDATA, NULL, &bufferSize);
	PHIDP_PREPARSED_DATA preparsedData = (PHIDP_PREPARSED_DATA)HeapAlloc(heap, 0, bufferSize);
	GetRawInputDeviceInfo(rawInput->header.hDevice, RIDI_PREPARSEDDATA, preparsedData, &bufferSize);

	UINT WINAPI GetRawInputDeviceInfo(
	  _In_opt_     HANDLE hDevice,
	  _In_         UINT uiCommand,
	  _Inout_opt_  LPVOID pData,
	  _Inout_      PUINT pcbSize
	);
	*/
	global RIDI_PREPARSEDDATA
	res := DllCall("GetRawInputDeviceInfo", "UInt", hDevice, "UInt", RIDI_PREPARSEDDATA, "Ptr", 0, "UInt*", pcbSize, "UInt", 8 + A_PtrSize * 2)
	VarSetCapacity(pData, pcbSize)
	res := DllCall("GetRawInputDeviceInfo", "UInt", hDevice, "UInt", RIDI_PREPARSEDDATA, "Ptr", &pData, "UInt*", pcbSize, "UInt", 8 + A_PtrSize * 2)
	return ErrorLevel
}
