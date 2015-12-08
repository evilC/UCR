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
	Axes := {}
	
	__New(parent){
		this.ParentProfile := Object(parent)
		this.MasterThread := AhkExported()
		this.JoystickWatcherFn := this.JoystickWatcher.Bind(this)
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
	
	SetAxisBinding(AxisObj){
		AxisObj := Object(AxisObj)
		fn := this.JoystickWatcherFn
		SetTimer, % fn, Off
		if (AxisObj.__value.bindstring == ""){
			this.Axes.Delete(AxisObj.hwnd)
		} else {
			this.Axes[AxisObj.hwnd] := AxisObj
		}
		SetTimer, % fn, 10
	}
	
	; Rename - handles axes too
	KeyEvent(hk, event){
		this.MasterThread.ahkExec("UCR._HotkeyHandler.KeyEvent(" &hk "," event ")")
	}
	
	JoystickWatcher(){
		for hwnd, AxisObj in this.Axes {
			bindstring := AxisObj.__value.bindstring
			if (bindstring){
				state := GetKeyState(bindstring)
				if (state != AxisObj.InputState){
					AxisObj.InputState := state
					this.KeyEvent(AxisObj, state)
					;OutputDebug % "State " bindstring " changed to: " state
				}
			}
		}
	}
}

; Bind hotkeys to this to clear their binding, deleting boundfunc objects
Dummy:
	return