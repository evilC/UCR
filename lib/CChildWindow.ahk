; A Child Window Within the scrolling sub-window
; parent = parent CLASS
; options = options to pass
; (Currently only supports x and y)
; Note that X and Y are RELATIVE TO THE CANVAS
; Eg if the window is scrolled half way down, adding at 0, 0 inserts it out of view at the top left corner!
class CChildWindow extends CWindow {
	IsMinimized := 0
	
	__New(title := "", options := false, parent := 0){
		base.__New(title, options, parent)
		;this.Gui.AddLabel("I am " . this.Hwnd)
		;this.Gui.Show("x" . this.options.x . " y" . this.options.y . " w300 h100")
		;this.Gui.Show()
		
	}
}
