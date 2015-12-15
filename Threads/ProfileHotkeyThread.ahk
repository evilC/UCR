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
	AxisStates := {}
	Hats := {}
	HatBindstrings := {}
	HatStates := {}
	JoystickTimerState := 0
	PovMap := [[0,0,0,0], [1,0,0,0], [1,1,0,0] , [0,1,0,0], [0,1,1,0], [0,0,1,0], [0,0,1,1], [0,0,0,1], [1,0,0,1]]
	
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
		if (hk.__value.Type = 3){
			; joystick hat
			OutputDebug % "bind stick " hk.__value.Buttons[1].deviceid ", hat dir " hk.__value.Buttons[1].code ", bindstring: " hkstring
			oldstate := this.JoystickTimerState
			this.SetJoystickTimerState(0)
			if (hkstring == "" || this.Hats[hwnd]){
				; Remove existing binding
				this.Hats.Delete(hwnd)
				this.HatBindstrings.Delete(hwnd)
				this.HatStates.Delete(hwnd)
			}
			this.Hats[hwnd] := hk
			this.HatBindstrings[hwnd] := hkstring
			this.HatStates[hwnd] := 0
			if (oldstate)
				this.SetJoystickTimerState(1)
		} else {
			OutputDebug % "type is " hk.__value.type
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
	}
	
	SetAxisBinding(AxisObj){
		AxisObj := Object(AxisObj)
		oldstate := this.JoystickTimerState
		if (oldstate)
			this.SetJoystickTimerState(0)
		if (AxisObj.__value.bindstring == ""){
			this.Axes.Delete(AxisObj.hwnd)
			this.AxisStates.Delete(AxisObj.hwnd)
		} else {
			this.Axes[AxisObj.hwnd] := AxisObj
			this.AxisStates[AxisObj.hwnd] := 0
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
			; ToDo: This was passed in? No need to store on axisobj?
			bindstring := AxisObj.__value.bindstring
			if (bindstring){
				state := GetKeyState(bindstring)
				if (state != this.AxisStates[hwnd]){
					this.AxisStates[hwnd] := state
					this.InputEvent(AxisObj, state)
					;OutputDebug % "State " bindstring " changed to: " state
				}
			}
		}
		for hwnd, HatObj in this.Hats {
			bindstring := this.HatBindstrings[hwnd]
			if (bindstring){
				state := GetKeyState(bindstring)
				; Get direction
				state := (state = -1 ? 1 : round(state / 4500) + 2)
				; Get state of that direction
				state := this.PovMap[state, HatObj.__value.Buttons[1].code]
				
				if (state != this.HatStates[hwnd]){
					this.HatStates[hwnd] := state
					this.InputEvent(HatObj, state)
				}
			}
		}
	}
}

; Bind hotkeys to this to clear their binding, deleting boundfunc objects
Dummy:
	return