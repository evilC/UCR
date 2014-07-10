; General helper functions for all UCR windows
#include <CWindow>

Class UCRWindow extends CWindow {
	__New(title := "", options := ""){
		base.__New(title, options)
	}

	GetClientRect(hwnd){
		Gui, %hwnd%: +LastFound
		VarSetCapacity(rect, 16, 0)
        DllCall("GetClientRect", "Ptr", hwnd, "Ptr", &rect)
        ;return {w: NumGet(rect, 8, "Int"), h: NumGet(rect, 12, "Int")}
        return {l: NumGet(rect, 0, "Int"), t: NumGet(rect, 4, "Int") , r: NumGet(rect, 8, "Int"), b: NumGet(rect, 12, "Int")}
	}

	ScreenToClient(hwnd, x, y){
		VarSetCapacity(pt, 16)
		NumPut(x,pt,0)
		NumPut(y,pt,4)
		DllCall("ScreenToClient", "uint", hwnd, "Ptr", &pt)
		x := NumGet(pt, 0, "long")
		y := NumGet(pt, 4, "long")
		
		return {x: x, y: y}
	}

	; Used by OnSize
	; obj is an object returned by GetPos
	; ToDo: clean this up
	AdjustToClientCoords(hwnd, obj){
		tmp := this.ScreenToClient(hwnd, 0, 0)
    	obj.Left += tmp.x
    	obj.Right += tmp.x
    	obj.Top += tmp.y
    	obj.Bottom += tmp.y
    	return obj
	}

	GetPos(hwnd){
		;hwnd := this.__Handle
		Gui, %hwnd%: +LastFound
		WinGetPos x, y, w, h
		return {Top: y, Left: x, Right: x + w, Bottom: y + h}
	}

	GetSize(hwnd){
		;hwnd := this.__Handle
		Gui, %hwnd%: +LastFound
		WinGetPos x, y, w, h
		;msgbox % h
		return {w: w, h: h}
	}

	GetScrollInfo(hwnd, bar){
		static SIF_ALL=0x17

	    VarSetCapacity(si, 28, 0)
	    NumPut(28, si) ; cbSize
	    NumPut(SIF_ALL, si, 4) ; fMask
	    if (DllCall("GetScrollInfo", "uint", hwnd, "int", bar, "uint", &si)){
			ret := {}
			ret.cbSize := NumGet(si, 0, "uint") ; cbSize
			ret.fMask := NumGet(si, 4, "uint") ; fMask
			ret.nMin := NumGet(si, 8, "int") ; nMin
			ret.nMax := NumGet(si, 12, "int") ; nMax
			ret.nPage := NumGet(si, 16) ; nPage
			ret.nPos := NumGet(si, 20) ; nPos
			ret.nTrackPos := NumGet(si, 24) ; nTrackPos
			return ret
		} else {
			return 0
		}
	}
}