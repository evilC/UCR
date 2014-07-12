#include <UCRWindow>

class UCRScrollableWindow extends UCRWindow
{
	child_windows := []
	panel_bottom := 0

	scroll_status := [0,0]

	viewport_width := 0
	viewport_height := 0

	__New(title := "", options := "")
	{
		OnMessage(0x115, "OnScroll") ; WM_VSCROLL
		OnMessage(0x114, "OnScroll") ; WM_HSCROLL
		base.__New(title, "+0x300000 " . options)
		hwnd := this.__Handle
		Gui, %hwnd%: +LastFound

		this.GetScrollStatus()
		return
	}

	OnSize(){
		global GUI_WIDTH
		static SIF_RANGE=0x1, SIF_PAGE=0x2, SIF_DISABLENOSCROLL=0x8, SB_HORZ=0, SB_VERT=1
		hwnd := this.__Handle

		;work out position and size of client area relative to main window
		method := 1
		if (method){
			; Original method - check coordinates of client windows
			viewport := {Top: 0, Left: 0, Right: 0, Bottom: 0}
			For key, value in this.child_windows {
				child_edges := this.GetChildEdges(this.__Handle, this.child_windows[key].__Handle)
				
				if (child_edges.Top < viewport.Top){
					viewport.Top := child_edges.Top
				}
				if (child_edges.Left < viewport.Left){
					viewport.Left := child_edges.Left
				}
				if (child_edges.Right > viewport.Right){
					viewport.Right := child_edges.Right
				}
				if (child_edges.Bottom > viewport.Bottom){
					viewport.Bottom := child_edges.Bottom
				}
			}
			this.viewport_width := viewport.Right - viewport.Left
			this.viewport_height := viewport.Bottom - viewport.Top

			viewport.Bottom += 20

			ScrollWidth := viewport.Right - viewport.Left
			ScrollHeight := viewport.Bottom - viewport.Top

			; GuiHeight = size of client area
			GuiWidth := this.GetPos(hwnd).w
			GuiHeight := this.GetPos(hwnd).h

			; Update horizontal scroll bar.
			this.SetScrollInfo(hwnd, SB_HORZ, {nMax: ScrollWidth, nPage: GuiWidth, fMask: SIF_RANGE | SIF_PAGE })
			
			; Update vertical scroll bar.
			this.SetScrollInfo(hwnd, SB_VERT, {nMax: ScrollHeight, nPage: GuiHeight, fMask: SIF_RANGE | SIF_PAGE })

		} else {
			; Alternate - add up heights of child windows
			; note this method works out size of client area by examining size of scrollbars.
			; I think this will result in it using the LAST size of the client area, as we may be about to add/remove scrollbars
			viewport := {Top: 0, Left: 0, Right: GUI_WIDTH, Bottom: 0}
			For key, value in this.child_windows {
				viewport.Bottom += this.GetPos(this.child_windows[key].__Handle).h
			}
			viewport.Top -= this.scroll_status[1].nPos
			viewport.Bottom -= this.scroll_status[1].nPos
			viewport.Left -= this.scroll_status[0].nPos
			viewport.Right -= this.scroll_status[0].nPos

			this.viewport_width := viewport.Right - viewport.Left
			this.viewport_height := viewport.Bottom - viewport.Top

			viewport.Bottom += 20

			ScrollWidth := viewport.Right - viewport.Left
			ScrollHeight := viewport.Bottom - viewport.Top

			; GuiHeight = size of client area
			GuiWidth := this.GetPos(hwnd).w
			GuiHeight := this.GetPos(hwnd).h

			; Update horizontal scroll bar.
			this.SetScrollInfo(hwnd, SB_HORZ, {nMax: ScrollWidth, nPage: GuiWidth, fMask: SIF_RANGE | SIF_PAGE })
			
			; Update vertical scroll bar.
			this.SetScrollInfo(hwnd, SB_VERT, {nMax: ScrollHeight, nPage: GuiHeight, fMask: SIF_RANGE | SIF_PAGE })

			; temp replacement of viewport var - decoupling this code from previous viewport calcs
			viewport := {Top: this.scroll_status[1].nPos * -1, Left: this.scroll_status[0].nPos * -1, Right: this.scroll_status[0].nMax - this.scroll_status[1].nPos, Bottom: this.scroll_status[1].nMax - this.scroll_status[1].nPos}

		}

		;tooltip % "viewport " JSON.stringify(viewport)

		; Handle move of client rect when window gets bigger and scrollbars are showing
		x := 0
		y := 0
		if (viewport.Left < 0 && viewport.Right < GuiWidth){
			;x := Abs(viewport.Left) > GuiWidth-viewport.Right ? GuiWidth-viewport.Right : Abs(viewport.Left)
			if (Abs(viewport.Left) > GuiWidth-viewport.Right){
				x := GuiWidth-viewport.Right
			} else {
				x := Abs(viewport.Left)
			}
		}
		if (viewport.Top < 0 && viewport.Bottom < GuiHeight){
			;y := Abs(viewport.Top) > GuiHeight-viewport.Bottom ? GuiHeight-viewport.Bottom : Abs(viewport.Top)
			if (Abs(viewport.Top) > GuiHeight-viewport.Bottom){
				y := GuiHeight-viewport.Bottom
			} else {
				y := Abs(viewport.Top)
			}
		}

		if (x || y){
			this.ScrollWindow(hwnd, x, y)
		}
		this.GetScrollStatus()
		return
	}

