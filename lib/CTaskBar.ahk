; The TaskBar
class CTaskBarWindow extends CScrollingWindow {
	TaskBarOrder := []
	TaskHwndToObj := []			; Lookup from the Hwnd of the TaskBar item to the Object it represents
	ObjHwndToTask := []
	; ToDo: Allow these to be set via parameter
	TaskHeight := 25
	TaskWidth := 155 ; Needs to be ~25 px less than width of window
	TaskGap := 5

	__New(title := "", options := "", parent := 0){
		base.__New(title, options, parent)
	}

	AddTask(title, options, window_obj){
		task := new CTaskBarItem(title, options, this)
		
		; Give tasks a sense of Order
		this.TaskBarOrder.Push(task.Gui.Hwnd)
		
		; Create lookup tables
		this.TaskHwndToObj[task.Gui.Hwnd] := window_obj
		this.ObjHwndToTask[window_obj.Gui.Hwnd] := task
		
		; Show position
		tasknum := this.TaskBarOrder.Length - 1
		this.RestoreTask(task.Gui.Hwnd)
		task.ShowRelative({x: 0, y: (tasknum * this.TaskHeight) + (tasknum * this.TaskGap), w: this.TaskWidth, h: this.TaskHeight})
	}
	
	TaskClicked(hwnd){
		if (this.TaskHwndToObj[hwnd].WindowStatus.IsMinimized){
			this.RestoreTask(hwnd)
		} else {
			this.MinimizeTask(hwnd)			
		}
	}
	
	; Task Hwnd was clicked - restore the Hwnd that it represents
	RestoreTask(hwnd){
		this.TaskHwndToObj[hwnd].Gui.Restore()
		this.ChildWindows[hwnd].Gui.BgColor := "0x00EE00"
	}
	
	; Task Hwnd was clicked - minimize the Hwnd that it represents
	MinimizeTask(hwnd){
		this.TaskHwndToObj[hwnd].Gui.Hide()
		this.TaskHwndToObj[hwnd].Gui.Minimize()
		this.TaskHwndToObj[hwnd].Gui.Hide()
		this.ChildWindows[hwnd].Gui.BgColor := "0xEE0000"
	}
	
	; Child Hwnd was clicked
	; Call RestoreTask with the TaskBar item's hwnd
	TaskRestored(hwnd){
		this.RestoreTask(this.ObjHwndToTask[hwnd].Gui.Hwnd)
	}
	
	; Call MinimizeTask with the TaskBar item's hwnd
	TaskMinimized(hwnd){
		this.MinimizeTask(this.ObjHwndToTask[hwnd].Gui.Hwnd)
	}
	
	; Hwnd is the Object's hwnd!, not the tasks!
	CloseTask(obj_hwnd){
		;this.Gui.Destroy(this.ObjHwndToTask[hwnd].Gui.Hwnd)
		;this.ObjHwndToTask[hwnd].OnClose()
		task_hwnd := this.ObjHwndToTask[obj_hwnd].Gui.Hwnd
		task_obj := this.ObjHwndToTask[obj_hwnd]
		Loop task_obj.Parent.TaskBarOrder.Length {
			if (task_obj.Parent.TaskBarOrder[A_Index] == task_hwnd){
				task_obj.Parent.TaskBarOrder.RemoveAt(A_Index)
				break
			}
		}
		this.TaskHwndToObj.Remove(task_hwnd)
		this.ObjHwndToTask.Remove(obj_hwnd)
		
		task_obj.OnClose()
		task_obj.Gui.Destroy()
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
