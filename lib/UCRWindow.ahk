; General helper functions for all UCR windows
#include <CWindow>

Class UCRWindow extends CWindow {
	__New(title := "", options := ""){
		base.__New(title, options)
	}

	; Wrapper for GetClientRect DllCall
	; Gets "Client" (internal) area of a window
	GetClientRect(hwnd){
		Gui, %hwnd%: +LastFound
		VarSetCapacity(rect, 16, 0)
        DllCall("GetClientRect", "Ptr", hwnd, "Ptr", &rect)
        ;return {w: NumGet(rect, 8, "Int"), h: NumGet(rect, 12, "Int")}
        return {l: NumGet(rect, 0, "Int"), t: NumGet(rect, 4, "Int") , r: NumGet(rect, 8, "Int"), b: NumGet(rect, 12, "Int")}
	}

	; Wrapper for ScreenToClient DllCall
	; returns offset between screen and client coords
	ScreenToClient(hwnd, x, y){
		VarSetCapacity(pt, 16)
		NumPut(x,pt,0)
		NumPut(y,pt,4)
		DllCall("ScreenToClient", "uint", hwnd, "Ptr", &pt)
		x := NumGet(pt, 0, "long")
		y := NumGet(pt, 4, "long")
		
		return {x: x, y: y}
	}

	; Convert passed Edge object from screen coords to client rect coords
	AdjustToClientCoords(hwnd, obj){
		; find offset for upper left corner of client rect
		tmp := this.ScreenToClient(hwnd, 0, 0)
		
		; Offset passed Edge object
    	obj.Left += tmp.x
    	obj.Right += tmp.x
    	obj.Top += tmp.y
    	obj.Bottom += tmp.y
    	return obj
	}

	; Returns Edge coordinates of child (Relative to parent window - ie due to scrolling)
	GetChildEdges(pHwnd, cHwnd){
		cw := this.GetEdges(cHwnd)
		cw := this.AdjustToClientCoords(pHwnd,cw)
		return cw
	}

	; Get Edges
	; Note: Coordinates are relative to the SCREEN
	GetEdges(hwnd){
		Gui, %hwnd%: +LastFound
		WinGetPos x, y, w, h
		return {Top: y, Left: x, Right: x + w, Bottom: y + h}
	}

	; Wrapper for WinGetPos
	GetPos(hwnd){
		Gui, %hwnd%: +LastFound
		WinGetPos x, y, w, h
		return {x: x, y: y, w: w, h: h}
	}

	; Wrapper for GetScrollInfo DllCall
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

	; Wrapper for SetScrollInfo DllCall
	SetScrollInfo(hwnd, bar, scrollinfo){
		;static SIF_ALL=0x17

		VarSetCapacity(si, 28, 0)
		NumPut(28, si) ; cbSize
		

		if (scrollinfo.fMask){
			NumPut(scrollinfo.fMask, si, 4) ; fMask
		}
		if (scrollinfo.nMin){
			NumPut(scrollinfo.nMin, si, 8) ; nMin
		}
		if (scrollinfo.nMax){
			NumPut(scrollinfo.nMax, si, 12) ; nMax
		}
		if (scrollinfo.nPage){
			NumPut(scrollinfo.nPage, si, 16) ; nPage
		}
		if (scrollinfo.nPos){
			NumPut(scrollinfo.nPos, si, 20, "int") ; nPos
		}
		if (scrollinfo.nTrackPos){
			NumPut(scrollinfo.nTrackPos, si, 24) ; nTrackPos
		}
		return DllCall("SetScrollInfo", "uint", hwnd, "int", bar, "uint", &si, "int", 1)
	}

	; Wrapper for ScrollWindow DllCall
	ScrollWindow(hwnd, x, y){
		DllCall("ScrollWindow", "uint", hwnd, "int", x, "int", y, "uint", 0, "uint", 0)
	}
}