	OnScroll(wParam, lParam, msg, hwnd)
	{
		static SCROLL_STEP=10
		static SIF_ALL=0x17

		bar := msg=0x115 ; SB_HORZ=0, SB_VERT=1

		this.GetScrollStatus()
		
		; If call returns no info, quit
		if (this.scroll_status[bar] == 0){
			return
		}
		
		rect := this.GetClientRect(hwnd)
		new_pos := this.scroll_status[bar].nPos

		action := wParam & 0xFFFF
		if (action = 0){ ; SB_LINEUP
			;tooltip % "NP: " new_pos
			new_pos -= SCROLL_STEP
		} else if (action = 1){ ; SB_LINEDOWN
			; Wheel down
			new_pos += SCROLL_STEP
		} else if (action = 2){ ; SB_PAGEUP
			; Page Up ?
			new_pos -= rect.b - SCROLL_STEP
		} else if (action = 3){ ; SB_PAGEDOWN
			; Page Down ?
			new_pos += rect.b - SCROLL_STEP
		} else if (action = 5 || action = 4){ ; SB_THUMBTRACK || SB_THUMBPOSITION
			; Drag handle
			new_pos := wParam >> 16
		} else if (action = 6){ ; SB_TOP
			; Home?
			new_pos := this.scroll_status[bar].nMin ; nMin
		} else if (action = 7){ ; SB_BOTTOM
			; End?
			new_pos := this.scroll_status[bar].nMax ; nMax
		} else {
			return
		}
		
		min := this.scroll_status[bar].nMin ; nMin
		max := this.scroll_status[bar].nMax - this.scroll_status[bar].nPage ; nMax-nPage
		new_pos := new_pos > max ? max : new_pos
		new_pos := new_pos < min ? min : new_pos
		
		old_pos := this.scroll_status[bar].nPos ; nPos
		
		x := y := 0
		if bar = 0 ; SB_HORZ
			x := old_pos-new_pos
		else
			y := old_pos-new_pos

		; Scroll contents of window and invalidate uncovered area.
		this.ScrollWindow(hwnd, x, y)
		
		; Update scroll bar.
		tmp := this.scroll_status[bar]
		tmp.nPos := new_pos
		tmp.fMask := SIF_ALL

		this.SetScrollInfo(hwnd, bar, tmp)
		return
	}

	GetScrollStatus(){
		this.scroll_status[0] := this.GetScrollInfo(this.__Handle, 0)
		this.scroll_status[1] := this.GetScrollInfo(this.__Handle, 1)
	}

	AddChild(type){
		;base.__New("", "-Border +Parent" parent.__Handle)
		cw := new %type%(this, "", "-Border")
		hwnd := cw.__Handle
		this.child_windows[hwnd] := cw
		cw.Show()

		coords := this.AllocateSpace(cw)
		cw.Show("w300 X" coords.x " Y" coords.y)

		this.OnSize()
		return cw
	}

	RemoveChild(cw){
		hwnd := cw.__Handle
		this.child_windows.remove(hwnd,"")  ; The ,"" is VITAL, else remaining HWNDs in the array are decremented by one

		this.panel_bottom := 0
		For key, value in this.child_windows {
			this.child_windows[key].Show("X0 Y" . this.panel_bottom)
			this.panel_bottom += this.GetPos(this.child_windows[key].__Handle).h
		}
		this.OnSize()
	}
	
	AllocateSpace(window){
		tmp := this.panel_bottom
		this.panel_bottom += this.GetClientRect(window.__Handle).b + 2

		tmp -= this.scroll_status[1].nPos

		ret := {x: 0 - this.scroll_status[0].nPos, y: tmp}
		return ret
	}

}

OnScroll(wParam, lParam, msg, hwnd){
	AFC_AppObj.OnScroll(wParam, lParam, msg, hwnd)
}