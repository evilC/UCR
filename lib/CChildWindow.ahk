; A Child Window Within the scrolling sub-window
; parent = parent CLASS
; options = options to pass
; (Currently only supports x and y)
; Note that X and Y are RELATIVE TO THE CANVAS
; Eg if the window is scrolled half way down, adding at 0, 0 inserts it out of view at the top left corner!
class CChildWindow extends CWindow {
	IsMinimized := 0
	
	__New(parent, options := false){
		this.parent := parent
		
		if (!options){
			options := {x:0, y: 0}
		} else {
			if (!options.x){
				options.x := 0
			}
			if (!options.y){
				options.y := 0
			}
		}
		
		; Adjust coordinates to cater for current position of parent's scrollbar.
		offset := this.GetWindowOffSet(this.parent.Hwnd)	; Get offset due to position of scroll bars
		options.x += offset.x
		options.y += offset.y
		
		; Create the GUI
		this.Gui := GuiCreate("Child","+Parent" . this.parent.Hwnd,this)
		this.Gui.AddLabel("I am " . this.Gui.Hwnd)	;this.Gui.Hwnd
		this.Gui.Show("x" . options.x . " y" . options.y . " w300 h100")
		
		this.Hwnd := this.Gui.Hwnd
	}
	
	OnSize(){
		
		if (WinGetMinMax("ahk_id " . this.Hwnd) == -1){
			this.parent.ChildMinimized(this.Hwnd)
		}
		/* else {
			this.parent.ChildMaximized(this.Hwnd)
		}
		*/
	}
	
	OnClose(){
		this.parent.ChildClosed(this.Hwnd)
	}
}
