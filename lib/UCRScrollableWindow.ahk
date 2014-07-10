#include <UCRWindow>

class UCRScrollableWindow extends UCRWindow
{
	child_windows := []
	panel_bottom := 0

	viewport_width := 0
	viewport_height := 0

	__New(title := "", options := "")
	{
		OnMessage(0x115, "OnScroll") ; WM_VSCROLL
		OnMessage(0x114, "OnScroll") ; WM_HSCROLL
		base.__New(title, "+0x300000 " . options)
		hwnd := this.__Handle
		Gui, %hwnd%: +LastFound
		return
	}

	OnSize(){
		global GUI_WIDTH
	    static SIF_RANGE=0x1, SIF_PAGE=0x2, SIF_DISABLENOSCROLL=0x8, SB_HORZ=0, SB_VERT=1
	    hwnd := this.__Handle


        ;rs := this.GetClientRect(hwnd)
		;this.gui_size := {w: rs.r - rs.l, h: rs.b - rs.t}
   		;rs := {t: , r: , b: , l: }

		;hwnd := this.parent.__Handle
		wingetpos, x, y, w, h, ahk_id %hwnd%
		this.gui_size := {w: w , h: h}

	    ;work out position of client area relative to main window
	    viewport := {Top: 0, Left: 0, Right: 0, Bottom: 0}

	    For key, value in this.child_windows {
	    	;cw := this.child_windows[key].GetPos()
	    	cw := this.GetPos(this.child_windows[key].__Handle)
	    	cw := this.AdjustToClientCoords(hwnd,cw)
	    	
	    	if (cw.Top < viewport.Top){
	    		viewport.Top := cw.Top
	    	}
	    	if (cw.Left < viewport.Left){
	    		viewport.Left := cw.Left
	    	}
	    	if (cw.Right > viewport.Right){
	    		viewport.Right := cw.Right
	    	}
	    	if (cw.Bottom > viewport.Bottom){
	    		viewport.Bottom := cw.Bottom
	    	}
	    }
	    this.viewport_width := viewport.Right - viewport.Left
	    this.viewport_height := viewport.Bottom - viewport.Top
	    ;viewport.Bottom += 20

	    ScrollWidth := viewport.Right - viewport.Left
	    ScrollHeight := viewport.Bottom - viewport.Top
	    GuiWidth := this.gui_size.w
	    GuiHeight := this.gui_size.h
	    
	    Gui, %hwnd%: +LastFound

	    ; Initialize SCROLLINFO.
	    VarSetCapacity(si, 28, 0)
	    NumPut(28, si) ; cbSize
	    NumPut(SIF_RANGE | SIF_PAGE, si, 4) ; fMask
	    
	    ; Update horizontal scroll bar.
	    NumPut(ScrollWidth, si, 12) ; nMax
	    NumPut(GuiWidth, si, 16) ; nPage
	    DllCall("SetScrollInfo", "uint", WinExist(), "uint", SB_HORZ, "uint", &si, "int", 1)
	    
	    ; Update vertical scroll bar.
		; NumPut(SIF_RANGE | SIF_PAGE | SIF_DISABLENOSCROLL, si, 4) ; fMask
	    NumPut(ScrollHeight, si, 12) ; nMax
	    NumPut(GuiHeight, si, 16) ; nPage
	    DllCall("SetScrollInfo", "uint", WinExist(), "uint", SB_VERT, "uint", &si, "int", 1)
	    
	    x := 0
	    y := 0
	    if (viewport.Left < 0 && viewport.Right < GuiWidth)
	        x := Abs(viewport.Left) > GuiWidth-viewport.Right ? GuiWidth-viewport.Right : Abs(viewport.Left)
	    if (viewport.Top < 0 && viewport.Bottom < GuiHeight)
	        y := Abs(viewport.Top) > GuiHeight-viewport.Bottom ? GuiHeight-viewport.Bottom : Abs(viewport.Top)
	    if (x || y)
	        DllCall("ScrollWindow", "uint", WinExist(), "int", x, "int", y, "uint", 0, "uint", 0)

	    return
	}

