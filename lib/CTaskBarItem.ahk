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
		this.Gui := GuiCreate("Child","-Border +Parent" . this.parent.Hwnd,this)
		this.Gui.AddLabel("I am " . this.options.MainHwnd)	;this.Gui.Hwnd
		this.Gui.BgColor := "0x00EE00"
		this.Gui.Show("x" . options.x . " y" . options.y . " w150 h25")
		
		this.Hwnd := this.Gui.Hwnd
	}
	
	TaskMinimized(){
		cw := this.GetChildWindow()
		cw.Gui.Hide()
		cw.IsMinimized := 1

		this.Gui.BgColor := "0xEE0000"
		this.parent.parent.ChildCanvas.Onsize()
	}
	
	TaskMaximized(){
		cw := this.GetChildWindow()
		
		;this.parent.ChildMaximized(this.options.MainHwnd)
		cw.Gui.Restore()
		this.Gui.BgColor := "0x00EE00"
		cw.IsMinimized := 0
		this.parent.parent.ChildCanvas.Onsize()
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
		return this.parent.parent.ChildCanvas.ChildWindows[this.options.MainHwnd]
	}
}
