/*  XInput by Lexikos
 *  This version of the script uses objects, so requires AutoHotkey_L.
 */


/*
*   Loads and initializes XInput.dll, wrapper functions, and globals/constants.
*
*   Parameters:
*       dll     -   The path or name of the XInput DLL to load.
*                   
*                   xinput1_3.dll     - Windows 7
*                   xinput1_4.dll     - Windows 8
*                   xinput9_1_0.dll   - Vista
*/
XInput_Init(dll="xinput1_3.dll")
{
    global
    if _XInput_hm
        return
    
    ;======== CONSTANTS DEFINED IN XINPUT.H ========

    ; User index definitions
    XUSER_MAX_COUNT   := 4
    XUSER_INDEX_ANY   := 0x0FF
    
    /*
    ; Gamepad thresholds (XInput standards)
    XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE    := 7849
    XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE   := 8689
    XINPUT_GAMEPAD_TRIGGER_THRESHOLD      := 30
    */
    
    ; Values stored in ErrorLevel after calling an XInput function
    ERROR_SUCCESS   := 0x000
    ERROR_EMPTY     := 0x10D2 ; 4306
    ERROR_DEVICE_NOT_CONNECTED   := 0X48F ; 1167

    
    /* ------------------------------------------
    *   Xinput_GetCapabilities constants
    */
    
    ; Type - Device types
    ;XINPUT_DEVTYPE_GAMEPAD   := 0x01

    ; SubType - Device subtypes
    XINPUT_DEVSUBTYPE_UNKNOWN          := 0x00
    XINPUT_DEVSUBTYPE_GAMEPAD          := 0x01
    XINPUT_DEVSUBTYPE_WHEEL            := 0x02
    XINPUT_DEVSUBTYPE_ARCADE_STICK     := 0x03
    XINPUT_DEVSUBTYPE_FLIGHT_SICK      := 0x04
    XINPUT_DEVSUBTYPE_DANCE_PAD        := 0x05
    XINPUT_DEVSUBTYPE_GUITAR           := 0x06
    XINPUT_DEVSUBTYPE_GUITAR_ALTERNATE := 0x07
    XINPUT_DEVSUBTYPE_DRUM_KIT         := 0x08
    XINPUT_DEVSUBTYPE_GUITAR_BASS      := 0x0B
    XINPUT_DEVSUBTYPE_ARCADE_PAD       := 0x13
    
    ; Flags
    XINPUT_CAPS_VOICE_SUPPORTED   := 0x0004
    ; For Windows 8 only
    XINPUT_CAPS_FFB_SUPPORTED     := 0x0001
    XINPUT_CAPS_WIRELESS          := 0x0002
    XINPUT_CAPS_PMD_SUPPORTED     := 0x0008
    XINPUT_CAPS_NO_NAVIGATION     := 0x0010

    ; Buttons (bitmask, bitwise OR combination)
    XINPUT_GAMEPAD_DPAD_UP          := 0x0001
    XINPUT_GAMEPAD_DPAD_DOWN        := 0x0002
    XINPUT_GAMEPAD_DPAD_LEFT        := 0x0004
    XINPUT_GAMEPAD_DPAD_RIGHT       := 0x0008
    XINPUT_GAMEPAD_START            := 0x0010
    XINPUT_GAMEPAD_BACK             := 0x0020
    XINPUT_GAMEPAD_LEFT_THUMB       := 0x0040
    XINPUT_GAMEPAD_RIGHT_THUMB      := 0x0080
    XINPUT_GAMEPAD_LEFT_SHOULDER    := 0x0100
    XINPUT_GAMEPAD_RIGHT_SHOULDER   := 0x0200
    XINPUT_GAMEPAD_A                := 0x1000
    XINPUT_GAMEPAD_B                := 0x2000
    XINPUT_GAMEPAD_X                := 0x4000
    XINPUT_GAMEPAD_Y                := 0x8000

    /** --------------------------------------
    *   Xinput_GetKeystroke constants
    */
    ;GetKeystroke is not implemented at the moment but may work in a future xinput dll
    
    /*
    ; Unicode - Reserved values
    XINPUT_FLAG_GAMEPAD      := 0x01
    XINPUT_FLAG_KEYBOARD     := 
    XINPUT_FLAG_REMOTE       := 
    XINPUT_FLAG_BIGBUTTON    := 
    XINPUT_FLAG_ANYDEVICE    := 
    XINPUT_FLAG_ANYUSER      := 
    */
    
    ; VirtualKey
    VK_PAD_A                  := 0x5800
    VK_PAD_B                  := 0x5801
    VK_PAD_X                  := 0x5802
    VK_PAD_Y                  := 0x5803
    VK_PAD_RSHOULDER          := 0x5804
    VK_PAD_LSHOULDER          := 0x5805
    VK_PAD_LTRIGGER           := 0x5806
    VK_PAD_RTRIGGER           := 0x5807

    VK_PAD_DPAD_UP            := 0x5810
    VK_PAD_DPAD_DOWN          := 0x5811
    VK_PAD_DPAD_LEFT          := 0x5812
    VK_PAD_DPAD_RIGHT         := 0x5813
    VK_PAD_START              := 0x5814
    VK_PAD_BACK               := 0x5815
    VK_PAD_LTHUMB_PRESS       := 0x5816
    VK_PAD_RTHUMB_PRESS       := 0x5817

    VK_PAD_LTHUMB_UP          := 0x5820
    VK_PAD_LTHUMB_DOWN        := 0x5821
    VK_PAD_LTHUMB_RIGHT       := 0x5822
    VK_PAD_LTHUMB_LEFT        := 0x5823
    VK_PAD_LTHUMB_UPLEFT      := 0x5824
    VK_PAD_LTHUMB_UPRIGHT     := 0x5825
    VK_PAD_LTHUMB_DOWNRIGHT   := 0x5826
    VK_PAD_LTHUMB_DOWNLEFT    := 0x5827

    VK_PAD_RTHUMB_UP          := 0x5830
    VK_PAD_RTHUMB_DOWN        := 0x5831
    VK_PAD_RTHUMB_RIGHT       := 0x5832
    VK_PAD_RTHUMB_LEFT        := 0x5833
    VK_PAD_RTHUMB_UPLEFT      := 0x5834
    VK_PAD_RTHUMB_UPRIGHT     := 0x5835
    VK_PAD_RTHUMB_DOWNRIGHT   := 0x5836
    VK_PAD_RTHUMB_DOWNLEFT    := 0x5837
    
    ; Flags
    XINPUT_KEYSTROKE_KEYDOWN   := 0x0001
    XINPUT_KEYSTROKE_KEYUP     := 0x0002
    XINPUT_KEYSTROKE_REPEAT    := 0x0004
    
    /** -----------------------------------------------
    *   Xinput_GetBatteryInformation constants
    */
    
    ; Type - Devices that support batteries
    BATTERY_DEVTYPE_GAMEPAD   :=  0x00
    BATTERY_DEVTYPE_HEADSET   :=  0x01
    
    ; BatteryType - battery status level
    BATTERY_TYPE_DISCONNECTED   := 0x00 ; This device is not connected
    BATTERY_TYPE_WIRED          := 0x01 ; Wired device, no battery
    BATTERY_TYPE_ALKALINE       := 0x02 ; Alkaline battery source
    BATTERY_TYPE_NIMH           := 0x03 ; Nickel Metal Hydride battery source
    BATTERY_TYPE_UNKNOWN        := 0xFF ; Cannot determine the battery type
    
    ; BatteryLevel
    ; These are only valid for wireless, connected devices, with known battery types
    ; The amount of use time remaining depends on the type of device.
    BATTERY_LEVEL_EMPTY    := 0x00
    BATTERY_LEVEL_LOW      := 0x01
    BATTERY_LEVEL_MEDIUM   := 0x02
    BATTERY_LEVEL_FULL     := 0x03
    
    ;=============== END CONSTANTS =================
    
    _XInput_hm := DllCall("LoadLibrary" ,"str", dll)
    
    if !_XInput_hm {
        MsgBox, Failed to initialize XInput: %dll%.dll not found.
        return
    }

    _XInput_GetState        := DllCall("GetProcAddress", "uint", _XInput_hm, "uint", 100) ; guide/home button works with this. __stdcall int secret_get_gamepad (int, XINPUT_GAMEPAD_SECRET*)
    ;_XInput_GetState       := DllCall("GetProcAddress", "uint", _XInput_hm, "AStr", "XInputGetState")
    _XInput_SetState        := DllCall("GetProcAddress", "uint", _XInput_hm, "AStr", "XInputSetState")
    _XInput_GetKeystroke    := DllCall("GetProcAddress", "uint", _XInput_hm, "AStr", "XInputGetKeystroke")  
    _XInput_GetCapabilities := DllCall("GetProcAddress", "uint", _XInput_hm, "AStr", "XInputGetCapabilities")
    _XInput_GetBatteryInformation := DllCall("GetProcAddress", "uint", _XInput_hm, "AStr", "XInputGetBatteryInformation")
    
    ;OnExit, XInput_Term__
    if !(_XInput_GetState && _XInput_SetState && _XInput_GetKeystroke && _XInput_GetCapabilities && _XInput_GetBatteryInformation) {
        XInput_Term()
        MsgBox, Failed to initialize XInput: function not found.
        return
    }
}


