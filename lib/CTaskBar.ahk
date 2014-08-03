; The TaskBar
class CTaskBarWindow extends CScrollingWindow {
	__New(parent, options := 0){
		
		if (!options.ChildCanvas){
			msgbox("ERROR: No Child Canvas specified for TaskBarItem")
			ExitApp
		}
		base.__New(parent, options)

	}

	TaskBarOrder := []
	ChildMaximized(hwnd){
		this.ChildWindows[this.options.ChildCanvas.ChildWindows[hwnd].TaskHwnd].TaskMaximized()
		
		this.options.ChildCanvas.OnSize()
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
	__New(parent, options := false){
		this.parent := parent
		
		if (options){
			this.options := options
		} else {
			options := {}
		}
		
		options.x := 0
		options.y := this.parent.TaskBarOrder.Length() * 30
		
		; Adjust coordinates to cater for current position of parent's scrollbar.
		offset := this.GetWindowOffSet(this.parent.Hwnd)	; Get offset due to position of scroll bars
		options.x += offset.x
		options.y += offset.y
		
		; Create the GUI
		this.Gui := GuiCreate(this.options.title ,"-Border +Parent" . this.parent.Hwnd,this)
		this.Gui.AddLabel(this.options.title)	;this.Gui.Hwnd
		this.TaskMaximized()
		this.Gui.Show("x" . options.x . " y" . options.y . " w150 h25")
		
		this.Hwnd := this.Gui.Hwnd
	}
	
	TaskMinimized(){
		cw := this.GetChildWindow()
		cw.Gui.Hide()
		cw.IsMinimized := 1

		this.Gui.BgColor := "0xEE0000"
		;this.parent.parent.ChildCanvas.Onsize()
		this.options.ChildCanvas.Onsize()
	}
	
	TaskMaximized(){
		cw := this.GetChildWindow()
		
		;this.parent.ChildMaximized(this.options.MainHwnd)
		cw.Gui.Restore()
		this.Gui.BgColor := "0x00EE00"
		cw.IsMinimized := 0
		this.options.ChildCanvas.Onsize()
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
		return this.options.ChildCanvas.ChildWindows[this.options.MainHwnd]
	}
}
