#SingleInstance force

#include class_scrollgui.ahk

UCR := new UCR()
return

Esc::
GuiClose:
	ExitApp

Class UCR extends _CWindow {
	__New(){
		base.__New()
		this.mytext := this.Add("Text","xm ym","Blah")
		this.mybtn := this.Add("Button","xm yp+20","Test")
		this.Show("w500 h400", "UCR")
		this.GuiControl("+g", this.mybtn, this.Test)
		
		Gui, new, % "hwndhwnd -Border +Parent" this.hMain
		this.hChild := hwnd
		Gui, % this.hChild ":show", % "x175 y0 w300 h400"
		Gui, Margin, 20, 20
		Loop 10 {
			Gui, new, % "hwndChild -Border +Parent" this.hChild
			Gui, % Child ":Add", Text, % "xm ym", Child %A_Index%
			Gui, % Child ":Show", % "h40 w380 x5 y" (A_Index - 1)*50,
		}
		; Create ScrollGUI1 with both horizontal and vertical scrollbars and mouse wheel capturing
		this.SG1 := New ScrollGUI(this.hChild, 300, 400, "-Border +Parent" this.hMain, 3, 3)
		; Show ScrollGUI1
		this.SG1.Show("ScrollGUI1 Title", "x175 y0")
		this.SG1.AdjustToChild()
	}
	
	Test(){
		SoundBeep
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
		return new this.Control(this, aParams*)
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
	Class Control {
		; equivalent to Gui, Add, <params>
		; Pass parent as param 1
		__New(aParams*){
			this._parent := aParams[1]
			Gui, % this._parent._hwnd ":Add", % aParams[2], % "hwndhwnd " aParams[3], % aParams[4]
			this._hwnd := hwnd
		}
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