/*
*   Unloads XInput library/dll if it has been previously loaded.
*/
XInput_Term() {
    ;XInput_Term__:
    global
    if _XInput_hm {
        DllCall("FreeLibrary", "uint", _XInput_hm)
        _XInput_hm :=_0
        _XInput_GetState := 0
        _XInput_SetState := 0
        _XInput_GetKeystroke := 0
        _XInput_GetCapabilities := 0
        _XInput_GetBatteryInformation := 0
    }
}


/*
*   Retrieves the current state of the specified controller.
*
*   Parameters:
*       UserIndex        -   [in] Index of the signed-in gamer associated with the device. 
*                                 Can be a value of 0 to XUSER_MAX_COUNT - 1.
*
*   Returns:
*       If the function succeeds, the return value is object containing the xinput state, 0 otherwise.
*       {
*           UserIndex     ; Index of the user's controller. Can be a value of 0 to XUSER_MAX_COUNT - 1.
*           PacketNumber  ; (unused) This value increments whenever the state of the gamepad changes.
*           Buttons       ; Which buttons are pressed (Bitwise OR).
*           LeftTrigger   ; Between 0 and 255
*           RightTrigger
*           ThumbLX       ; Between -32768 to 32767. 0 is centered. Negative is down or left.
*           ThumbLY
*           ThumbRX
*           ThumbRY
*       }
*
*   Remarks:
*       If the function succeeds, ErrorLevel will be set to ERROR_SUCCESS (0).
*       If the controller is not connected, ErrorLevel will be set to ERROR_DEVICE_NOT_CONNECTED (1167).
*       Otherwise ErrorLevel is set to the error code defined in Winerror.h.
*/
XInput_GetState(UserIndex = 0) 
{
    global _XInput_GetState
    VarSetCapacity(xiState, 16)
    if ErrorLevel := DllCall(_XInput_GetState, "uint", UserIndex , "uint", &xiState)
        return 0
    
    return {
        (Join,
            UserIndex    : UserIndex
            PacketNumber : NumGet(xiState, 0) 
            Buttons      : NumGet(xiState, 4, "UShort")
            LeftTrigger  : NumGet(xiState, 6, "UChar")
            RightTrigger : NumGet(xiState, 7, "UChar")
            ThumbLX      : NumGet(xiState, 8, "Short")
            ThumbLY      : NumGet(xiState, 10, "Short")
            ThumbRX      : NumGet(xiState, 12, "Short")
            ThumbRY      : NumGet(xiState, 14, "Short")
        )}
}


