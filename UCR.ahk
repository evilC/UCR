#SingleInstance force

#include class_scrollgui.ahk

UCR := new UCR()
return

Esc::
GuiClose:
	ExitApp

Class UCR extends _CWindow {
	Plugins := []
	__New(){
		base.__New()
		this.myedit := this.Add("Edit","xm ym w100","ChangeMe")
		this.mybtn := this.Add("Button","xm yp+20 w100","Beep")
		this.Show("w500 h400", "UCR")
		this.GuiControl("+g", this.mybtn, this.Test)
		this.GuiControl("+g", this.myedit, this.EditChanged)
		
		this.ChildWindow := new _CWindow("-Border +Parent" this._hwnd)
		this.ChildWindow.Show("x175 y0 w300 h400")
		Gui, Margin, 20, 20
		Loop 10 {
			this.Plugins.Insert(new _CWindow("-Border +Parent" this.ChildWindow._hwnd))
			this.Plugins[A_Index].Add("Text", "xm ym", "Child" A_Index)
			this.Plugins[A_Index].Show("h40 w380 x5 y" (A_Index - 1)*50 )
		}
		; Create ScrollGUI1 with both horizontal and vertical scrollbars and mouse wheel capturing
		this.SG1 := New ScrollGUI(this.ChildWindow._hwnd, 300, 400, "-Border +Parent" this._hwnd, 3, 3)
		; Show ScrollGUI1
		this.SG1.Show("ScrollGUI1 Title", "x175 y0")
		this.SG1.AdjustToChild()
	}
	
	Test(){
		SoundBeep
	}
	
	EditChanged(){
		this.ToolTip(this.myedit.value, 2000)
	}
}

; Wrap AHK functionality in a standardized, easy to use, syntactically similar class
Class _CWindow {
	; equivalent to Gui, New, <params>
	__New(aParams*){
		Gui, new, % "hwndhwnd " aParams[1], % aParams[2], % aParams[3]
		this._hwnd := hwnd
	}
	
	; Equivalent to Gui, Add, <params>
	Add(aParams*){
		return new this._CGuiControl(this, aParams*)
	}
	
	; Equivalent to Gui, Show, <params>
	Show(aParams*){
		Gui, % this._hwnd ":Show", % aParams[1], % aParams[2], % aParams[3]
	}
	
	; Wraps GuiControl to use hwnds and function binding etc
	GuiControl(aParams*){
		m := SubStr(aParams[1],1,1)
		if (m = "+" || m = "-"){
			; Options
			o := SubStr(aParams[1],2,1)
			if (o = "g"){
				; G-Label
				fn := bind(aParams[3],this)
				GuiControl % aParams[1], % aParams[2]._hwnd, % fn
			}
		} else {
			GuiControl, % aParams[1], % aParams[2]._hwnd, % aParams[3]
		}
	}
	
	; Gui Controls
	Class _CGuiControl {
		; equivalent to Gui, Add, <params>
		; Pass parent as param 1
		__New(aParams*){
			this._parent := aParams[1]
			this._type := aParams[2]
			Gui, % this._parent._hwnd ":Add", % aParams[2], % "hwndhwnd " aParams[3], % aParams[4]
			this._hwnd := hwnd
		}
		
		__Get(aParam){
			if (aParam = "value"){
				; ToDo: What about other types?
				;if (this._type = "listview"){
				GuiControlGet, val, , % this._hwnd
				return val
			}
		}
	}
	
	ToolTip(Text, duration){
		fn := bind(this.ToolTipTimer, this)
		SetTimer, % fn, % "-" duration
		ToolTip % Text
	}
	
	ToolTipTimer(){
		ToolTip
	}
}

bind(fn, args*) {  ; bind v1.2
    try bound := fn.bind(args*)  ; Func.Bind() not yet implemented.
    return bound ? bound : new BoundFunc(fn, args*)
}

class BoundFunc {
    __New(fn, args*) {
        this.fn := IsObject(fn) ? fn : Func(fn)
        this.args := args
    }
    __Call(callee, args*) {
        if (callee = "" || callee = "call" || IsObject(callee)) {  ; IsObject allows use as a method.
            fn := this.fn, args.Insert(1, this.args*)
            return %fn%(args*)
        }
    }
}