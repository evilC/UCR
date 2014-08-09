; The TaskBar
class CTaskBarWindow extends CScrollingWindow {
	TaskBarOrder := []
	TaskIndex := []			; Lookup from the Hwnd of the TaskBar item to the Object it represents
	; ToDo: Allow these to be set via parameter
	TaskHeight := 25
	TaskWidth := 155 ; Needs to be ~25 px less than width of window
	TaskGap := 5

	__New(title := "", options := "", parent := 0){
		base.__New(title, options, parent)
	}

	AddTask(title, options, window_obj){
		task := new CTaskBarItem(title, options, this)
		this.TaskBarOrder.Push(task.Gui.Hwnd)
		this.TaskIndex[task.Gui.Hwnd] := window_obj
		tasknum := this.TaskBarOrder.Length - 1
		task.ShowRelative({x: 0, y: (tasknum * this.TaskHeight) + (tasknum * this.TaskGap), w: this.TaskWidth, h: this.TaskHeight})
	}
	
	TaskClicked(hwnd){
		if (this.TaskIndex[hwnd].WindowStatus.IsMinimized){
			this.RestoreTask(hwnd)
		} else {
			this.MinimizeTask(hwnd)			
		}
	}
	
	RestoreTask(hwnd){
		this.TaskIndex[hwnd].Gui.Restore()
	}
	
	MinimizeTask(hwnd){
		this.TaskIndex[hwnd].Gui.Hide()
		this.TaskIndex[hwnd].Gui.Minimize()
		this.TaskIndex[hwnd].Gui.Hide()
	}
	
}

/*
; The TaskBar
class CTaskBarWindow extends CScrollingWindow {
	__New(title := "", options := "", parent := 0, childcanvas := 0){
		
		if (!childcanvas){
			msgbox("ERROR: No Child Canvas specified for TaskBarItem")
			ExitApp
		}
		this._ChildCanvas := childcanvas
		base.__New(title, options, parent)

	}

	TaskBarOrder := []
	ChildMaximized(hwnd){
		this.ChildWindows[this._ChildCanvas.ChildWindows[hwnd].TaskHwnd].TaskMaximized()
		
		this._ChildCanvas.OnSize()
	}

	Pack(){
		offset := this.GetWindowOffSet(this.Hwnd)
		Bottom := 0 + offset.y
		Loop this.TaskBarOrder.Length(){
			;WinMove("ahk_id " . this.TaskBarOrder[A_Index],"", 0, Bottom)
			this.ChildWindows[this.TaskBarOrder[A_Index]].ShowRelative({x: 0, y: Bottom})
			Bottom += 30
		}
	}
}
*/

Class CTaskBarItem extends CWindow {
	__New(title := "", options := "", parent := 0){
		;this._MainHwnd := mainhwnd
		base.__New(title, options, parent)

		this.Gui.AddLabel(title)
		;this.TaskMaximized()

		;this.ShowRelative({x: coords.x, y: coords.y, w:150, h:25})
	}
	
	/*
	TaskClicked(){
		
	}
	*/
}

/*
Class CTaskBarItem extends CWindow {
	__New(title := "", options := "", parent := 0, mainhwnd := 0){
		this._MainHwnd := mainhwnd
		base.__New(title, options, parent)


		; Adjust coordinates to cater for current position of parent's scrollbar.
		coords := {x: 0, y: this.parent.TaskBarOrder.Length() * 30 }
		
		this.Gui.AddLabel(title)
		this.TaskMaximized()

		this.ShowRelative({x: coords.x, y: coords.y, w:150, h:25})
		
	}
	
	TaskMinimized(){
		cw := this.GetChildWindow()
		cw.Gui.Hide()
		cw.IsMinimized := 1

		this.Gui.BgColor := "0xEE0000"
		this.parent._ChildCanvas.Onsize()
	}
	
	TaskMaximized(){
		cw := this.GetChildWindow()
		
		cw.Gui.Restore()
		WinMoveTop("ahk_id " . cw.Hwnd)
		this.Gui.BgColor := "0x00EE00"
		cw.IsMinimized := 0
		this.parent._ChildCanvas.Onsize()
	}
	
	TaskBarItemClicked(){
		cw := this.GetChildWindow()
		if (cw.IsMinimized){
			this.TaskMaximized()
		} else {
			this.TaskMinimized()
		}
	}
	
	GetChildWindow(){
		return this.parent._ChildCanvas.ChildWindows[this._MainHwnd]
	}
}
*/