/*
*   Retrieves a gamepad input event.
*
*   Parameters:
*       UserIndex        -   [in] Index of the signed-in gamer associated with the device. 
*                                 Can be a value of 0 to XUSER_MAX_COUNT - 1, 
*                                 or XUSER_INDEX_ANY (0x0FF) to fetch the next available input event from any user.
*
*   Returns:
*       If the function succeeds, the return value is object containing the xinput event, 0 otherwise.
*       {
*           VirtualKey   ; VirtualKey   ; Virtual-key code of the key, button, or stick movement. 
*           ;Unicode     ; (unused) This member is unused and the value is zero.
*           Flags        ; Flags that indicate the keyboard state at the time of the input event. 
*           UserIndex    ; Index of the signed-in gamer associated with the device. Can be a value in the range 0–3.
*           HidCode      ; HID code corresponding to the input. If there is no corresponding HID code, this value is zero.
*       }   
*
*    Remarks:
*       If the function succeeds, ErrorLevel will be set to ERROR_SUCCESS (0).
*       If no new keys have been pressed, ErrorLevel will be set to XINPUT_ERROR_EMPTY (4306).
*       If the controller is not connected, ErrorLevel will be set to ERROR_DEVICE_NOT_CONNECTED (1167).
*       Otherwise ErrorLevel is set to the error code defined in Winerror.h.
*/
XInput_GetKeystroke(UserIndex = 0x0FF) ; XUSER_INDEX_ANY = 0x0FF
{
    global _XInput_GetKeystroke
    VarSetCapacity(xiKeystroke, 8)
    if ErrorLevel := DllCall(_XInput_GetKeystroke, "uint", UserIndex, "uint", 0, "uint", &xiKeystroke)
        return 0
    
    ;Unicode : NumGet(xiKeystroke, 2, "UShort")
    return {
        (Join,
            VirtualKey : NumGet(xiKeystroke, 0, "UShort")
            Flags : NumGet(xiKeystroke, 4, "UShort")
            UserIndex : NumGet(xiKeystroke, 6, "UChar")
            HidCode : NumGet(xiKeystroke, 7, "UChar")
        )}
}

