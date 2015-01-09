; Base class to derive from for Plugins
Class UCR_Plugin Extends _UCR_C_Window {
	__New(parent){
		base.__New(parent)
	}

	OnChange(name := ""){
		; Extend this class to receive change events from GUI items

		; Fire parent's OnChange event, so it can trickle up to root
		this.parent.OnChange()
	}
}

; Functionality common to all window types
Class _UCR_C_Window extends _UCR_C_GuiItem {
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

; Functionality common to all things that have a GUI presence
Class _UCR_C_GuiItem extends _UCR_C_Common {
	__New(parent){
		base.__New(parent)
		this.CreateGui()
	}
}

; Common functions for all UCR classes
Class _UCR_C_Common {
	__New(parent){
		if (!parent){
			; Root class
			this.parent := this
			this.root := this
		} else {
			this.parent := parent
			this.root := this.parent.root
		}
	}
	
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
