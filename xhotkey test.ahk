#singleinstance force

USE_XHOTKEY := 1

LastHotkey := ""

WIDTH := 350
HEIGHT := 550
Gui, Add, Text, % "w" WIDTH " center", xHotkey.hk
Gui, Add, ListView, % "vHKList w200 h200 w" WIDTH, Name|App (ahk_class)|On/Off
LV_ModifyCol(1, 80)
LV_ModifyCol(2, 140)
Gui, Add, Text, % "w" WIDTH " center", Debug Log
Gui, Add, ListView, % "vDebugLog xm w200 h200 w" WIDTH, Action|Hotkey|App
LV_ModifyCol(1, 80)
LV_ModifyCol(2, 100)
LV_ModifyCol(3, 140)
Gui, Add, Text, xm w50 h20, Hotkey: 
Gui, Add, Edit, gOptionChanged vHotkeyBox w100 xp+60 yp-3

Gui, Add, Text, % "x" (WIDTH / 2) + 20 " yp+3 w50 h20 Section", ahk_class: 
Gui, Add, Edit, gOptionChanged vAppBox w100 xp+60 yp-3


Gui, Add, Text,% "xm w" WIDTH " Center", Modifiers

Gui, Add, CheckBox, x40 yp+10 section vPassThruBox gOptionChanged
Gui, Add, CheckBox, yp+20 vWildBox gOptionChanged
Gui, Add, CheckBox, yp+20 vDollarBox gOptionChanged

Gui, Add, Text, xp+30 ys, `~ Pass Through
Gui, Add, Text, yp+20, * Wild
Gui, Add, Text, yp+20, $ Send doesnt trigger

Gui, Add, CheckBox, x270 ys section vAltBox gOptionChanged
Gui, Add, CheckBox, yp+20 vCtrlBox gOptionChanged
Gui, Add, CheckBox, yp+20 vShiftBox gOptionChanged
Gui, Add, CheckBox, yp+20 vWinBox gOptionChanged

Gui, Add, Text, xp+30 ys, ! Alt
Gui, Add, Text, yp+20, ^ Ctrl
Gui, Add, Text, yp+20, + Shift
Gui, Add, Text, yp+20, # Win
		


Gui, Show, % "w "WIDTH + 20 " h" HEIGHT + 20, xHotkey Test

return

OptionChanged:
	Gui, Submit, NoHide
	prefix := BuildPrefixes()
	; Remove old hotkey
	if (LastHotkey){
		Gui, ListView, DebugLog
		if (USE_XHOTKEY){
			xHotkey(LastHotkey,, 0)
		} else {
			Hotkey, % LastHotkey,, Off
		}
		LV_ADD(,"Removing",LastHotkey,"Global")
		LastHotkey := ""
	}
	; Add new hotkey
	hk := StrLower(GetKeyName(HotkeyBox))
	if (hk){
		Gui, ListView, DebugLog
		hk := prefix hk
		if (USE_XHOTKEY){
			try {
				xHotkey(hk, "Test", 1)
				LV_ADD(,"Adding",hk,"Global")
				LastHotkey := hk
			} catch {
				LV_ADD(,"Ignoring",HotkeyBox,"Global")
			}
		} else {
			Hotkey, % hk, Test, On
			LV_ADD(,"Adding",hk,"Global")
		}
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
	soundbeep
	return
}

BuildPrefixes(){
	Gui, Submit, Nohide
	global PassThruBox, WildBox, DollarBox, AltBox, CtrlBox, ShiftBox, WinBox
	ret := ""
	ret .= PassThruBox ? "~" : ""
	ret .= WildBox ? "*" : ""
	ret .= DollarBox ? "$" : ""
	ret .= AltBox ? "!" : ""
	ret .= CtrlBox ? "^" : ""
	ret .= ShiftBox ? "+" : ""
	ret .= WinBox ? "#" : ""
	return ret
}

ToolTipOff:
	Tooltip
	return

GuiClose:
	ExitApp
