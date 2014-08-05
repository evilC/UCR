; Helper functions
class CWindow {
	__New(title := "", options := "x0 y0 w200 h50", parent := 0){
		this.parent := parent
		if (this.parent){
			options .= " +Parent" . this.parent.Hwnd
		}
		this.Gui := GuiCreate(title,options,this)
		
		/*
		if(!IsObject(parent)){
			parent := 0
		}
		this._Parent := parent
		
		if(!IsObject(options)){
			;options := {x: 0, y: 0, w: 200, h:100}
			options := {}
		}
		if !ObjHasKey(options, "x"){
			options.x := 0
		}
		this._Options := options
		*/
	}
	
	__Get(aName){
		; IMPORTANT! SINGLE equals sign (=) is a CASE INSENSITIVE comparison!
		if (aName = "hwnd" && IsObject(this.Gui)){
			return this.Gui.Hwnd
		}
		/* else if (aName = "options"){
			return this._Options
		}
		*/
	}

	; Wrapper for WinGetPos
	GetPos(hwnd){
		WinGetPos(x, y, w, h, "ahk_id " hwnd)
		return {x: x, y: y, w: w, h: h}
	}
	
	; Wrapper for GetClientRect DllCall
	; Gets "Client" (internal) area of a window
	GetClientRect(hwnd){
		VarSetCapacity(rect, 16, 0)
        DllCall("GetClientRect", "Ptr", hwnd, "Ptr", &rect)
        return {l: NumGet(rect, 0, "Int"), t: NumGet(rect, 4, "Int") , r: NumGet(rect, 8, "Int"), b: NumGet(rect, 12, "Int")}
	}
	
	; Wrapper for GetScrollInfo DllCall
	GetScrollInfo(hwnd, bar){
		static SIF_ALL := 0x17

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
	
	GetScrollInfos(hwnd){
		ret := []
		ret[0] := this.GetScrollInfo(hwnd, 0)
		ret[1] := this.GetScrollInfo(hwnd, 1)
		return ret
	}


	; Wrapper for SetScrollInfo DllCall
	SetScrollInfo(hwnd, bar, scrollinfo){
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

	GetScrollBarVisibility(hwnd){
		static WS_HSCROLL := 0x00100000
		static WS_VSCROLL := 0x00200000

		ret := DllCall("GetWindowLong", "uint", hwnd, "int", -16)
		out := {}
		out.x := (ret & WS_HSCROLL) > 0
		out.y := (ret & WS_VSCROLL) > 0
		return out
	}

	; Get the offset of the canvas of a window due to scrollbar position
	GetWindowOffSet(hwnd){
		ret := {x: 0, y: 0}
		info := this.GetScrollInfos(hwnd)
		if (info[0] == 0){
			; No x scroll bar
			ret.x := 0
		} else {
			ret.x := info[0].nPos * -1
		}
		
		if (info[1] == 0){
			; No y scroll bar
			ret.y := 0
		} else {
			ret.y := info[1].nPos * -1
		}
		
		return ret
	}
	
	; Wrapper for GetParent DllCall
	GetParent(hwnd){
		return DllCall("GetParent", "Ptr", hwnd)
	}
	
	; Gets position of a child window relative to it's parent's RECT
	GetClientPos(){
		pos := this.GetPos(this.Hwnd)
		offset := this.ScreenToClient(this.parent.Hwnd, x, y)
		pos.x += offset.x
		pos.y += offset.y
		return pos
	}
}
