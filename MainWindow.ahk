; Autohotkey V2 code!!
; Uses Fincs "Proposed New GUI API for AutoHotkey v2": http://ahkscript.org/boards/viewtopic.php?f=37&t=2998

#include <CWindow>
#include <CChildWindow>
#include <CScrollingWindow>
#include <CTaskBar>

#SingleInstance Force
#MaxHotkeysPerInterval 9999

MainWindow := new CMainWindow("Outer Parent", "+Resize")

; Is it possible to move this inside the class somehow?
OnMessage(0x115, "OnScroll") ; WM_VSCROLL
OnMessage(0x114, "OnScroll") ; WM_HSCROLL
OnMessage(0x112,"PreMinimize")
OnMessage(0x201, "ClickHandler")	; 0x202 = WM_LBUTTONUP. 0x201 = WM_LBUTTONDOWN
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

; Detect clicks
ClickHandler(wParam, lParam, msg, hwnd := 0){
	global MainWindow
	; Click on ChildCanvas item = bring to front
	if(MainWindow.ChildCanvas.ChildWindows[hwnd]){
		WinMoveTop("ahk_id " . hwnd)
	}
	; Click on TaskBar Item = maximize / minimize
	if (MainWindow.TaskBar.ChildWindows[hwnd]){
		MainWindow.TaskBar.ChildWindows[hwnd].TaskBarItemClicked()
		return 0	; This line is IMPORTANT! It stops the message being processed further.
	}
}

; When we are about to minimize a window to the task bar, hide it first so the minimize is instant.
; This does not actually handle the minimize at all, just speeds it up by cutting out the minimize animation
PreMinimize(wParam, lParam, msg, hwnd := 0){
	global MainWindow
	if (wParam == 0xF020){
		;Minimize
		if (MainWindow.ChildCanvas.ChildWindows[hwnd]){
			MainWindow.ChildCanvas.ChildWindows[hwnd].Gui.Hide()
		}
	}
}

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
	__New(title, options := 0, parent := 0){
		;this.Gui := GuiCreate(title,options,this)
		base.__New(title, options)
		this.Gui.AddButton("Add","gAddClicked")
		
		this.Gui.Show("x0 y0 w600 h500")
		
		; Set up child GUI Canvas
		this.ChildCanvas := new CChildCanvasWindow("", "x200 y50", this)
		this.ChildCanvas.OnSize()
		
		; Set up "Task Bar" for Child GUIs
		this.TaskBar := new CTaskBarWindow("", "x0 y50", this, this.ChildCanvas)
		this.TaskBar.OnSize()
		
		
		this.OnSize()
		GroupAdd("MyGui", "ahk_id " . this.Hwnd)
		
	}

	AddClicked(){
		static WinNum := 1
		child := new CChildCanvasSubWindow(this.ChildCanvas, {x: 0, y: 0, title: "Child " . WinNum })
		this.ChildCanvas.ChildWindows[child.Hwnd] := child
		WinMoveTop("ahk_id " . child.Hwnd)
		this.ChildCanvas.OnSize()

		;task := new CTaskBarItem(this.TaskBar, {MainHwnd: child.Hwnd, title: "Child " . WinNum })
		task := new CTaskBarItem("Child " . WinNum, "-Border", this.TaskBar, child.Hwnd)
		;options.x := 0
		;options.y := this.parent.TaskBarOrder.Length() * 30
		this.TaskBar.ChildWindows[task.Hwnd] := task
		this.TaskBar.TaskBarOrder.Push(task.Hwnd)
		
		this.ChildCanvas.ChildWindows[child.Hwnd].TaskHwnd := task.hwnd
		this.TaskBar.OnSize()

		WinNum++
	}
	
	OnSize(){
		; Size Scrollable Child Window
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

; The ChildCanvas Window - Child windows sit on this
class CChildCanvasWindow extends CScrollingWindow {
	ChildMinimized(hwnd){
		this.parent.TaskBar.ChildWindows[this.ChildWindows[hwnd].TaskHwnd].TaskMinimized(hwnd)
		this.OnSize()
	}
	
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
				break
			}
		}
		this.ChildWindows.Remove(hwnd)

		this.parent.TaskBar.OnSize()
		this.OnSize()
	}
}

; A window that resides in the ChildCanvas window
class CChildCanvasSubWindow extends CChildWindow {
	__New(parent, options){
		base.__New(parent, options)
		this.Gui.AddLabel("I am " . this.Hwnd)
	}
	
	OnClose(){
		this.parent.ChildClosed(this.Hwnd)
	}
	
	OnSize(){
		if (WinGetMinMax("ahk_id " . this.Hwnd) == -1){
			this.parent.ChildMinimized(this.Hwnd)
		}
	}
}
