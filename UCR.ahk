/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Uses xHotkey instead of the normal AHK Hotkey command.
https://github.com/Lexikos/xHotkey.ahk

Master Application
*/

#SingleInstance, force

#include Plugins.ahk

UCR := new UCR()
return

Class UCR extends CWindow {
	Plugins := []	; Array containing plugin objects

	MAIN_WIDTH := 800
	MAIN_HEIGHT := 600
	PLUGIN_WIDTH := 600

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
		base.CreateGui()
		Gui, % this.GuiCmd("Add"), Text, ,MAIN WINDOW

		this.Show()
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

	; Handle hotkey binding etc
	Class Hotkey {
		__New(parent){
			this.parent := parent
		}

		Add(key,callback)){
			xHotkey(key,this.Bind(callback,this.parent),1)
		}

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

	Class GuiControl {
		Value := ""
		__New(parent, ControlType, guinum := 1, Options := "", Text := "") {
			static
			local cb

			this.parent := parent

			if (!ControlType) {
				return 0
			}
			Gui, % this.parent.GuiCmd("Add"), % ControlType,% this.vLabel() " g_UCR_gLabel_Router " " hwndctrlHwnd ", % Text
			this.Hwnd := ctrlHwnd
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
		}
	}

}

; Functionality common to all window types
Class CWindow {
	__New(parent){
		if (!parent){
			; Root class
			this.parent := this
		} else {
			this.parent := parent
		}
		this.CreateGui()
	}

	; Prepends HWND to a GUI command
	GuiCmd(cmd){
		return this.hwnd ":" cmd
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

; All gLabels route through here
; gLabel names are memory addresses that route to the object that handles them
_UCR_gLabel_Router:
	Object(SubStr(A_GuiControl,2)).OnChange()
	return

GuiClose:
	ExitApp