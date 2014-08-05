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
	
	Sort(hwnd := 0){
		static Bottom := 0
		;Critical
		if (hwnd){
			WinMove("ahk_id " . hwnd,"", 0, Bottom)
			Bottom += 30
		} else {
			Bottom := 0
			For key, value in this.ChildWindows {
				WinMove("ahk_id " . key,"", 0, Bottom)
				Bottom += 30
			}
		}
		this.OnSize()
	}
	
	ChildClosed(hwnd){
		base.ChildClosed(hwnd)
		this.Sort()
	}
	
	Pack(){
		offset := this.GetWindowOffSet(this.Hwnd)
		Bottom := 0 + offset.y
		Loop this.TaskBarOrder.Length(){
			WinMove("ahk_id " . this.TaskBarOrder[A_Index],"", 0, Bottom)
			Bottom += 30
		}
	}
}

Class CTaskBarItem extends CWindow {
	__New(title := "", options := "", parent := 0, mainhwnd := 0){
		this._MainHwnd := mainhwnd
		base.__New(title, options, parent)


		; Adjust coordinates to cater for current position of parent's scrollbar.
		coords := this.GetWindowOffSet(this.parent.Hwnd)	; Get offset due to position of scroll bars
		coords.y += this.parent.TaskBarOrder.Length() * 30
		
		this.Gui.AddLabel(title)
		this.TaskMaximized()
		this.Gui.Show("x" . coords.x . " y" . coords.y . " w150 h25")
		
	}
	
	TaskMinimized(){
		cw := this.GetChildWindow()
		cw.Gui.Hide()
		cw.IsMinimized := 1

		this.Gui.BgColor := "0xEE0000"
		;this.parent.parent.ChildCanvas.Onsize()
		this.parent._ChildCanvas.Onsize()
	}
	
	TaskMaximized(){
		cw := this.GetChildWindow()
		
		;this.parent.ChildMaximized(this.options.MainHwnd)
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
