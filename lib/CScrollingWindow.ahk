#include <CWindow>

; A scrollable window class
class CScrollingWindow extends CWindow {
	__New(title := "", options := "", parent := 0, ext_options := 0){
		global _MainWindow
		static hooks_added := 0
		base.__New(title, options . " 0x300000", parent, ext_options)

		if (IsObject(ext_options)){
			if (ext_options.ScrollTrap){
				if (ext_options.ScrollDefault){
					def := 1
				} else {
					def := 0
				}
				this.RegisterMessage(0x114, this, "OnScroll", def)
				this.RegisterMessage(0x115, this, "OnScroll", def)
			}
		}
		
		if (!hooks_added){
			hooks_added := 1
			hotkey, IfWinActive, ahk_group _MainWindow
			hotkey, ~WheelUp, _WheelHandler
			hotkey, ~WheelDown, _WheelHandler
			hotkey, ~+WheelUp, _WheelHandler
			hotkey, ~+WheelDown, _WheelHandler
			hotkey, IfWinActive

			if (0){
				_WheelHandler:
					_MessageHandler(InStr(A_ThisHotkey,"Down") ? 1 : 0, 0, GetKeyState("Shift") ? 0x114 : 0x115, 0)
					return
			}
		}
		
	}
	
	_WheelHandler(){
		_WheelHandler:
			msgbox("HERE")
			return
	}

	/*
	MessageHandler(wParam, lParam, msg, hwnd){
		base.MessageHandler(wParam, lParam, msg, hwnd)
		if (msg == 0x114 || msg == 0x115){
			soundbeep
			this.OnScroll(wParam, lParam, msg, hwnd)
		}
	}
	*/
	
	OnReSize(gui := 0, eventInfo := 0, width := 0, height := 0){
		static SIF_RANGE := 0x1, SIF_PAGE := 0x2, SIF_DISABLENOSCROLL := 0x8, SB_HORZ := 0, SB_VERT := 1

		base.OnReSize(gui, eventInfo, width, height)

		; ToDo: Check if window contains any controls, and include those in the viewport calcs.

		; Do not allow scrollbars to appear if windows dragged such that they clip the left or top edge.
		; Strange behavior ensues if this is allowed.
		info := this.GetScrollInfos(this.Gui.Hwnd)
		if (info[0]){
			scx := info[0].nPos
		} else {
			scx := 0
		}
		if (info[1]){
			scy := info[1].nPos
		} else {
			scy := 0
		}

		; Work out where the edges of the child windows lie
		viewport := {Top: 0, Left: 0, Right: 0, Bottom: 0}
		ctr := 0
		For key, value in this.ChildWindows {
			if (this.ChildWindows[key].WindowStatus.IsMinimized){
				continue
			}
			; Get Window Position
			pos := this.ChildWindows[key].GetClientPos()
			; Adjust coordinates due to scrollbar position
			pos.x += scx
			pos.y += scy
			; Expand viewport if Child window falls outside
			if (pos.y < viewport.Top && pos.y > 0){ ; Dont expand if window dragged off the Top of canvas
				viewport.Top := pos.y
			}
			if (pos.x < viewport.Left && pos.x > 0){ ; Dont expand if window dragged off the Left of canvas
				viewport.Left := pos.x
			}
			bot := pos.y + pos.h
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
			; If no Child windows present, set scroll bars off.
			; Update horizontal scroll bar.
			this.SetScrollInfo(this.Gui.Hwnd, SB_HORZ, {nMax: 0, nPage: 0, fMask: SIF_RANGE | SIF_PAGE })
			; Update vertical scroll bar.
			this.SetScrollInfo(this.Gui.Hwnd, SB_VERT, {nMax: 0, nPage: 0, fMask: SIF_RANGE | SIF_PAGE })
			return
		}
		
		; Configure scroll bars due to canvas size
		ScrollWidth := viewport.Right - viewport.Left
		ScrollHeight := viewport.Bottom - viewport.Top

		; GuiHeight = size of client area
		g := this.GetClientRect(this.Gui.Hwnd)
		GuiWidth := g.r
		GuiHeight := g.b

		; Update horizontal scroll bar.
		this.SetScrollInfo(this.Gui.Hwnd, SB_HORZ, {nMax: ScrollWidth, nPage: GuiWidth, fMask: SIF_RANGE | SIF_PAGE })

		; Update vertical scroll bar.
		this.SetScrollInfo(this.Gui.Hwnd, SB_VERT, {nMax: ScrollHeight, nPage: GuiHeight, fMask: SIF_RANGE | SIF_PAGE })
		
		viewport.Left -= scx
		viewport.Right -= scx
		viewport.Top -= scy
		viewport.Bottom -=scy
		
		; If window is sized up while child items are clipped, drag the child items into view
		if (viewport.Left < 0 && viewport.Right < GuiWidth){
			x := Abs(viewport.Left) > GuiWidth-viewport.Right ? GuiWidth-viewport.Right : Abs(viewport.Left)
		}
		if (viewport.Top < 0 && viewport.Bottom < GuiHeight){
			y := Abs(viewport.Top) > GuiHeight-viewport.Bottom ? GuiHeight-viewport.Bottom : Abs(viewport.Top)
		}
		if (x || y){
			this.ScrollWindow(this.Gui.Hwnd, x, y)
		}
	}

	OnScroll(wParam, lParam, msg, hwnd){
		static SCROLL_STEP := 10
		static SIF_ALL := 0x17

		bar := msg - 0x114 ; SB_HORZ=0, SB_VERT=1

		scroll_status := this.GetScrollInfos(this.Gui.Hwnd)
		
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
