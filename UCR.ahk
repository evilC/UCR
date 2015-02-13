#SingleInstance force
UCR := new UCR()
return

Esc::
GuiClose:
	ExitApp

class UCR extends _CAhkWrapper {
	__New(){
		this.hwnd := this.Gui("New")
		this.myedit := this.Gui("Add", "Edit", "xm ym")
		this.mytext := this.Gui("Add", "Text", "xm yp+20", "nothing")
		this.Gui("Show")
		this.GuiControl(,this.mytext, "Test")
	}
}

/*
class _CGui extends _CAhkWrapper {
	class Window {
		__New(aParams*){
			this.hwnd := this.Gui("New")
		}
		
		Add(aParams*){
			
		}
		
		Show(aParams*){
			this.Gui("Show")
		}
	}
}

class _CGuiControl extends _CAhkWrapper {
	__New(){
		
	}
}
*/

; A class to wrap AHK - standardize methods, improve v1/v2 portability etc.
class _CAhkWrapper {
	hwnd := 0
	; Essenially prefixes Gui commands with hwnds
	Gui(aParams*){
		if (aParams[1] = "new"){
			Gui, new, % "hwndhwnd " aParams[2], % aParams[3], % aParams[4]
			return hwnd	; up to you to store handle!
		} else if (aParams[1] = "add") {
			Gui, % this.hwnd ":Add", % aParams[2], % "hwndhwnd " aParams[3], % aParams[4]
			return hwnd	; up to you to store handle!
		} else {
			Gui, % this.hwnd ":" aParams[1], % aParams[2], % aParams[3], % aParams[4]
		}
		if (!hwnd){
		}
	}
	
	; Command to function
	GuiControl(aParams*){
		GuiControl, % aParams[1], % aParams[2], % aParams[3]
	}
}

