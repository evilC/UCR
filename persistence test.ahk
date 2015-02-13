#SingleInstance force

MyClass := new MyClass()
return

Esc::
GuiClose:
	ExitApp

Class MyClass extends _CPersistentWindow {
	__New(){
		base.__New()
		this.GUI_WIDTH := 200
		this.Gui("Margin",5,5)
		this.Gui("Add", "Text", "Center xm ym w" this.GUI_WIDTH, "Persistent (Change and Reload)")
		this.myedit := this.Gui("Add", "Edit","xm yp+20 w" this.GUI_WIDTH,"ChangeMe")
		this.myedit.MakePersistent("somename")
		this.mybtn := this.Gui("Add","Button","xm yp+30 w" this.GUI_WIDTH,"Copy")
		this.GuiControl("+g", this.mybtn, this.Test)	; pass object to bind g-label to, and method to bind to
		this.GuiControl("+g", this.myedit, this.EditChanged)
		this.myoutput := this.Gui("Add","Edit","xm yp+30 w" this.GUI_WIDTH,"")
		this.Gui("Show", ,"Class Test")
	}
	
	Test(){
		; Copy contents of one edit box to another
		this.myoutput.value := this.myedit.value
			SoundBeep
	}
	
	EditChanged(){
		; Pull contents of edit box with .value
		this.ToolTip(this.myedit.value, 2000)
	}
}

; Implement GuiControl persistence with IniRead / IniWrite
class _CPersistentWindow extends _CWindow {
	Class _CGuiControl extends _CWindow._CGuiControl {
		; hook into the onchange event
		OnChange(){
			; IniWrite etc ...
			if (this._PersistenceName){
				val := this.value
				sn := A_ScriptName ".ini"
				k := this._PersistenceName
				IniWrite, % this.value, % A_ScriptName ".ini", Settings, % this._PersistenceName
			}
		}
		
		; 
		MakePersistent(Name){
			; IniRead etc
			this._PersistenceName := Name
			IniRead, val, % A_ScriptName ".ini", Settings, % this._PersistenceName, -1
			if (val != -1){
				this.value := val
			}
		}
	}
}

; Wrap AHK functionality in a standardized, easy to use, syntactically similar class
Class _CWindow {
	; equivalent to Gui, New, <params>
	__New(aParams*){
		Gui, new, % "hwndhwnd " aParams[1], % aParams[2], % aParams[3]
		this._hwnd := hwnd
	}
	
	Gui(aParams*){
		if (aParams[1] = "new"){
			Gui, new, % "hwndhwnd " aParams[2], % aParams[3], % aParams[4]
			this._hwnd := hwnd
		} else if (aParams[1] = "add") {
			return new this._CGuiControl(this, aParams[2], aParams[3], aParams[4])
		} else {
			Gui, % this._hwnd ":" aParams[1], % aParams[2], % aParams[3], % aParams[4]
		}
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
				aParams[2]._glabel := fn
				fn := bind(aParams[2]._OnChange,aParams[2])
				GuiControl % aParams[1], % aParams[2]._hwnd, % fn
			}
		} else {
			GuiControl, % aParams[1], % aParams[2]._hwnd, % aParams[3]
		}
	}
	
	; Gui Controls
	Class _CGuiControl {
		_glabel := 0
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
		
		__Set(aParam, aValue){
			if (aParam = "value"){
				return this._parent.GuiControl(,this,aValue)
			}
		}
		
		; Override this to hook into change events independently of g-label.
		; Use to make GuiControls persistent between runs etc (ie save in INI file)
		OnChange(){
			
		}
		
		; Called if a g-label is active OR persistence is on.
		_OnChange(){
			this.OnChange()	; Provide hook to update INI file etc
			if (this._glabel != 0){
				ret := this._glabel.()
				if (ret = 0){
					; 
				}
			}
		}
	}
	
	ToolTip(Text, duration){
		fn := bind(this.ToolTipTimer, this)
		this._TooltipActive := fn
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