/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Uses xHotkey instead of the normal AHK Hotkey command.
https://github.com/Lexikos/xHotkey.ahk

Master Application

ToDo:
* Normalize names / locations of classes etc.
  Naming convention? _ Prefix for "internal"?

* Hotkey Gui Control - Edit box / bind button(s)

* Hotkey authority from main class.
  Convenient way for main class to instruct a plugin to disable / re-enable hotkeys

* Profile system
  Instruct Plugins to "Load" / "Save"
  Save global settings
  INI / XML etc

* Joystick / vJoy intergration
  Endless loop / timer for polling input axes / emulating joystick button up events?

* Hotkey detection ("Binding") system.
  Current Input based systems lacking.

* Windows API / DirectInput library?
  
* Installer / dependency manager
  ASPDM?

* QuickBind system

* Global Hotkeys / Swap profile via popup or OSD etc

* Nesting / Grouping Plugins?
  One plugin with 4 axes = 4x 1 axis plugins nested?

* Window management
  Emulated taskbar to select plugin
  Fixed size UI?

* Chaining output?
  eg Key with shift states also with Toggle?

* Plugin inter-communication?
  Shift states etc - couldn't all be nested?

* Help / Tooltip system

*/

#SingleInstance, force

#include Plugins.ahk

UCR := new UCR()
return

Class UCR extends CWindow {
	Plugins := []	; Array containing plugin objects

	MAIN_WIDTH := 200
	MAIN_HEIGHT := 200
	;PLUGIN_WIDTH := 600

	__New(){
		global _UCR_Plugins	; Array of plugin class names

		base.__New("")

		; Load plugins
		Loop % _UCR_Plugins.MaxIndex() {
			cls := _UCR_Plugins[A_Index]
			this.LoadPlugin(_UCR_Plugins[A_Index])
		}
	}

	CreateGui(){
		static
		base.CreateGui()
		Gui, % this.GuiCmd("Add"), Text, ,Hotkeys

		Gui, % this.GuiCmd("Add"), ListView, % "r20 w" this.MAIN_WIDTH " h" this.MAIN_HEIGHT, Name|On/Off
		LV_ModifyCol(1, 100)

		this.Show("w" this.MAIN_WIDTH + 10 " h" this.MAIN_HEIGHT + 10, "U C R - Universal Control Remapper")
	}

	; Adds a plugin - likely called before class instantiated, so beware "this"!
	RegisterPlugin(name){
		global _UCR_Plugins
		if (!_UCR_Plugins.MaxIndex()){
			_UCR_Plugins := []
		}
		_UCR_Plugins.Insert(name)
	}

	LoadPlugin(name){
		this.Plugins.Insert(new %name%(this))
	}

	OnChange(){
		;soundbeep
		Gui, % this.GuiDefault()
		LV_Delete()
		for i, hotkey in this.GetHotkeys() {
			LV_Add(,hotkey.Name, hotkey["Off?"] ? hotkey["Off?"] : "On")
		}
	}

	; GetHotkeys - pull the HotkeyList into an Array, so we can show current hotkeys in memory (for debugging purposes)
	; From http://ahkscript.org/boards/viewtopic.php?p=31849#p31849
	GetHotkeys(){
		static hEdit, pSFW, pSW, bkpSFW, bkpSW

		if !hEdit
		{
			dhw := A_DetectHiddenWindows
			DetectHiddenWindows, On
			ControlGet, hEdit, Hwnd,, Edit1, ahk_id %A_ScriptHwnd%
			DetectHiddenWindows %dhw%

			AStr := A_IsUnicode ? "AStr" : "Str"
			Ptr := A_PtrSize == 8 ? "Ptr" : "UInt"
			hmod := DllCall("GetModuleHandle", "Str", "user32.dll")
			pSFW := DllCall("GetProcAddress", Ptr, hmod, AStr, "SetForegroundWindow")
			pSW := DllCall("GetProcAddress", Ptr, hmod, AStr, "ShowWindow")
			DllCall("VirtualProtect", Ptr, pSFW, Ptr, 8, "UInt", 0x40, "UInt*", 0)
			DllCall("VirtualProtect", Ptr, pSW, Ptr, 8, "UInt", 0x40, "UInt*", 0)
			bkpSFW := NumGet(pSFW+0, 0, "Int64")
			bkpSW := NumGet(pSW+0, 0, "Int64")
		}

		if (A_PtrSize == 8)
		{
			NumPut(0x0000C300000001B8, pSFW+0, 0, "Int64")  ; return TRUE
			NumPut(0x0000C300000001B8, pSW+0, 0, "Int64")   ; return TRUE
		}
		else
		{
			NumPut(0x0004C200000001B8, pSFW+0, 0, "Int64")  ; return TRUE
			NumPut(0x0008C200000001B8, pSW+0, 0, "Int64")   ; return TRUE
		}

		ListHotkeys

		NumPut(bkpSFW, pSFW+0, 0, "Int64")
		NumPut(bkpSW, pSW+0, 0, "Int64")

		ControlGetText, text,, ahk_id %hEdit%

		static cols
		hotkeys := []
		for each, field in StrSplit(text, "`n", "`r")
		{
			if (A_Index == 1 && !cols)
				cols := StrSplit(field, "`t")
			if (A_Index <= 2 || field == "")
				continue

			out := {}
			for i, fld in StrSplit(field, "`t")
				out[ cols[A_Index] ] := fld
			static ObjPush := Func(A_AhkVersion < "2" ? "ObjInsert" : "ObjPush")
			%ObjPush%(hotkeys, out)
		}
		return hotkeys
	}


	; Add or remove a binding
	Class Hotkey extends UCRCommon {
		CurrentKey := ""
		State := 0
		CallbackDown := ""
		CallbackUp := ""
		CallbackContext := ""

		__New(parent){
			this.parent := parent
		}

		; IMPORTANT! Be sure to pass the correct context to Add. Context alters the "scope" which is passed when a callback is called
		; If you pass "this.Fire" to callback_down, be sure to pass "this" to context.
		Add(key, callback_down, callback_up, context*) {
			if (this.CurrentKey){
				this.Remove()
			}
			if (GetKeyName(key)){
				this.CallbackContext := context
				this.CallbackDown := callback_down
				this.CallbackUp := callback_up
				xHotkey("~" key, this.Bind(this.DownEvent,this), 1)
				xHotkey("~" key " up", this.Bind(this.UpEvent,this), 1)
				this.CurrentKey := key
				return 1
			} else {
				this.Remove()
				return 0
			}
		}

		Remove(){
			if (this.CurrentKey){
				xHotkey("~" this.CurrentKey,,0)
				xHotkey("~" this.CurrentKey " up",,0)
				this.CurrentKey := ""
				this.State := 0
				return 1
			} else {
				return 0
			}
		}

		; Trap down events so we can keep internal tabs on state etc
		DownEvent(){
			; Suppress "Key repeat" down events - if key held normally, down event repeatedly fired.
			if (this.State == 0){
				this.State := 1
				if (this.CallbackDown){
					; Call Callback function with specified context
					fn := this.Bind(this.CallbackDown, this.CallbackContext*)
					%fn%()
				}
			}
		}

		UpEvent(){
			if (this.State == 1){
				this.State := 0
				if (this.CallbackUp){
					fn := this.Bind(this.CallbackUp, this.CallbackContext*)
					%fn%()
				}
			}
		}
	}

	Class GuiControl extends CGuiItem {
		Value := ""
		__New(parent, ControlType, Options := "", Text := "") {
			this.parent := parent

			if (!ControlType,Text) {
				return 0
			}
			this.CreateControl(ControlType,Text)
		}

		CreateControl(ControlType){
			static
			Gui, % this.GuiCmd("Add"), % ControlType,% this.vLabel() " g_UCR_gLabel_Router " " hwndctrlHwnd ", % Text
			this.Hwnd := ctrlHwnd
		}

		GuiCmd(name){
			return this.parent.GuiCmd(name)
		}

		vLabel(){
			return "v" this.Addr()
		}

		Addr(){
			return "#" Object(this)
		}

		OnChange(){
			GuiControlGet, OutputVar, , % this.Hwnd
			this.Value := OutputVar
			this.parent.OnChange()
		}


	}

	; Base class to derive from for Plugins
	Class Plugin Extends CWindow {
		__New(parent){
			base.__New(parent)
		}

		OnChange(){
			; Extend this class to receive change events from GUI items

			; Fire parent's OnChange event, so it can trickle up to root
			this.parent.OnChange()
		}
	}

}

