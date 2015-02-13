; REQUIRES AHK TEST BUILD from HERE: http://ahkscript.org/boards/viewtopic.php?f=24&t=5802
#SingleInstance force

MyClass := new MyClass()
return

Esc::
GuiClose:
	ExitApp

Class MyClass extends CWindow {
	__New(){
		base.__New()
		this.GUI_WIDTH := 200
		this.Gui("Margin",5,5)
		this.Gui("Add", "Text", "Center xm ym w" this.GUI_WIDTH, "Persistent (Remembered on Reload)")
		this.myedit := this.Gui("Add", "Edit","xm yp+20 w" this.GUI_WIDTH,"ChangeMe")
		this.myedit.MakePersistent("somename")
		this.mybtn := this.Gui("Add","Button","xm yp+30 w" this.GUI_WIDTH,"v Copy v")
		this.GuiControl("+g", this.mybtn, this.Test)	; pass object to bind g-label to, and method to bind to
		this.GuiControl("+g", this.myedit, this.EditChanged)
		this.Gui("Add", "Text", "Center xm yp+30 w" this.GUI_WIDTH, "Not Persistent (Lost on Reload)")
		this.myoutput := this.Gui("Add","Edit","xm yp+20 w" this.GUI_WIDTH,"")
		
		; Child Windows
		this.ChildWindow := new CWindow(this, "-Border")
		this.ChildWindow.GuiOption("+Parent", this)
		this.ChildWindow.Gui("Add","Text", "Center x0 y40 w" this.GUI_WIDTH, "CHILD GUI")
		this.ChildWindow.Gui("Show", "x2 y150 w" this.GUI_WIDTH " h100")
		this.Gui("Show", "h260","Class Test")
	}
	
	Test(){
		; Copy contents of one edit box to another
		this.myoutput.value := this.myedit.value
	}
	
	EditChanged(){
		; Pull contents of edit box with .value
		this.ToolTip(this.myedit.value, 2000)
	}
}

; Implement GuiControl persistence with IniRead / IniWrite
class CWindow extends _CGui {
	Class CGuiControl extends _CGuiControl {
		; hook into the onchange event
		OnChange(){
			; IniWrite
			if (this._PersistenceName){
				IniWrite, % this.value, % A_ScriptName ".ini", Settings, % this._PersistenceName
			}
		}
		
		; Set a GuiControl to be persistent.
		; If called on a GuiControl, and there is an existing setting for it, set the control to the setting value
		MakePersistent(Name){
			; IniRead
			this._PersistenceName := Name
			IniRead, val, % A_ScriptName ".ini", Settings, % this._PersistenceName, -1
			if (val != -1){
				this.value := val
			}
		}
	}
}

; Gui Controls
Class _CGuiControl extends _CGui {
	_glabel := 0
	; equivalent to Gui, Add, <params>
	; Pass parent as param 1
	__New(aParams*){
		this._parent := aParams[1]
		this._type := aParams[2]
		; Must use base gui commands here, as this.Gui("Add",...) points here!
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
			this._glabel.()
		}
	}
}

; Wrap AHK functionality in a standardized, easy to use, syntactically similar class
Class _CGui {
	; equivalent to Gui, New, <params>
	; put parent as param 1
	__New(parent := 0, Param2 := "", Param3 := "", Param4 := ""){
		this._parent := parent
		if (this.parent != 0){
			; parent passed
		}
		this.Gui("new", Param2, Param3, Param4)
	}
	
	Gui(aParams*){
		c := aParams[1]
		opts := this.ParseOptions(aParams[3])
		cmd := this.ParseOptions(aParams[1])
		if (opts.flags.parent || cmd.flags.parent){
			MsgBox % "Parent option not supported. Use GuiOption(""+Parent"", obj, ...)"
			return
		}
		if (aParams[1] = "new"){
			Gui, new, % "hwndhwnd " aParams[2], % aParams[3], % aParams[4]
			this._hwnd := hwnd
		} else if (aParams[1] = "add") {
			if (opts.flags.v || opts.flags.g){
				; v-label or g-label passed old-school style
				MsgBox % "v-labels and g-labels are not allowed.`n`Please consult the documentation for alternate methods to use."
				return
			}
			return new this.CGuiControl(this, aParams[2], aParams[3], aParams[4])
		} else {
			Gui, % this._hwnd ":" aParams[1], % aParams[2], % aParams[3], % aParams[4]
		}
	}
	
	; The same as Gui, +Option - but lets you pass objects instead of hwnds
	GuiOption(option, value){
		Gui, % this._hwnd ":" option, value
	}
	
	; Wraps GuiControl to use hwnds and function binding etc
	GuiControl(aParams*){
		m := SubStr(aParams[1],1,1)
		if (m = "+" || m = "-"){
			; Options
			o := SubStr(aParams[1],2,1)
			if (o = "g"){
				; Emulate G-Labels whilst also allowing seperate OnChange event to be Extended (For Saving settings in INI etc)
				; Bind g-label to _glabel property
				fn := bind(aParams[3],this)
				aParams[2]._glabel := fn
				; Bind glabel event to _OnChange method
				fn := bind(aParams[2]._OnChange,aParams[2])
				GuiControl % aParams[1], % aParams[2]._hwnd, % fn
			}
		} else {
			GuiControl, % aParams[1], % aParams[2]._hwnd, % aParams[3]
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
	
	; Parses an Option string into an object, for easy interpretation of which options it is setting
	ParseOptions(options){
		ret := { flags: {}, options: {}, signs: {} }
		opts := StrSplit(options, A_Space)
		Loop % opts.MaxIndex() {
			opt := opts[A_Index]
			; Strip +/- prefix if it exists
			sign := SubStr(opt,1,1)
			p := 0
			if (sign = "+" || sign = "-"){
				opt := SubStr(opt,2)
			} else {
				; default to being in + mode
				sign := "+"
			}
			vg := SubStr(opt,1,1)
			if (vg = "v" || vg = "g"){
				; v-label or g-label
				value := Substr(opt,2)
				opt := vg
			} else {
				; Take all the letters as the option
				opt := RegExReplace(opt, "^([a-z|A-Z]*)(.*)", "$1")
				; Take numbers as value
				value := RegExReplace(opt, "^([a-z|A-Z]*)(.*)", "$2")
			}
			
			ret.flags[opt] := 1
			ret.options[opt] := value
			ret.signs[opt] := sign
		}
		return ret
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