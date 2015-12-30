/*
Handles monitoring of input for a profile.
Done in a separate thread for the following reasons:
1) Hotkeys can be quickly turned on or off for a profile by using Suspend
2) Non-native input bindings (eg Hat bindings, axis bindings) can be emulated using timers without impacting debugging of the main thread.
*/
#Persistent
#NoTrayIcon
autoexecute_done := 1
return

class _InputThread {
	Bindings := {}			; List of current Button bindings, indexed by HWND of hotkey GuiControl
	Axes := {}				; Holds all information regarding bound axes {AxisObj: axis object, state: current state, bindstring: eg "2joyX"}
	Hats := {}				; ToDo: collapse hat data into one object like axes
	HatBindstrings := {}
	HatStates := {}
	JoystickTimerState := 0
	PovMap := [[0,0,0,0], [1,0,0,0], [1,1,0,0] , [0,1,0,0], [0,1,1,0], [0,0,1,0], [0,0,1,1], [0,0,0,1], [1,0,0,1]]
	
	__New(CallbackPtr){
		this.CallbackPtr := CallbackPtr
		this.Callback := Object(CallbackPtr)
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
	
	; Starts or stops the SetTimer that polls joystick axis / hat state
	SetJoystickTimerState(state){
		fn := this.JoystickWatcherFn
		if (state){
			SetTimer, % fn, 10
		} else {
			SetTimer, % fn, Off
		}
		this.JoystickTimerState := state
	}
	
	; Sets a button binding.
	; This can either be using AHK hotkeys (for regular keyboard, mouse, joystick button down events etc)...
	; ... or for "emulated" events such as joystick hat direction press/release, or simulating "proper" up events for joystick buttons
	SetButtonBinding(hk, hkstring := ""){
		hk := Object(hk)
		hwnd := hk.hwnd
		; ToDo: Fix bug: If old binding was a different type, it will not get removed
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
			;OutputDebug % "Setting Binding for hotkey " hk.name " to " hkstring
			if (!hkstring){
				;OutputDebug % "Deleting hotkey " this.Bindings[hwnd]
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
	
	; Cause an axis to be watched, and fire a callback when it changes.
	; AxisObj is the Axis GuiControl object.
	; Set delete to 1 to force a delete (so if you delete a plugin still set to an axis, you can force a delete)
	SetAxisBinding(AxisObj, delete := 0){
		static AHKAxisList := ["X","Y","Z","R","U","V"]
		AxisObj := Object(AxisObj)
		oldstate := this.JoystickTimerState
		if (oldstate)
			this.SetJoystickTimerState(0)
		if (delete || !AxisObj.__value.DeviceID || !AxisObj.__value.Axis){
			this.Axes.Delete(AxisObj.hwnd)
		} else {
			this.Axes[AxisObj.hwnd] := {AxisObj: AxisObj, state: 0, bindstring: AxisObj.__value.DeviceID "joy" AHKAxisList[AxisObj.__value.Axis]}
		}
		if (oldstate)
			this.SetJoystickTimerState(1)
	}
	
	; Rename - handles axes too
	InputEvent(hk, event){
		; ToDo: Fix bug - The below line seems to be firing with empty event - even when no keys are pressed.
		this.Callback.Call(&hk,event)
		
		; Simulate up events for joystick buttons
		if (hk.__value.Type = 2){
			;OutputDebug % "Waiting for release of bindstring " this.Bindings[hk.hwnd]
			while (GetKeyState(this.Bindings[hk.hwnd])){
				Sleep 10
			}
			;OutputDebug % "release detected of bindstring " this.Bindings[hk.hwnd]
			this.Callback.Call(&hk,0)
		}
	}
	
	; Polls state of joystick for change in axis or POV hat state
	JoystickWatcher(){
		for hwnd, o in this.Axes {
			if (o.bindstring){
				state := GetKeyState(o.bindstring)
				; ToDo: state != "" is to do with bug with InputEvent being called when it shouldnt. Should not be needed
				if (state != "" && state != o.state){
					o.state := state
					this.InputEvent(o.AxisObj, state)
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