; Functionality common to all window types
Class CWindow extends CGuiItem {
	; Prepends HWND to a GUI command
	GuiCmd(cmd){
		return this.hwnd ":" cmd
	}

	; Useful eg for ListView commands which work on default Gui
	GuiDefault(){
		return this.GuiCmd("Default")
	}

	CreateGui(){
		if (this.parent == this){
			; Root window
			Gui, New, hwndGuiHwnd
		} else {
			; Plugin / Sidebar etc
			Gui, New, hwndGuiHwnd
		}

		this.hwnd := GuiHwnd
	}

	Show(options := "", title := ""){
		Gui, % this.GuiCmd("Show"), % options, % title
	}

}

; Functionality common to all things that have a GUI presence
Class CGuiItem extends UCRCommon {
	__New(parent){
		if (!parent){
			; Root class
			this.parent := this
		} else {
			this.parent := parent
		}
		this.CreateGui()
	}
}

; Common functions for all UCR classes
Class UCRCommon {
	; "Function Binding" methods for changing the context / scope of a call to a class method
	Bind(fn, args*) {
	    return new this.BoundFunc(fn, args*)
	}

	class BoundFunc {
	    __New(fn, args*) {
	        this.fn := IsObject(fn) ? fn : Func(fn)
	        this.args := args
	    }
	    __Call(callee) {
	        if (callee = "") {
	            fn := this.fn
	            return %fn%(this.args*)
	        }
	    }
	}
}

; All gLabels route through here
; gLabel names are memory addresses that route to the object that handles them
_UCR_gLabel_Router:
	Object(SubStr(A_GuiControl,2)).OnChange()
	return

GuiClose:
	ExitApp