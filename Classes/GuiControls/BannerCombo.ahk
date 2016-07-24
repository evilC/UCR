; ======================================================================== BANNER COMBO ===============================================================
; Wraps a ComboBox GuiControl to turn it into a DDL with a "Cue Banner" 1st item, that is re-selected after every choice.
class _BannerCombo {
	__New(ParentHwnd, aParams*){
		this._ParentHwnd := ParentHwnd
		this._Ptr := &this
		Gui, % this._ParentHwnd ":Add", % "Combobox", % "hwndhwnd " aParams[1], % aParams[2]
		this.hwnd := hwnd
		
		fn := this.__ChangedValue.Bind(this)
		GuiControl, % this._ParentHwnd ":+g", % this.hwnd, % fn
		
		; Get Hwnd of EditBox part of ComboBox
		this._hEdit := DllCall("GetWindow","PTR",this.hwnd,"Uint",5) ;GW_CHILD = 5
		
		; == Hack to stop Mouse Wheel changing option when the control is focused.
		; ToDo: Find better solution (Probably involves changing AHK_H source code)
		; In a scrolling environment, this is really annoying.
		; Not the best solution, as if you scroll while the list is open, the list doesn't move.
		; Get the position of the Editbox
		ControlGetPos,x,y,,,,% "ahk_id " this._hEdit
		; Set the parent of the editbox to the main Gui instead of the Combobox
		DllCall("SetParent","PTR",this._hEdit,"PTR",this._ParentHwnd)
		; Move the Editbox back to where it should be
		ControlMove,,% x,% y,,,% "ahk_id " this._hEdit
		; == End Hack
	}
	
	; Pass an array of strings to set available options
	SetOptions(opts){
		str := "|", max := opts.length()
		Loop % max{
			str .= opts[A_Index]
			if (A_Index != max){
				str .= "|"
			}
		}
		GuiControl,% this._ParentHwnd ":" , % this.hwnd, % str
	}
	
	; Sets the text of the Cue Banner
	SetCueBanner(text){
		static EM_SETCUEBANNER:=0x1501
		DllCall("User32.dll\SendMessageW", "Ptr", this._hEdit, "Uint", EM_SETCUEBANNER, "Ptr", True, "WStr", text)
	}
	
	; The control changed through user interaction
	__ChangedValue(){
		; Find index of dropdown list. Will be really big number if text was typed into the Editbox
		SendMessage 0x147, 0, 0,, % "ahk_id " this.hwnd  ; CB_GETCURSEL
		o := ErrorLevel
		; Reset DDL to position 0 (The "Cue Banner")
		GuiControl, % this._ParentHwnd ":Choose", % this.hwnd, 0
		; Filter typed text
		if (o < 100){
			o++
			this._ChangedValue(o)
		}
	}
	
	; Override
	_ChangedValue(o){
		
	}
	
	; All Input controls should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		; do nothing
	}
}
