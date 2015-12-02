#Persistent
;#NoTrayIcon
;HotkeyThread := new _HotkeyThread()
autoexecute_done := 1
return

class _HotkeyThread {
	Bindings := {}	; List of current bindings, indexed by HWND of hotkey GuiControl
	__New(parent){
		this.ParentProfile := Object(parent)
		Suspend, On
	}
	
	SetHotkeyState(state){
		if (state){
			OutputDebug % "Turning hotkeys on"
			Suspend, Off
		} else {
			OutputDebug % "Turning hotkeys off"
			Suspend, On
		}
	}
	
	SetBinding(hwnd, hkstring){
		OutputDebug % "Setting Binding for hwnd " hwnd " to " hkstring
		if (ObjHasKey(this.Bindings, hwnd)){
			hotkey, % this.Bindings[hwnd], Off
		}
		if (!hkstring){
			this.Bindings.Delete(hwnd)
			return
		}
		this.Bindings[hwnd] := hkstring
		fn := this.KeyEvent.Bind(this, hwnd, 1)
		hotkey, % hkstring, % fn, On
	}
	
	KeyEvent(hwnd, event){
		SoundBeep
	}
	
	Test(){
		msgbox % "Parent Name: " this.ParentProfile.name
	}
}