; The TaskBar
; ToDo:
; When a Child window is destroyed, Pack() is called on the TaskBar to re-order taskbar items.
; This re-order takes time, and delays the child window from being removed from view

#include <CScrollingWindow>
#include <CWindow>

class CTaskBarWindow extends CScrollingWindow {
	TaskBarOrder := []
	TaskHwndToObj := []			; Lookup from the Hwnd of the TaskBar item to the Object it represents
	ObjHwndToTask := []
	; ToDo: Allow these to be set via parameter
	TaskHeight := 25
	TaskWidth := 155 ; Needs to be ~25 px less than width of window
	TaskGap := 5

	__New(title := "", options := "", parent := 0, ext_options := 0){
		base.__New(title, options, parent, ext_options)
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
		task.ShowRelative({x: 0, y: this.GetTaskY(tasknum), w: this.TaskWidth, h: this.TaskHeight})
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
		len := task_obj.Parent.TaskBarOrder.Length
		Loop  len {
			if (task_obj.Parent.TaskBarOrder[A_Index] == task_hwnd){
				task_obj.Parent.TaskBarOrder.RemoveAt(A_Index)
				break
			}
		}
		this.TaskHwndToObj.Remove(task_hwnd)
		this.ObjHwndToTask.Remove(obj_hwnd)
		
		task_obj.OnClose()
		task_obj.Gui.Destroy()
		
		; If item was removed from anywhere else but end, re-pack the boxes.
		if (len != A_Index){
			; Pass A_Index to Pack() to only re-order items below the one we just deleted
			this.Pack(A_Index)
		}
	}

	; Re-Order TaskBar items (eg due to deletion)
	Pack(start := 1){
		offset := this.GetWindowOffSet(this.Gui.Hwnd)
		Bottom := 0 + offset.y
		Loop this.TaskBarOrder.Length {
			if (A_Index < start){
				; Skip packing items before optional start parameter.
				; Allows accelerating pack by only packing guis after the deleted item
				continue
			}
			;WinMove("ahk_id " . this.TaskBarOrder[A_Index],"", 0, Bottom)
			;this.ChildWindows[this.TaskBarOrder[A_Index]].ShowRelative({x: 0, y: Bottom})
			this.ChildWindows[this.TaskBarOrder[A_Index]].ShowRelative({x: 0, y: this.GetTaskY(A_Index - 1)})
			Bottom += 30
		}
	}
	
	GetTaskY(tasknum){
		return (tasknum * this.TaskHeight) + (tasknum * this.TaskGap)
	}
}

Class CTaskBarItem extends CWindow {
	__New(title := "", options := "", parent := 0, ext_options := 0){
		base.__New(title, options, parent, ext_options)

		this.Gui.AddLabel(title)
	}
	
	WindowClicked(){
		this.Parent.TaskClicked(this.Gui.hwnd)
	}
}
