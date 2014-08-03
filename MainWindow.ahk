; Autohotkey V2 code!!
; Uses Fincs "Proposed New GUI API for AutoHotkey v2": http://ahkscript.org/boards/viewtopic.php?f=37&t=2998

#include <CWindow>
#include <CChildWindow>
#include <CScrollingWindow>
#include <CTaskBar>

#SingleInstance Force
#MaxHotkeysPerInterval 9999

MainWindow := new CMainWindow()

; Is it possible to move this inside the class somehow?
OnMessage(0x115, "OnScroll") ; WM_VSCROLL
OnMessage(0x114, "OnScroll") ; WM_HSCROLL
;OnMessage(0x112,"PreMinimize")
OnMessage(0x202, "ClickHandler")	; 0x202 = WM_LBUTTONUP. WM_LBUTTONDOWN seems to fire twice ?!
OnMessage(0x46, "WindowMove")


#IfWinActive ahk_group MyGui
~WheelUp::
~WheelDown::
~+WheelUp::
~+WheelDown::
    ; SB_LINEDOWN=1, SB_LINEUP=0, WM_HSCROLL=0x114, WM_VSCROLL=0x115
	; Pass 0 to Onscroll's hwnd param
    OnScroll(InStr(A_ThisHotkey,"Down") ? 1 : 0, 0, GetKeyState("Shift") ? 0x114 : 0x115, 0)
return
#IfWinActive

; Detect drag of child windows and update scrollbars accordingly
WindowMove(wParam, lParam, msg, hwnd := 0){
	global MainWindow
	if (MainWindow.ChildCanvas.ChildWindows[hwnd]){
		MainWindow.ChildCanvas.OnSize()
	}
}

; Detect click on TaskBar item
ClickHandler(wParam, lParam, msg, hwnd := 0){
	global MainWindow
	if (MainWindow.TaskBar.ChildWindows[hwnd]){
		MainWindow.TaskBar.ChildWindows[hwnd].TaskBarItemClicked()
	}
}

/*
; When we are about to minimize a window to the task bar, hide it first so the minimize is instant.
PreMinimize(wParam, lParam, msg, hwnd := 0){
	global MainWindow
	if (wParam == 0xF020){
		;Minimize
		if (MainWindow.ChildCanvas.ChildWindows[hwnd]){
			MainWindow.ChildCanvas.ChildWindows[hwnd].Gui.Hide()
		}
	}
}
*/

OnScroll(wParam, lParam, msg, hwnd := 0){
	global MainWindow
	if (!hwnd){
		; No Hwnd - Mouse wheel used. Find Hwnd of what is under the cursor
		MouseGetPos(tmp,tmp,tmp,hwnd,2)
	}
	MainWindow.OnScroll(wParam, lParam, msg, hwnd)
}

; The Main Window
class CMainWindow extends CWindow {
	__New(){
		this.Gui := GuiCreate("Outer Parent","Resize",this)
		this.Gui.AddButton("Add","gAddClicked")
		
		this.Gui.Show("x0 y0 w600 h500")
		this.Hwnd := this.Gui.Hwnd
		
		; Set up child GUI Canvas
		this.ChildCanvas := new CChildCanvasWindow(this, {name: "canvas"})
		this.ChildCanvas.OnSize()
		
		; Set up "Task Bar" for Child GUIs
		this.TaskBar := new CTaskBarWindow(this, {name: "taskbar", ChildCanvas: this.ChildCanvas})
		this.TaskBar.OnSize()
		
		
		this.OnSize()
		GroupAdd("MyGui", "ahk_id " . this.Hwnd)
		
	}

	AddClicked(){
		child := new CChildWindow(this.ChildCanvas, {x: 0, y: 0 })
		this.ChildCanvas.ChildWindows[child.Hwnd] := child
		this.ChildCanvas.OnSize()

		task := new CTaskBarItem(this.TaskBar, {MainHwnd: child.Hwnd, ChildCanvas: this.ChildCanvas })
		this.TaskBar.ChildWindows[task.Hwnd] := task
		this.TaskBar.TaskBarOrder.Push(task.Hwnd)
		
		this.ChildCanvas.ChildWindows[child.Hwnd].TaskHwnd := task.hwnd
		this.TaskBar.OnSize()

	}
	
	OnSize(){
		; Size Scrollable Child Window
		;Critical
		
		; Lots of hard wired values - would like to eliminate these!
		r := this.GetClientRect(this.Hwnd)
		r.b -= 50	; How far down from the top of the main gui does the child window start?
		; Subtract border widths
		r.b -= r.t + 6
		r.r -= r.l + 6

		; Client rect seems to not include scroll bars - check if they are showing and subtract accordingly
		cc := {r: r.r, b: r.b}
		cc_sbv := this.GetScrollBarVisibility(this.ChildCanvas.Hwnd)
		if (cc_sbv.x){
			cc.r -= 16
		}

		if (cc_sbv.y){
			cc.b -= 16
		}
		
		tb := {r: r.r, b: r.b}
		tb_sbv := this.GetScrollBarVisibility(this.TaskBar.Hwnd)
		if (tb_sbv.x){
			tb.r -= 16
		}

		if (tb_sbv.y){
			tb.b -= 16
		}
		
		this.ChildCanvas.Gui.Show("x200 y50 w" . cc.r - 200 . " h" . cc.b)
		
		this.TaskBar.Gui.Show("x0 y50 w180 h" . tb.b)
	}
	
	OnScroll(wParam, lParam, msg, hwnd){
		; Is the current hwnd the TaskBar?
		if (hwnd == this.TaskBar.Hwnd){
			this.TaskBar.OnScroll(wParam, lParam, msg, this.TaskBar.Hwnd)
			return
		}
		; Is the current hwnd a child of the TaskBar?
		h := hwnd
		Loop {
			h := this.GetParent(h)
			if (h == this.TaskBar.Hwnd){
				this.TaskBar.OnScroll(wParam, lParam, msg, this.TaskBar.Hwnd)
				return
			}
			if (!h){
				break
			}

		}

		; Default route for scroll is ChildCanvas
		this.ChildCanvas.OnScroll(wParam, lParam, msg, this.ChildCanvas.Hwnd)
	}
}

; The ChildCanvas
class CChildCanvasWindow extends CScrollingWindow {
	ChildMinimized(hwnd){
		this.parent.TaskBar.ChildWindows[this.ChildWindows[hwnd].TaskHwnd].TaskMinimized(hwnd)
		this.OnSize()
	}
}