/*
*    Sends data to a connected controller. This function is used to activate the vibration
*    function of a controller.
*    
*   Parameters:
*       UserIndex        -   [in] Index of the user's controller. Can be a value of 0 to XUSER_MAX_COUNT - 1.
*       LeftMotorSpeed   -   [in] Speed of the left motor, between 0 and 65535.
*       RightMotorSpeed  -   [in] Speed of the right motor, between 0 and 65535.
*    
*   Returns:
*       If the function succeeds, the return value is true, otherwise false.
*
*   Remarks:
*       If the function succeeds, ErrorLevel will be set to ERROR_SUCCESS (0).
*       If the controller is not connected, ErrorLevel will be set to ERROR_DEVICE_NOT_CONNECTED (1167).
*       Otherwise ErrorLevel is set to the error code defined in Winerror.h.
*       The left motor is the low-frequency rumble motor. The right motor is the
*           high-frequency rumble motor. The two motors are not the same, and they create
*           different vibration effects.
*/
XInput_SetState(UserIndex, LeftMotorSpeed, RightMotorSpeed)
{
    global _XInput_SetState
    return DllCall(_XInput_SetState ,"uint", UserIndex , "uint*", LeftMotorSpeed|RightMotorSpeed<<16) = 0
}
    
    
/*
*   Retrieves the capabilities and features of a connected controller.
*
*   Parameters:
*       UserIndex  -   [in] Index of the user's controller. Can be a value in the range 0-3.
*       Flags      -   [in] Identifies the controller type.
*                            0   - All controllers.
*                            1   - XINPUT_FLAG_GAMEPAD: Xbox 360 Controllers only.
*
*   Returns:
*       If the function succeeds, the return value is object containing the xinput controller's capabilities, 0 otherwise.
*       {
*           UserIndex    ; Index of the user's controller. Can be a value of 0 to XUSER_MAX_COUNT - 1.
*           Type         ; Currently always XINPUT_DEVTYPE_GAMEPAD (may change in a later version).
*           SubType      ; Subtype of the game controller.
*           Flags        ; Features of the controller.
*           Buttons      ; Bitwise or of available buttons.
*           LeftTrigger  ; Resolution of left trigger (0 means unsupported, 255 for max resolution).
*           RightTrigger
*           ThumbLX      ; Resolution of thumb sticks
*           ThumbLY
*           ThumbRX
*           ThumbRY
*           LeftMotorSpeed  ; Resolution of motor
*           RightMotorSpeed
*       }
*
*   Remarks:
*       If the function succeeds, ErrorLevel will be set to ERROR_SUCCESS (0).
*       If the controller is not connected, ErrorLevel will be set to ERROR_DEVICE_NOT_CONNECTED (1167).
*       Otherwise ErrorLevel is set to the error code defined in Winerror.h.
*/
XInput_GetCapabilities(UserIndex = 0, Flags = 0) 
{
    global _XInput_GetCapabilities
    VarSetCapacity(xiCaps, 20)
    if ErrorLevel := DllCall(_XInput_GetCapabilities, "uint", UserIndex, "uint", Flags, "uint", &xiCaps)
        return 0
    
    return {
        (Join,
            UserIndex : UserIndex
            Type : NumGet(xiCaps, 0 "UChar")
            SubType : NumGet(xiCaps, 1, "UChar")
            Flags : NumGet(xiCaps, 2, "UShort")
            Buttons : NumGet(xiCaps, 4, "UShort")
            LeftTrigger : NumGet(xiCaps, 6, "UChar")
            RightTrigger : NumGet(xiCaps, 7, "UChar")
            ThumbLX : NumGet(xiCaps, 8, "UShort")
            ThumbLY : NumGet(xiCaps, 10, "UShort")
            ThumbRX : NumGet(xiCaps, 12, "UShort")
            ThumbRY : NumGet(xiCaps, 14, "UShort")
            LeftMotorSpeed : NumGet(xiCaps, 16, "UShort")
            RightMotorSpeed : NumGet(xiCaps,  18, "UShort")
        )}
}

