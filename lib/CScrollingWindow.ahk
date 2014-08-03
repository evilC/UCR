class CScrollingWindow extends CWindow {
	Bottom := 0
	Right := 0
	__New(parent, options := 0){
		this.parent := parent
		this.options := options
		this.ChildWindows := []

		this.Gui := GuiCreate("","-Border 0x300000 Parent" . this.parent.Hwnd, this)
		this.Gui.Show("x0 y50 w10 h10")
		this.Hwnd := this.Gui.Hwnd
		
		;OnMessage(0x115, OnScroll()) ; WM_VSCROLL
		;OnMessage(0x114, OnScroll()) ; WM_HSCROLL

	}
	
	/*
	AddClicked(){
		; Add child window at top left of canvas
		child := new CChildWindow(this, {x: this.Bottom, y: this.Right })
		this.Bottom += 30
		this.Right += 30
		
		g := this.GetClientRect(this.Hwnd)
		if (this.Bottom > g.b){
			this.Bottom := 0
		}
		if (this.Right > g.r){
			this.Right := 0
		}
		this.ChildWindows[child.Hwnd] := child
		this.OnSize()
	}
	*/
	
	ChildClosed(hwnd){
		For key, value in this.parent.TaskBar.ChildWindows {
			if (key == this.parent.ChildCanvas.ChildWindows[hwnd].TaskHwnd){
				; Remove TaskBar entry from TaskBarOrder
				Loop this.parent.TaskBar.TaskBarOrder.Length() {
					if(this.parent.TaskBar.TaskBarOrder[A_Index] == this.parent.ChildCanvas.ChildWindows[hwnd].TaskHwnd){
						this.parent.TaskBar.TaskBarOrder.RemoveAt(A_Index)
						break
					}
				}
				this.parent.TaskBar.ChildWindows[key].Gui.Destroy()
				this.parent.TaskBar.ChildWindows.Remove(key)
				this.parent.TaskBar.Pack()
				return
			}
		}
		this.ChildWindows.Remove(hwnd)
		this.OnSize()
	}
	
	OnSize(){
		static SIF_RANGE := 0x1, SIF_PAGE := 0x2, SIF_DISABLENOSCROLL := 0x8, SB_HORZ := 0, SB_VERT := 1
		
		viewport := {Top: 0, Left: 0, Right: 0, Bottom: 0}
		ctr := 0
		For key, value in this.ChildWindows {
			if (this.ChildWindows[key].IsMinimized){
				continue
			}
			if (!this.ChildWindows[key]){
				; ToDo: Why do I need this?
				continue
			}
			pos := this.ChildWindows[key].GetClientPos()
			bot := pos.y + pos.h
			if (pos.y < viewport.Top){
				viewport.Top := pos.y
			}
			if (pos.x < viewport.Left){
				viewport.Left := pos.x
			}
			if (bot > viewport.Bottom){
				viewport.Bottom := bot
			}
			right := pos.x + pos.w
			if (right > viewport.Right){
				viewport.Right := right
			}
			
			ctr++
		}
		if (!ctr){
			; Update horizontal scroll bar.
			this.SetScrollInfo(this.Hwnd, SB_HORZ, {nMax: 0, nPage: 0, fMask: SIF_RANGE | SIF_PAGE })
			; Update vertical scroll bar.
			this.SetScrollInfo(this.Hwnd, SB_VERT, {nMax: 0, nPage: 0, fMask: SIF_RANGE | SIF_PAGE })
			return
		}
		
		ScrollWidth := viewport.Right - viewport.Left
		ScrollHeight := viewport.Bottom - viewport.Top

		; GuiHeight = size of client area
		g := this.GetClientRect(this.Hwnd)
		GuiWidth := g.r
		GuiHeight := g.b

		; Update horizontal scroll bar.
		this.SetScrollInfo(this.Hwnd, SB_HORZ, {nMax: ScrollWidth, nPage: GuiWidth, fMask: SIF_RANGE | SIF_PAGE })

		; Update vertical scroll bar.
		this.SetScrollInfo(this.Hwnd, SB_VERT, {nMax: ScrollHeight, nPage: GuiHeight, fMask: SIF_RANGE | SIF_PAGE })
		
		; If being window gets bigger while child items are clipped, drag the child items into view
		if (viewport.Left < 0 && viewport.Right < GuiWidth){
			x := Abs(viewport.Left) > GuiWidth-viewport.Right ? GuiWidth-viewport.Right : Abs(viewport.Left)
		}
		if (viewport.Top < 0 && viewport.Bottom < GuiHeight){
			y := Abs(viewport.Top) > GuiHeight-viewport.Bottom ? GuiHeight-viewport.Bottom : Abs(viewport.Top)
		}
		if (x || y){
			this.ScrollWindow(this.Hwnd, x, y)
		}


	}

	OnScroll(wParam, lParam, msg, hwnd){
		static SCROLL_STEP := 10
		static SIF_ALL := 0x17

		bar := msg - 0x114 ; SB_HORZ=0, SB_VERT=1

		scroll_status := this.GetScrollInfos(this.Hwnd)
		
		; If call returns no info, quit
		if (scroll_status[bar] == 0){
			return
		}
		
		rect := this.GetClientRect(hwnd)
		new_pos := scroll_status[bar].nPos

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
			new_pos := scroll_status[bar].nMin ; nMin
		} else if (action = 7){ ; SB_BOTTOM
			; End?
			new_pos := scroll_status[bar].nMax ; nMax
		} else {
			return
		}
		
		min := scroll_status[bar].nMin ; nMin
		max := scroll_status[bar].nMax - scroll_status[bar].nPage ; nMax-nPage
		new_pos := new_pos > max ? max : new_pos
		new_pos := new_pos < min ? min : new_pos
		
		old_pos := scroll_status[bar].nPos ; nPos
		
		x := y := 0
		if bar = 0 ; SB_HORZ
			x := old_pos-new_pos
		else
			y := old_pos-new_pos

		; Scroll contents of window and invalidate uncovered area.
		this.ScrollWindow(hwnd, x, y)
		
		; Update scroll bar.
		tmp := scroll_status[bar]
		tmp.nPos := new_pos
		tmp.fMask := SIF_ALL

		this.SetScrollInfo(hwnd, bar, tmp)
		return
	}

}
