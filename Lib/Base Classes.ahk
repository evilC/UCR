; The Main window will derive from this class
Class CMainWindow Extends CWindow {
	Class GuiControl extends CGuiItem {
		desc := "control"
		Value := ""
		name := "ctrl"
		__New(parent, ControlType, Options := "", Text := "", name := "") {
			this.parent := parent
			this.name := name

			if (!ControlType,Text) {
				return 0
			}
			this.CreateControl(ControlType, Options, Text)
			this.Value := Text
		}

		CreateControl(ControlType, Options, Text){
			static
			Gui, % this.GuiCmd("Add"), % ControlType,% this.vLabel() " hwndctrlHwnd " Options, % Text
			fn := bind(this.OnChange, this)  ; Bind parameters to a function.
			GuiControl +g, %ctrlHwnd%, %fn%
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
		
		Test(s:="") {
			MsgBox Test`n%s%
		}

	}

	; Add or remove a binding
	Class Hotkey extends UCRCommon {
		keyup_enabled := 1
		desc := "hotkey"
		CurrentKey := ""
		CurrentApp := ""
		State := 0
		CallbackDown := ""
		CallbackUp := ""
		CallbackContext := ""
		Modifiers := ["~", "*", "$", "!", "^", "+", "#"]

		__New(parent){
			this.parent := parent
		}

		; IMPORTANT! Be sure to pass the correct context to Add. Context alters the "scope" which is passed when a callback is called
		; If you pass "this.Fire" to callback_down, be sure to pass "this" to context.
		Add(key, app := "", callback_down := "", callback_up := "", context*) {
			if (this.CurrentKey){
				this.Remove()
			}
			; Check that the hotkey is not just modifiers
			if (this.StripModifiers(key)){
				if (app){
					xHotkey.IfWinActive("ahk_class " app)
					this.CurrentApp := app
				} else {
					xHotkey.IfWinActive()
					this.CurrentApp := ""
				}
				try {
					xHotkey(key, bind(this.DownEvent,this), 1)
					if (this.keyup_enabled){
						xHotkey(key " up", bind(this.UpEvent,this), 1)
					}
					
					; try worked - continue
					this.CallbackContext := context
					this.CallbackDown := callback_down
					this.CallbackUp := callback_up
					this.CurrentKey := key
					return 1
				} catch {
					this.Remove()
				}
			}
			return 0
		}

		Remove(){
			if (this.CurrentKey){
				if (this.CurrentApp){
					xHotkey.IfWinActive("ahk_class " this.CurrentApp)
				} else {
					xHotkey.IfWinActive()
				}
				Try {
					xHotkey(this.CurrentKey,,0)
					if (this.keyup_enabled){
						xHotkey(this.CurrentKey " up",,0)
					}
				} catch {
					
				}
				this.CurrentKey := ""
				this.State := 0
			}
			if (this.CurrentApp){
				this.CurrentApp := ""
			}
			this.Status := 0
			this.CallbackDown := ""
			this.CallbackUp := ""
			this.CallbackContext := ""
		}
		
		StripModifiers(str){
			Loop {
				if (!str){
					break
				}
				found := 0
				Loop % this.Modifiers.MaxIndex(){
					if (SubStr(str,1,1) = this.Modifiers[A_Index]){
						StringTrimLeft, str, str, 1
						found := 1
						break
					}
				}
				if (!found){
					break
				}
			}
			return str
		}

		; Trap down events so we can keep internal tabs on state etc
		DownEvent(){
			; Suppress "Key repeat" down events - if key held normally, down event repeatedly fired.
			if (this.State == 0 || !this.keyup_enabled){
				this.State := 1
				if (IsObject(this.CallbackDown)){
					; Call Callback function with specified context
					fn := bind(this.CallbackDown, this.CallbackContext*)
					%fn%()
				}
			}
		}

		UpEvent(){
			if (this.State == 1){
				this.State := 0
				if (IsObject(this.CallbackUp)){
					fn := bind(this.CallbackUp, this.CallbackContext*)
					%fn%()
				}
			}
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

}

; All Plugins to derive from this class
Class UCR_Plugin Extends CWindow {
	__New(parent){
		base.__New(parent)
	}

	OnChange(){
		; Extend this class to receive change events from GUI items

		; Fire parent's OnChange event, so it can trickle up to root
		this.parent.OnChange()
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
	; converts to hex, pads to 4 digits, chops off 0x
	ToHex(dec, padding := 4){
		return Substr(this.Convert2Hex(dec,padding),3)
	}

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

}
