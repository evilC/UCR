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
			this.options := {x: 0, y: 0}
		} else {
			this.options := options
			if (!options.x){
				this.options.x := 0
			}
			if (!options.y){
				this.options.y := 0
			}
		}
		
		; Adjust coordinates to cater for current position of parent's scrollbar.
		offset := this.GetWindowOffSet(this.parent.Hwnd)	; Get offset due to position of scroll bars
		this.options.x += offset.x
		this.options.y += offset.y
		
		; Create the GUI
		this.Gui := GuiCreate(this.options.title ,"+Parent" . this.parent.Hwnd,this)
		;this.Gui.AddLabel("I am " . this.Gui.Hwnd)	;this.Gui.Hwnd
		this.Gui.Show("x" . this.options.x . " y" . this.options.y . " w300 h100")
		
		this.Hwnd := this.Gui.Hwnd
	}
}
