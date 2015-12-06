/*
Handles binding of hotkeys for a profile.
Done in a separate thread so that hotkeys can be quickly turned on or off for a profile by using Suspend
*/
#Persistent
#NoTrayIcon
autoexecute_done := 1
return

class _HotkeyThread {
	Bindings := {}	; List of current bindings, indexed by HWND of hotkey GuiControl
	__New(parent){
		this.ParentProfile := Object(parent)
		this.MasterThread := AhkExported()
		Suspend, On
	}
	
	SetHotkeyState(state){
		if (state){
			Suspend, Off
		} else {
			Suspend, On
		}
	}
	
	SetBinding(hk, hkstring := ""){
		hk := Object(hk)
		hwnd := hk.hwnd
		OutputDebug % "Setting Binding for hotkey " hk.name " to " hkstring
		if (!hkstring){
			OutputDebug % "Deleting hotkey " this.Bindings[hwnd]
			if (this.Bindings[hwnd]){
				hotkey, % this.Bindings[hwnd], Dummy
				hotkey, % this.Bindings[hwnd], Off
				hotkey, % this.Bindings[hwnd] " up", Dummy
				hotkey, % this.Bindings[hwnd] " up", Off
			}
			this.Bindings.Delete(hwnd)
			return
		}
		if (ObjHasKey(this.Bindings, hwnd)){
			hotkey, % this.Bindings[hwnd], Off
			hotkey, % this.Bindings[hwnd] " up", Off
		}
		this.Bindings[hwnd] := hkstring
		fn := this.KeyEvent.Bind(this, hk, 1)
		hotkey, % hkstring, % fn, On
		fn := this.KeyEvent.Bind(this, hk, 0)
		hotkey, % hkstring " up", % fn, On
	}
	
	KeyEvent(hk, event){
		this.MasterThread.ahkExec("UCR._InputHandler.KeyEvent(" &hk "," event ")")
	}
}

Dummy:
	return