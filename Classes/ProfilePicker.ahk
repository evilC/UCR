; =================================================================== PROFILE PICKER ==========================================================
; A tool for plugins that allows users to pick a profile (eg for a profile switcher plugin). Cannot alter profile tree
class _ProfilePicker extends _ProfileTreeBase {
	__New(){
		base.__New()
		; Initialize resizing system to min size of gui
		Gui, % this.hwnd ":Show", % "Hide"
		
		Gui, % this.hwnd ":+Minsize" 120 "x" 110
	}
	
	_CurrentCallback := 0
	TV_Event(){
		if (A_GuiEvent == "DoubleClick"){
			this._CurrentCallback.Call(this.LvHandleToProfileId[A_EventInfo])
			Gui, % this.hwnd ":Hide"
			this._CurrentCallback := 0
		}
	}
	
	PickProfile(callback, currentprofile){
		this._CurrentCallback := callback
		CoordMode, Mouse, Screen
		MouseGetPos, x, y
		this.BuildProfileTree()
		this.SelectProfileByID(currentprofile)
		Gui, % this.hwnd ":Show", % "x" x - 110 " y" y - 5 " w200 h200", Profile Picker
		UCR.MoveWindowToCenterOfGui(this.hwnd)
	}
}
