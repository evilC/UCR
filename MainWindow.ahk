; Autohotkey V2 code!!
; Uses Fincs "Proposed New GUI API for AutoHotkey v2": http://ahkscript.org/boards/viewtopic.php?f=37&t=2998

#include <CWindow>
#include <CChildWindow>
#include <CScrollingWindow>
#include <CTaskBar>

#SingleInstance Force
#MaxHotkeysPerInterval 9999

MainWindow := new CMainWindow("Outer Parent", "+Resize")

class CMainWindow extends CWindow {
	__New(title := "", options := "", parent := 0){
		base.__New(title, options, parent)
		this.ShowRelative({x: 0, y: 0, w:600, h: 400})
		
		this.Gui.AddButton("Add","gAddClicked")
		
		; Set up child GUI Canvas
		this.ChildCanvas := new CChildCanvasWindow("", "-Border", this, {ScrollTrap: 1, ScrollDefault: 1, name: "ChildCanvas" })
		this.ChildCanvas.name := "ChildCanvas"
		
		; Set up "Task Bar" for Child GUIs
		this.TaskBar := new CTaskBarWindow("", "-Border", this, {ScrollTrap: 1, ScrollDefault: 0, name: "TaskBar" })
		this.TaskBar.OnReSize()

		this.OnResize()
		this.ChildCanvas.OnReSize()

	}

	;When Main window is resize, resize sub-windows accordingly
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

	AddClicked(){
		static WinNum := 0
		title := "Child " . WinNum
		child := new CChildCanvasSubWindow(title, "", this.ChildCanvas, {name: title})
		child.ShowRelative({x: WinNum * 10, y: WinNum * 10, w:200, h:50})
		WinMoveTop("ahk_id " . child.Gui.Hwnd)
		;this.ChildCanvas.OnReSize()

		this.TaskBar.AddTask(title, "-Border", child)
		;this.OnResize()
		;this.TaskBar.OnReSize()

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
