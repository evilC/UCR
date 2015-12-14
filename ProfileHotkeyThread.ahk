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
	JoystickTimerState := 0
	
	__New(parent){
		this.MasterThread := AhkExported()
		this.JoystickWatcherFn := this.JoystickWatcher.Bind(this)
		this.SetHotkeyState(0)
	}
	
	; rename - handles axes too
	SetHotkeyState(state){
		if (state){
			Suspend, Off
		} else {
			Suspend, On
		}
		this.SetJoystickTimerState(state)
	}
	
	SetJoystickTimerState(state){
		fn := this.JoystickWatcherFn
		if (state){
			SetTimer, % fn, 10
		} else {
			SetTimer, % fn, Off
		}
		this.JoystickTimerState := state
	}
	
	SetButtonBinding(hk, hkstring := ""){
		hk := Object(hk)
		hwnd := hk.hwnd
		OutputDebug % "Setting Binding for hotkey " hk.name " to " hkstring
		if (!hkstring){
			OutputDebug % "Deleting hotkey " this.Bindings[hwnd]
			if (this.Bindings[hwnd]){
				hotkey, % this.Bindings[hwnd], Dummy
				hotkey, % this.Bindings[hwnd], Off
				try {
					hotkey, % this.Bindings[hwnd] " up", Dummy
					hotkey, % this.Bindings[hwnd] " up", Off
				}
			}
			this.Bindings.Delete(hwnd)
			return
		}
		if (ObjHasKey(this.Bindings, hwnd)){
			hotkey, % this.Bindings[hwnd], Off
			try {
				hotkey, % this.Bindings[hwnd] " up", Off
			}
		}
		this.Bindings[hwnd] := hkstring
		fn := this.InputEvent.Bind(this, hk, 1)
		hotkey, % hkstring, % fn, On
		; Do not bind up events for joystick buttons as they fire straight after the down event (are inaccurate)
		if (hk.__value.Type = 1){
			fn := this.InputEvent.Bind(this, hk, 0)
			hotkey, % hkstring " up", % fn, On
		}
	}
	
	SetAxisBinding(AxisObj){
		AxisObj := Object(AxisObj)
		oldstate := this.JoystickTimerState
		if (oldstate)
			this.SetJoystickTimerState(0)
		if (AxisObj.__value.bindstring == ""){
			this.Axes.Delete(AxisObj.hwnd)
		} else {
			this.Axes[AxisObj.hwnd] := AxisObj
		}
		if (oldstate)
			this.SetJoystickTimerState(1)
	}
	
	; Rename - handles axes too
	InputEvent(hk, event){
		this.MasterThread.ahkExec("UCR._InputHandler.InputEvent(" &hk "," event ")")
		; Simulate up events for joystick buttons
		if (hk.__value.Type = 2){
			OutputDebug % "Waiting for release of bindstring " this.Bindings[hk.hwnd]
			while (GetKeyState(this.Bindings[hk.hwnd])){
				Sleep 10
			}
			OutputDebug % "release detected of bindstring " this.Bindings[hk.hwnd]
			this.MasterThread.ahkExec("UCR._InputHandler.InputEvent(" &hk "," 0 ")")
		}
	}
	
	JoystickWatcher(){
		for hwnd, AxisObj in this.Axes {
			bindstring := AxisObj.__value.bindstring
			if (bindstring){
				state := GetKeyState(bindstring)
				if (state != AxisObj.InputState){
					AxisObj.InputState := state
					this.InputEvent(AxisObj, state)
					;OutputDebug % "State " bindstring " changed to: " state
				}
			}
		}
	}
}

; Bind hotkeys to this to clear their binding, deleting boundfunc objects
Dummy:
	return