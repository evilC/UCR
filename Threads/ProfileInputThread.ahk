/*
Handles monitoring of input for a profile.
Done in a separate thread for the following reasons:
1) Hotkeys can be quickly turned on or off for a profile by using Suspend
2) Non-native input bindings (eg Hat bindings, axis bindings) can be emulated using timers without impacting debugging of the main thread.
*/
#Persistent
#NoTrayIcon
#MaxHotkeysPerInterval 9999
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
	MouseDeltaMappings := {}
	
	__New(CallbackPtr){
		this.Callback := ObjShare(CallbackPtr)
		Gui, +HwndHwnd		; Get a unique hwnd so we can register for messages
		this.hwnd := hwnd
		this.JoystickWatcherFn := this.JoystickWatcher.Bind(this)
		this.MouseTimeOutDuration := 10	; ToDo: Allow changing
		this.MouseTimeoutFn := this.OnMouseTimeout.Bind(this)
		this.MouseMoveFn := this.OnMouseMove.Bind(this)
		; Add interfaces so main thread can call methods in a thread-safe manner
		global _InterfaceSetHotkeyState := ObjShare(this.SetHotkeyState.Bind(this))
		global _InterfaceSetButtonBinding := ObjShare(this.SetButtonBinding.Bind(this))
		global _InterfaceSetAxisBinding := ObjShare(this.SetAxisBinding.Bind(this))
		global _InterfaceSetDeltaBinding := ObjShare(this.SetDeltaBinding.Bind(this))
		this.SetHotkeyState(0)
	}
	
	; All input flows from here back to the main thread
	InputEvent(hk, event){
		; ToDo: Fix bug - The below line seems to be firing with empty event - even when no keys are pressed.
		this.Callback.Call(hk._Ptr,event)
		
		; Simulate up events for joystick buttons
		if (hk.__value.Type = 2){
			;OutputDebug % "Waiting for release of bindstring " this.Bindings[hk.hwnd]
			while (GetKeyState(this.Bindings[hk.hwnd])){
				Sleep 10
			}
			;OutputDebug % "release detected of bindstring " this.Bindings[hk.hwnd]
			this.Callback.Call(hk._Ptr,0)
		}
	}

	; rename - handles axes too
	; The main thread requested a change in state of input
	SetHotkeyState(state){
		if (state){
			Suspend, Off
			if (MouseDeltaMappings != {})
				this.RegisterMouse()
		} else {
			Suspend, On
			if (MouseDeltaMappings != {})
				this.UnRegisterMouse()
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

	; The main thread asked for a change in button binding.
	SetButtonBinding(hk, hkstring := ""){
		; Allow call from main thread to return before attempting to use the object it passed.
		fn := this.SetButtonBindingCallback.Bind(this,ObjShare(hk), hkstring)
		SetTimer,% fn,-1
	}
	
	; Sets a button binding.
	; This can either be using AHK hotkeys (for regular keyboard, mouse, joystick button down events etc)...
	; ... or for "emulated" events such as joystick hat direction press/release, or simulating "proper" up events for joystick buttons
	SetButtonBindingCallback(hk, hkstring := ""){
		hwnd := hk.hwnd
		; ToDo: Fix bug: If old binding was a different type, it will not get removed
		if (hk.__value.Type = 3){
			; joystick hat
			;OutputDebug % "bind stick " hk.__value.Buttons[1].deviceid ", hat dir " hk.__value.Buttons[1].code ", bindstring: " hkstring
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
			;OutputDebug % "Binding " hkstring
			fn := this.InputEvent.Bind(this, hk, 1)
			hotkey, % hkstring, % fn, On
			; Do not bind up events for joystick buttons as they fire straight after the down event (are inaccurate)
			if (hk.__value.Type = 1){
				fn := this.InputEvent.Bind(this, hk, 0)
				hotkey, % hkstring " up", % fn, On
			}
		}
	}

	; The main thread requested a change in axis binding
	SetAxisBinding(AxisObj, delete := 0){
		fn := this.SetAxisBindingCallBack.Bind(this,ObjShare(AxisObj), delete)
		SetTimer,% fn,-1
	}
	
	; Cause an axis to be watched, and fire a callback when it changes.
	; AxisObj is the Axis GuiControl object.
	; Set delete to 1 to force a delete (so if you delete a plugin still set to an axis, you can force a delete)
	SetAxisBindingCallBack(AxisObj, delete := 0){
		static AHKAxisList := ["X","Y","Z","R","U","V"]
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
	
	; The main thread requested a (mouse) delta binding
	SetDeltaBinding(DeltaObj, delete := 0){
		fn := this.SetDeltaBindingCallBack.Bind(this,ObjShare(DeltaObj), delete)
		SetTimer,% fn,-1
	}
	
	; Subscribes to "delta" mouse movement
	SetDeltaBindingCallBack(DeltaObj, delete := 0){
		if (DeltaObj.value == "")	; ToDo: bit of a bodge. Fix. Remove delete param?
			delete := 1
		if (delete){
			this.MouseDeltaMappings.Delete(DeltaObj.hwnd)
		} else {
			this.MouseDeltaMappings[DeltaObj.hwnd] := DeltaObj
		}
		if (this.MouseDeltaMappings == {}){
			this.UnRegisterMouse()
		} else {
			this.RegisterMouse()
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
	
	RegisterMouse(){
		static RIDEV_INPUTSINK := 0x00000100
		; Register mouse for WM_INPUT messages.
		static DevSize := 8 + A_PtrSize
		static RAWINPUTDEVICE := 0
		if (RAWINPUTDEVICE == 0){
			VarSetCapacity(RAWINPUTDEVICE, DevSize)
			NumPut(1, RAWINPUTDEVICE, 0, "UShort")
			NumPut(2, RAWINPUTDEVICE, 2, "UShort")
			NumPut(RIDEV_INPUTSINK, RAWINPUTDEVICE, 4, "Uint")
			; WM_INPUT needs a hwnd to route to, so get the hwnd of the AHK Gui.
			; It doesn't matter if the GUI is showing, as long as it exists
			NumPut(this.hwnd, RAWINPUTDEVICE, 8, "Uint")
		}
		DllCall("RegisterRawInputDevices", "Ptr", &RAWINPUTDEVICE, "UInt", 1, "UInt", DevSize )
		OnMessage(0x00FF, this.MouseMoveFn, -1)
	}
	
	UnRegisterMouse(){
		static RIDEV_REMOVE := 0x00000001
		static DevSize := 8 + A_PtrSize
		
		fn := this.MouseTimeoutFn
		SetTimer, % fn, Off
		
		;RAWINPUTDEVICE := this.RAWINPUTDEVICE
		static RAWINPUTDEVICE := 0
		if (RAWINPUTDEVICE == 0){
			VarSetCapacity(RAWINPUTDEVICE, DevSize)
			NumPut(1, RAWINPUTDEVICE, 0, "UShort")
			NumPut(2, RAWINPUTDEVICE, 2, "UShort")
			NumPut(RIDEV_REMOVE, RAWINPUTDEVICE, 4, "Uint")
		}
		DllCall("RegisterRawInputDevices", "Ptr", &RAWINPUTDEVICE, "UInt", 0, "UInt", DevSize )
		OnMessage(0x00FF, this.MouseMoveFn, 0)
	}
	
	; Called when the mouse moved.
	; Messages tend to contain small (+/- 1) movements, and happen frequently (~20ms)
	OnMouseMove(wParam, lParam){
		; RawInput statics
		static DeviceSize := 2 * A_PtrSize, iSize := 0, sz := 0, offsets := {x: (20+A_PtrSize*2), y: (24+A_PtrSize*2)}, uRawInput
 
		static axes := {x: 1, y: 2}
 
		; Find size of rawinput data - only needs to be run the first time.
		if (!iSize){
			r := DllCall("GetRawInputData", "UInt", lParam, "UInt", 0x10000003, "Ptr", 0, "UInt*", iSize, "UInt", 8 + (A_PtrSize * 2))
			VarSetCapacity(uRawInput, iSize)
		}
		sz := iSize	; param gets overwritten with # of bytes output, so preserve iSize
		; Get RawInput data
		r := DllCall("GetRawInputData", "UInt", lParam, "UInt", 0x10000003, "Ptr", &uRawInput, "UInt*", sz, "UInt", 8 + (A_PtrSize * 2))
 
		x := NumGet(&uRawInput, offsets.x, "Int")
		y := NumGet(&uRawInput, offsets.y, "Int")
 
		for hwnd, obj in this.MouseDeltaMappings {
			this.InputEvent(obj, {x: x, y: y})	; ToDo: This should be a proper I/O object type, like Buttons or Axes
		}
 
		; There is no message for "Stopped", so simulate one
		fn := this.MouseTimeoutFn
		SetTimer, % fn, % -this.MouseTimeOutDuration
	}
	
	OnMouseTimeout(){
		for hwnd, obj in this.MouseDeltaMappings {
			this.InputEvent(obj, {x: 0, y: 0})
		}
	}
}

; Bind hotkeys to this to clear their binding, deleting boundfunc objects
Dummy:
	return