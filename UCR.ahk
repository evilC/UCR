/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Uses xHotkey library instead of the normal AHK Hotkey command.
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

#include <AHKHID>
#include Plugins.ahk
#include Lib\Base Classes.ahk
#include Lib\Common.ahk

UCR := new UCR()
return

Class UCR extends CMainWindow {
	desc := "main"	; debugging object label
	Plugins := []	; Array containing plugin objects
	MessageTable := {}
	
	MAIN_WIDTH := 640
	MAIN_HEIGHT := 480
	;PLUGIN_WIDTH := 600

	__New(){
		global _UCR_Plugins	; Array of plugin class names

		base.__New("")

		; Load plugins
		Loop % _UCR_Plugins.MaxIndex() {
			cls := _UCR_Plugins[A_Index]
			this.LoadPlugin(_UCR_Plugins[A_Index])
		}
		
		this.RawInputRegister()
	}

	CreateGui(){
		static
		base.CreateGui()
		Gui, % this.GuiCmd("Add"), Text, ,Hotkeys

		Gui, % this.GuiCmd("Add"), ListView, % "r20 w" this.MAIN_WIDTH " h" this.MAIN_HEIGHT, Name|App (ahk_class)|On/Off
		LV_ModifyCol(1, 100)
		LV_ModifyCol(2, 100)

		this.Show("w" this.MAIN_WIDTH + 10 " h" this.MAIN_HEIGHT + 10, "U C R - Universal Control Remapper")
	}

	RawInputRegister(){
		global RIDEV_INPUTSINK
		;OnMessage(0x00FF, "_UCR_MessageHandler")
		this.RegisterMessage(0x00FF, "InputHandler")
		AHKHID_AddRegister(2)
		AHKHID_AddRegister(1,2,this.hwnd,RIDEV_INPUTSINK)	; Mouse
		AHKHID_AddRegister(1,6,this.hwnd,RIDEV_INPUTSINK)	; Keyboard
		AHKHID_Register()
		Return

	}
	
	Call(){
		msgbox here
	}
	
	InputHandler(wParam, lParam, msg, hwnd){
		global II_DEVTYPE, RIM_TYPEMOUSE, II_MSE_BUTTONFLAGS
		global RI_MOUSE_LEFT_BUTTON_DOWN, RI_MOUSE_LEFT_BUTTON_UP, RI_MOUSE_RIGHT_BUTTON_DOWN, RI_MOUSE_RIGHT_BUTTON_UP, RI_MOUSE_MIDDLE_BUTTON_DOWN, RI_MOUSE_MIDDLE_BUTTON_UP, RI_MOUSE_BUTTON_4_DOWN, RI_MOUSE_BUTTON_4_UP, RI_MOUSE_BUTTON_5_DOWN, RI_MOUSE_BUTTON_5_UP, RI_MOUSE_WHEEL
		global RIM_TYPEKEYBOARD, II_KBD_VKEY, II_KBD_FLAGS, II_KBD_MAKECODE
		global RIM_TYPEHID, II_DEVHANDLE, 
		
		Critical
		r := AHKHID_GetInputInfo(lParam, II_DEVTYPE)
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
						;LV_ADD(,"Mouse", "", "Left Button", "Down")
					}
				}
				If (flags & RI_MOUSE_LEFT_BUTTON_UP){
					if (!HideLeftMouse){
						;LV_ADD(,"Mouse", "", "Left Button", "Up")
					}
				}
				If (flags & RI_MOUSE_RIGHT_BUTTON_DOWN){
					if (!HideRightMouse){
						;LV_ADD(,"Mouse", "", "Right Button", "Down")
					}
				}
				If (flags & RI_MOUSE_RIGHT_BUTTON_UP){
					if (!HideRightMouse){
						;LV_ADD(,"Mouse", "", "Right Button", "Up")
					}
				}
				If (flags & RI_MOUSE_MIDDLE_BUTTON_DOWN){
					;LV_ADD(,"Mouse", "", "Middle Button", "Down")

				}
				If (flags & RI_MOUSE_MIDDLE_BUTTON_UP){
					;LV_ADD(,"Mouse", "", "Middle Button", "Up")
				}
				If (flags & RI_MOUSE_BUTTON_4_DOWN) {
					;LV_ADD(,"Mouse", "", "XButton1", "Down")
				}
				If (flags & RI_MOUSE_BUTTON_4_UP) {
					;LV_ADD(,"Mouse", "", "XButton1", "Up")
				}
				If (flags & RI_MOUSE_BUTTON_5_DOWN) {
					;LV_ADD(,"Mouse", "", "XButton2", "Down")
				}
				If (flags & RI_MOUSE_BUTTON_5_UP) {
					;LV_ADD(,"Mouse", "", "XButton2", "Up")
				}
				If (flags & RI_MOUSE_WHEEL) {
					waswheel := 1
					if (!HideMouseWheel){
						;LV_ADD(,"Mouse", "", "Wheel", Round(AHKHID_GetInputInfo(lParam, II_MSE_BUTTONDATA) / 120))
					}
				}
				waslogged := 1
			}
		} Else If (r = RIM_TYPEKEYBOARD) {
			; keyboard input ======================
			vk := AHKHID_GetInputInfo(lParam, II_KBD_VKEY)
			keyname := GetKeyName("vk" this.ToHex(vk,2))
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
			;s .= keyname
			;waslogged := 1
			;LV_ADD(,"Keyboard", "", s, (flags ? "Up" : "Down") )
		} Else If (r = RIM_TYPEHID) {
			; Stick Input ==============
			; reference material: http://www.codeproject.com/Articles/185522/Using-the-Raw-Input-API-to-Process-Joystick-Input
			h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE )
			name := AHKHID_GetDevName(h,1)
			if (name == StickID){
				r := AHKHID_GetInputData(lParam, uData)
				waslogged := 1
				; Why does this not work?? Neet to pull RIDI_PREPARSEDDATA
				;d := AHKHID_GetPreParsedData(h, uData)
				
				; Add to log
				;LV_ADD(,"Joystick", joysticks[name].human_name, "", Bin2Hex(&uData, r))
			}
		}
	}
	
	; Registers a Message for callbacks
	RegisterMessage(msg, callback){
		;this.MessageTable[msg] := bind(callback, context)
		this.MessageTable[msg] := callback
		OnMessage(msg, "_UCR_MessageHandler")
	}
	
	; Routes incoming windows messages
	MessageHandler(wParam, lParam, msg, hwnd){
		fn := this.MessageTable[msg]
		if (fn){
		;if (IsObject(fn)){
			;%fn%(wParam, lParam, msg, hwnd)
			this[fn](wParam, lParam, msg, hwnd)
		}
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
		Gui, % this.GuiDefault()
		LV_Delete()
		;for i, hotkey in this.GetHotkeys() {
		;	LV_Add(,hotkey.Name, hotkey["Off?"] ? hotkey["Off?"] : "On")
		;}
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
	}

}



_UCR_MessageHandler(wParam, lParam, msg, hwnd){
	global UCR
	UCR.MessageHandler(wParam, lParam, msg, hwnd)
}

GuiClose:
	ExitApp