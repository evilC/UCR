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
OnMessage(0x112,"PreMinimize")
OnMessage(0x201, "ClickHandler")	; 0x202 = WM_LBUTTONUP. 0x201 = WM_LBUTTONDOWN
OnMessage(0x46, "WindowMove")

; Detect drag of child windows and update scrollbars accordingly
WindowMove(wParam, lParam, msg, hwnd := 0){
	global MainWindow
	if (MainWindow.ChildCanvas.ChildWindows[hwnd]){
		MainWindow.ChildCanvas.OnReSize()
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
		;MainWindow.TaskBar.ChildWindows[hwnd].TaskBarItemClicked()
		;MainWindow.TaskBar.ChildWindows[hwnd].TaskClicked()
		MainWindow.TaskBar.TaskClicked(hwnd)
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

class CMainWindow extends CWindow {
	__New(title := "", options := "", parent := 0){
		base.__New(title, options, parent)
		this.ShowRelative({x: 0, y: 0, w:600, h: 400})
		
		this.Gui.AddButton("Add","gAddClicked")
		
		; Set up child GUI Canvas
		this.ChildCanvas := new CChildCanvasWindow("", "-Border", this, {ScrollTrap: 1, ScrollDefault: 1 })
		this.ChildCanvas.name := "ChildCanvas"
		
		; Set up "Task Bar" for Child GUIs
		this.TaskBar := new CTaskBarWindow("", "-Border", this, {ScrollTrap: 1, ScrollDefault: 0 })
		this.TaskBar.OnReSize()

		this.OnResize()
		this.ChildCanvas.OnReSize()

	}

	;OnReSize(gui := 0, eventInfo := 0, width := 0, height := 0){
	OnReSize(){
		base.OnReSize()
		; Size Scrollable Child Window
		; Lots of hard wired values - would like to eliminate these!
		r := this.GetClientRect(this.Gui.Hwnd)
		r.b -= 50	; How far down from the top of the main gui does the child window start?
		; Subtract border widths
		r.b -= r.t + 6
		r.r -= r.l + 6

		; Client rect seems to not include scroll bars - check if they are showing and subtract accordingly
		cc := {r: r.r, b: r.b}
		cc_sbv := this.GetScrollBarVisibility(this.ChildCanvas.Gui.Hwnd)
		if (cc_sbv.x){
			cc.r -= 16
		}

		if (cc_sbv.y){
			cc.b -= 16
		}
		
		tb := {r: r.r, b: r.b}
		tb_sbv := this.GetScrollBarVisibility(this.TaskBar.Gui.Hwnd)
		if (tb_sbv.x){
			tb.r -= 16
		}

		if (tb_sbv.y){
			tb.b -= 16
		}
		this.ChildCanvas.ShowRelative({x:200, y:50, w: cc.r - 200, h: cc.b})
		
		this.TaskBar.ShowRelative({x: 0, y: 50, w: 180, h: tb.b})		
	}

	OnScroll(wParam, lParam, msg, hwnd){
		; Is the current hwnd the TaskBar?
		if (hwnd == this.TaskBar.Gui.Hwnd){
			this.TaskBar.OnScroll(wParam, lParam, msg, this.TaskBar.Gui.Hwnd)
			return
		}
		; Is the current hwnd a child of the TaskBar?
		h := hwnd
		Loop {
			h := this.GetParent(h)
			if (h == this.TaskBar.Gui.Hwnd){
				this.TaskBar.OnScroll(wParam, lParam, msg, this.TaskBar.Gui.Hwnd)
				return
			}
			if (!h){
				break
			}

		}

		; Default route for scroll is ChildCanvas
		this.ChildCanvas.OnScroll(wParam, lParam, msg, this.ChildCanvas.Gui.Hwnd)
	}
	
	AddClicked(){
		static WinNum := 1
		title := "Child " . WinNum
		child := new CChildCanvasSubWindow(title, "", this.ChildCanvas)
		child.ShowRelative({x: WinNum * 10, y: WinNum * 10, w:200, h:50})
		;this.ChildCanvas.ChildWindows[child.Hwnd] := child
		WinMoveTop("ahk_id " . child.Gui.Hwnd)
		this.ChildCanvas.OnReSize()

		this.TaskBar.AddTask(title, "-Border", child)
		this.OnResize()
		;task := new CTaskBarItem("Child " . WinNum, "-Border", this.TaskBar, child.Hwnd)

		;this.TaskBar.ChildWindows[task.Hwnd] := task
		;this.TaskBar.TaskBarOrder.Push(task.Hwnd)
		
		;this.ChildCanvas.ChildWindows[child.Hwnd].TaskHwnd := task.hwnd
		this.TaskBar.OnReSize()

		WinNum++
	}

}

class CChildCanvasWindow extends CScrollingWindow {
	ChildMinimized(hwnd){
		base.ChildMinimized(hwnd)
		this.parent.Taskbar.TaskMinimized(hwnd)
		;this.ChildWindows[hwnd].Gui.Hide()
	}
	
	ChildClosed(hwnd){
		base.ChildClosed(hwnd)
		this.parent.Taskbar.CloseTask(hwnd)
	}
}

class CChildCanvasSubWindow extends CChildWindow {
	__New(title := "", options := "", parent := 0){
		base.__New(title, options, parent)
		this.Gui.AddLabel("I am " . this.Gui.Hwnd)
	}
}
