/*
	UCR Main bootstrap file
	
	The recommended editor for UCR is Scite4AutoHotkey
	https://autohotkey.com/boards/viewtopic.php?t=62
*/
#SingleInstance force
#MaxThreads 255
#NoEnv

SetKeyDelay, 0, 0   ; Default to no delay, as UCR does not send presses, it holds or releases

; GUID used to start RPC for UCR
UCRguid := "{E97F3D9C-47D5-47EA-92FB-2974647DB131}"

try parentProfileName = %1% ; First passed parameters defines a root profile name, this can alternatively be a GUID
try childProfileName = %2% ; The second parameter is the name of a child profile under the system profile

OutputDebug DBGVIEWCLEAR
SetBatchLines, -1
global UCR	; set UCR as a super-global NOW so that it is super-global while the Constructor is executing
new _UCR()	; The first line of the constructor will store the class instance in the UCR super-global
ObjRegisterActive(UCR, UCRguid) ; Register UCR object so that other scripts can get to it.
UCR.ChangeProfileByName(parentProfileName, childProfileName, 0) ; Change profile if parameters was passed to the script
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
#Include Functions\CreateGUID.ahk

; Called if the user closes the GUI
GuiClose(hwnd){
	UCR.GuiClose(hwnd)
}

; Func allows the MessageHandler thread to register messages in this thread
UCR_OnMessageCreate(msg,hwnd,fnPtr){
	OnMessage(msg+0,hwnd+0,Object(fnPtr+0))
}

; Func to allow RPC from remote scripts
ObjRegisterActive(Object, CLSID, Flags:=0) {
    static cookieJar := {}
    if (!CLSID) {
        if (cookie := cookieJar.Remove(Object)) != ""
            DllCall("oleaut32\RevokeActiveObject", "uint", cookie, "ptr", 0)
        return
    }
    if cookieJar[Object]
        throw Exception("Object is already registered", -1)
    VarSetCapacity(_clsid, 16, 0)
    if (hr := DllCall("ole32\CLSIDFromString", "wstr", CLSID, "ptr", &_clsid)) < 0
        throw Exception("Invalid CLSID", -1, CLSID)
    hr := DllCall("oleaut32\RegisterActiveObject"
        , "ptr", &Object, "ptr", &_clsid, "uint", Flags, "uint*", cookie
        , "uint")
    if hr < 0
        throw Exception(format("Error 0x{:x}", hr), -1)
    cookieJar[Object] := cookie
}