/*
*   Retrieves the capabilities and features of a connected controller.
*
*   Parameters:
*       UserIndex  -   [in] Index of the user's controller. Can be a value in the range 0-3.
*       DevType    -   [in] Identifies the controller type
*                            0   - BATTERY_DEVTYPE_GAMEPAD
*                            1   - BATTERY_DEVTYPE_HEADSET
*
*   Returns:
*       If the function succeeds, the return value is true, otherwise false.
*       {
*           UserIndex      ; Index of the user's controller. Can be a value of 0 to XUSER_MAX_COUNT - 1.
*           DevType        ; Specifies which device associated with this user index should be queried. Must be BATTERY_DEVTYPE_GAMEPAD or BATTERY_DEVTYPE_HEADSET.
*           BatteryType    ; The type of battery.
*           BatteryLevel   ; The charge state of the battery. This value is only valid for wireless devices with a known battery type.
*       }
*
    Function: XInput_GetCapabilities
    
    Retrieves the capabilities and features of a connected controller.
        
    Returns:
*       If the function succeeds, ErrorLevel will be set to ERROR_SUCCESS (0).
*       If the controller is not connected, ErrorLevel will be set to ERROR_DEVICE_NOT_CONNECTED (1167).
*       Otherwise ErrorLevel is set to the error code defined in Winerror.h.
*/
XInput_GetBatteryInformation(UserIndex = 0, DevType = 1) 
{
    global _XInput_GetBatteryInformation
    VarSetCapacity(xiBattery, 8) ; actually 7 but 8 may have better performance
    if ErrorLevel := DllCall(_XInput_GetBatteryInformation, "uint", UserIndex, "uchar", DevType, "uint", &xiBattery)
        return 0
    
    return {
        (Join,
            UserIndex : UserIndex
            DevType : DevType
            BatteryType : NumGet(xiBattery, 0, "UChar")
            BatteryLevel : NumGet(xiBattery, 1, "UChar")
        )}
}