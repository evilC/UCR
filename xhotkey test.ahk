; xHotkey test / demo script
#singleinstance force

USE_XHOTKEY := 1 ; Use 0 to use regular AHK Hotkey command for compatibility testing.

LastHotkey := ""

WIDTH := 350
HEIGHT := 460
Gui, Add, Text, % "w" WIDTH " center", xHotkey.hk
Gui, Add, ListView, % "vHKList w200 h200 w" WIDTH, Name|App (ahk_class)|On/Off
LV_ModifyCol(1, 80)
LV_ModifyCol(2, 140)
Gui, Add, Text, % "w" WIDTH " center", Debug Log
Gui, Add, ListView, % "vDebugLog xm w200 h200 w" WIDTH, Action|Hotkey|App
LV_ModifyCol(1, 80)
LV_ModifyCol(2, 100)
LV_ModifyCol(3, 140)
Gui, Add, Text, xm w50 h20 Section, Hotkey: 
Gui, Add, Edit, gOptionChanged vEditBox w100 xp+60 yp-3

Gui, Show, % "w "WIDTH + 20 " h" HEIGHT + 20, xHotkey Test

return

OptionChanged:
    Gui, Submit, NoHide
    ; Remove old hotkey
    if (LastHotkey){
        Gui, ListView, DebugLog
        tmp := "~" LastHotkey
        if (USE_XHOTKEY){
            xHotkey(tmp,, 0)
        } else {
            Hotkey, % tmp,, Off
        }
        LV_ADD(,"Removing",hk,"Global")
        LastHotkey := ""
    } else {
        LV_ADD(,"Ignoring",LastHotkey,"Global")
    }
    ; Add new hotkey
    hk := StrLower(GetKeyName(EditBox))
    if (hk){
        Gui, ListView, DebugLog
        tmp := "~" hk
        if (USE_XHOTKEY){
            xHotkey(tmp, "Test", 1)
        } else {
            Hotkey, % tmp, Test, On
        }
        LV_ADD(,"Adding",hk,"Global")
        LastHotkey := hk
    } else {
        LV_ADD(,"Ignoring",EditBox,"Global")
    }
    ; Update hotkey debug listview
    Gui, ListView, HKList
    LV_Delete()
    ; Query xHotkey for hotkey list
    for name, obj in xHotkey.hk {
        ; Process global variant
        if (isObject(obj.gvariant)){
            LV_Add(, (obj.gvariant.hasTilde ? "~" : "") name, "global", (obj.gvariant.enabled ? "On" : "Off") )
        }
        ; Process per-app variants
        Loop % obj.variants.MaxIndex(){
            LV_Add(, (obj.variants[A_Index].hasTilde ? "~" : "") name
                , substr(obj.variants[A_Index].base.WinTitle,11)
                , (obj.variants[A_Index].enabled ? "On" : "Off") )
        }
    }
        return

Test(){
    Test:
    global LastHotkey
    Tooltip % LastHotkey
    SetTimer, ToolTipOff, 500
    return
}

ToolTipOff:
    Tooltip
    return

GuiClose:
    ExitApp