	OnScroll(wParam, lParam, msg, hwnd)
	{
	    static SIF_ALL=0x17, SCROLL_STEP=10

	    bar := msg=0x115 ; SB_HORZ=0, SB_VERT=1
	    
	    VarSetCapacity(si, 28, 0)
	    NumPut(28, si) ; cbSize
	    NumPut(SIF_ALL, si, 4) ; fMask
	    ; ToDo: create GetScrollInfo function
	    if !DllCall("GetScrollInfo", "uint", hwnd, "int", bar, "uint", &si)
	        return
	    
	    ;VarSetCapacity(rect, 16)
	    ;DllCall("GetClientRect", "uint", hwnd, "uint", &rect)
	    rect := this.GetClientRect(hwnd)
	    
	    new_pos := NumGet(si, 20) ; nPos
	    if(bar){
	    	this.top_position := new_pos
	    } else {
	    	this.left_position := new_pos
	    }

	    action := wParam & 0xFFFF
	    if action = 0 ; SB_LINEUP
	        new_pos -= SCROLL_STEP
	    else if action = 1 ; SB_LINEDOWN
	        new_pos += SCROLL_STEP
	    else if action = 2 ; SB_PAGEUP
	        ;new_pos -= NumGet(rect, 12, "int") - SCROLL_STEP
	        new_pos -= rect.b - SCROLL_STEP
	    else if action = 3 ; SB_PAGEDOWN
	        ;new_pos += NumGet(rect, 12, "int") - SCROLL_STEP
	        new_pos += rect.b - SCROLL_STEP
	    else if (action = 5 || action = 4) ; SB_THUMBTRACK || SB_THUMBPOSITION
	        new_pos := wParam>>16
	    else if action = 6 ; SB_TOP
	        new_pos := NumGet(si, 8, "int") ; nMin
	    else if action = 7 ; SB_BOTTOM
	        new_pos := NumGet(si, 12, "int") ; nMax
	    else
	        return
	    
	    min := NumGet(si, 8, "int") ; nMin
	    max := NumGet(si, 12, "int") - NumGet(si, 16) ; nMax-nPage
	    new_pos := new_pos > max ? max : new_pos
	    new_pos := new_pos < min ? min : new_pos
	    
	    old_pos := NumGet(si, 20, "int") ; nPos
	    
	    x := y := 0
	    if bar = 0 ; SB_HORZ
	        x := old_pos-new_pos
	    else
	        y := old_pos-new_pos

	    ; Scroll contents of window and invalidate uncovered area.
	    DllCall("ScrollWindow", "uint", hwnd, "int", x, "int", y, "uint", 0, "uint", 0)
	    
	    ; Update scroll bar.
	    NumPut(new_pos, si, 20, "int") ; nPos
	    DllCall("SetScrollInfo", "uint", hwnd, "int", bar, "uint", &si, "int", 1)
	}

	AddChild(type){
		;base.__New("", "-Border +Parent" parent.__Handle)
		cw := new %type%(this, "", "-Border")
		hwnd := cw.__Handle
		this.child_windows[hwnd] := cw
		cw.Show()

		y := this.AllocateSpace(cw)
		cw.Show("w300 X0 Y" y)

		this.OnSize()
		return cw
	}

	RemoveChild(cw){
		hwnd := cw.__Handle
		this.child_windows.remove(hwnd,"")  ; The ,"" is VITAL, else remaining HWNDs in the array are decremented by one

		this.panel_bottom := 0
		For key, value in this.child_windows {
			this.child_windows[key].Show("X0 Y" . this.panel_bottom)
			;this.panel_bottom += this.GetClientRect(this.child_windows[key].__Handle).b
			;this.panel_bottom += this.child_windows[key].GetSize().h
			this.panel_bottom += this.GetSize(this.child_windows[key].__Handle).h
		}
		this.OnSize()
	}
	
	AllocateSpace(window){
		tmp := this.panel_bottom
		this.panel_bottom += this.GetClientRect(window.__Handle).b + 2
		return tmp
	}

}

OnScroll(wParam, lParam, msg, hwnd){
	AFC_AppObj.OnScroll(wParam, lParam, msg, hwnd)
}