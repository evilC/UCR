; ToDo: Split IOClasses out into individual files
; ToDo: Rename these type of IOClasses to IOInputClasses?
#Include Functions\IsEmptyAssoc.ahk
#Include Libraries\XInput.ahk

#MaxThreads 255
#Noenv

; Can use  #Include %A_LineFile%\..\other.ahk to include in same folder
Class _InputThread {
	static IOClasses := {AHK_KBM_Input: 0, AHK_JoyBtn_Input: 0, AHK_JoyHat_Input: 0, AHK_JoyAxis_Input: 0, RawInput_Mouse_Delta: 0, XInput_Axis: 0, XInput_Button: 0}
	DetectionState := 0
	UpdateBindingQueue := []	; An array of bindings waiting to be updated.
	UpdatingBindings := 0
	
	__New(ProfileID, CallbackPtr){
		this.Callback := ObjShare(CallbackPtr)
		;this.Callback := CallbackPtr
		this.ProfileID := ProfileID ; Profile ID of parent profile. So we know which profile this thread serves
		names := ""
		i := 0
		; Instantiate each of the IOClasses specified in the IOClasses array
		for name, state in this.IOClasses {
			; Instantiate an instance of a class that is a child class of this one. Thanks to HotkeyIt for this code!
			; Replace each 0 in the array with an instance of the relevant class
			call:=this.base[name]
			this.IOClasses[name] := new call(this.Callback)
			; debugging string
			if (i)
				names .= ", "
			names .= name
			i++
		}
		if (i){
			OutputDebug % "UCR| Input Thread loaded IOClasses: " names
		} else {
			OutputDebug % "UCR| Input Thread WARNING! Loaded No IOClasses!"
		}
		
		; Set up interfaces that the main thread can call
		global InterfaceUpdateBinding := ObjShare(this.UpdateBinding.Bind(this))
		global InterfaceUpdateBindings := ObjShare(this.UpdateBindings.Bind(this))
		global InterfaceSetDetectionState := ObjShare(this.SetDetectionState.Bind(this))
		
		; Get a boundfunc for the method that processes binding updates
		;this.BindingQueueFn := this._ProcessBindingQueue.Bind(this)
		
		XInput_Init()
		
		; Unreachable dummy label for hotkeys to bind to to clear binding
		if(0){
			UCR_INPUTHREAD_DUMMY_LABEL:
				return
		}

	}

	;~ ; A request was received from the main thread to update a binding.
	;~ UpdateBinding(ControlGUID, boPtr){
		;~ bo := ObjShare(boPtr).clone()
		;~ fn := this._UpdateBinding.Bind(this, ControlGUID, bo)
		;~ SetTimer, % fn, -1
	;~ }
	
	;_UpdateBinding(ControlGUID, bo){
	UpdateBinding(ControlGUID, boPtr){
		bo := ObjShare(boPtr).clone()
		; Direct the request to the appropriate IOClass that handles it
		
		this.IOClasses[bo.IOClass].UpdateBinding(ControlGUID, bo)
		;OutputDebug % "UCR| Input Thread: Added Binding to queue as item# " this.UpdateBindingQueue.length()+1
		;this.UpdateBindingQueue.push({ControlGuid: ControlGuid, BindObject: bo})
		;this._SetBindingQueueTimerState()
	}

	; A request was received from the main thread to update all bindings in one go.
	;~ UpdateBindings(boPtr){
		;~ bo := ObjShare(boPtr).clone()
		;~ fn := this._UpdateBindings.Bind(this, bo)
		;~ SetTimer, % fn, -0
	;~ }

	;_UpdateBindings(arr){
	UpdateBindings(arrPtr){
		arr := ObjShare(arrPtr).clone()
		Loop % arr.length(){
			b := arr[A_Index]
			;OutputDebug % "UCR| Input Thread: Directing UpdateBindings to IOClass " b.BindObject.IOClass
			this.IOClasses[b.BindObject.IOClass].UpdateBinding(b.ControlGUID, b.BindObject)
			;this.UpdateBindingQueue.push(b)
		}
		;this._SetBindingQueueTimerState()
	}

	;~ _SetBindingQueueTimerState(){
		;~ if (this.UpdatingBindings)
			;~ return
		;~ if (this.UpdateBindingQueue.length()){
			;~ fn := this.BindingQueueFn
			;~ SetTimer, % fn, -0
		;~ }
	;~ }
	
	;~ ; Tries to ensure that binding updates are processed in order
	;~ ; The main thread calls UpdateBinding(s) asyncronously, so if one call interrupts another...
	;~ ; ... eg a call to delte an old binding may end up getting executed after the call to set the new binding.
	;~ _ProcessBindingQueue(){
		;~ this.UpdatingBindings := 1
		;~ queue := this.UpdateBindingQueue.clone()
		;~ for i, b in queue {
			;~ ;OutputDebug % "UCR| Input Thread: Processing Binding Queue item " i ". IOClass: " b.BindObject.IOClass ", DeviceID: " b.BindObject.DeviceID ", Binding: " b.BindObject.Binding[1]
			;~ this.IOClasses[b.BindObject.IOClass].UpdateBinding(b.ControlGUID, b.BindObject)
			;~ this.UpdateBindingQueue.RemoveAt(1)
		;~ }
		;~ ; If another binding was added whilst we were processing, then re-process again
		;~ if (this.UpdateBindingQueue.length()){
			;~ this._ProcessBindingQueue()
		;~ }
		;~ this.UpdatingBindings := 0
	;~ }
	
	; A request was received from the main thread to set the Dection state
	;~ SetDetectionState(state){
		;~ fn := this._SetDetectionState.Bind(this, state)
		;~ SetTimer, % fn, -0
	;~ }
	
	;~ _SetDetectionState(state){
	SetDetectionState(state){
		if (state == this.DetectionState)
			return
		this.DetectionState := state
		for name, cls in this.IOClasses {
			cls.SetDetectionState(state)
		}
	}
	
	; Listens for Keyboard and Mouse input using the AHK Hotkey command
	class AHK_KBM_Input {
		DetectionState := 0
		_AHKBindings := {}
		
		__New(callback){
			this.callback := callback
			Suspend, On	; Start with detection off, even if we are passed bindings
		}
		
		/*
		_Deserialize(obj){
			for k, v in obj {
				this[k] := v
			}
		}
		*/
		
		UpdateBinding(ControlGUID, bo){
			this.RemoveBinding(ControlGUID)
			if (bo.Binding[1]){
				keyname := "$" this.BuildHotkeyString(bo)
				fn := this.KeyEvent.Bind(this, ControlGUID, 1)
				hotkey, % keyname, % fn, On
				fn := this.KeyEvent.Bind(this, ControlGUID, 0)
				hotkey, % keyname " up", % fn, On
				;OutputDebug % "UCR| AHK_KBM_Input Added hotkey " keyname " for ControlGUID " ControlGUID
				this._AHKBindings[ControlGUID] := {KeyName: keyname, HasNoRelease: this.HasNoReleaseEvent(bo)}
			}
		}
		
		SetDetectionState(state){
			; Are we already in the requested state?
			; This code is rigged so that either AHK_KBM_Input or AHK_JoyBtn_Input or both will not clash...
			; ... As long as all are turned on or off together, you won't get weird results.
			if (A_IsSuspended == state){
				;OutputDebug % "UCR| Thread: AHK_KBM_Input IOClass turning Hotkey detection " (state ? "On" : "Off")
				Suspend, % (state ? "Off" : "On")
			}
			this.DetectionState := state
		}
		
		RemoveBinding(ControlGUID){
			keyname := this._AHKBindings[ControlGUID].KeyName
			if (keyname){
				;OutputDebug % "UCR| AHK_KBM_Input Removing hotkey " keyname " for ControlGUID " ControlGUID
				hotkey, % keyname, UCR_INPUTHREAD_DUMMY_LABEL
				hotkey, % keyname, Off
				hotkey, % keyname " up", UCR_INPUTHREAD_DUMMY_LABEL
				hotkey, % keyname " up", Off
				this._AHKBindings.Delete(ControlGUID)
			}
		}
		
		KeyEvent(ControlGUID, e){
			;~ OutputDebug % "UCR| AHK_KBM_Input Key event for GuiControl " ControlGUID ", state " e
			;msgbox % "Hotkey pressed - " this.ParentControl.Parentplugin.id
			;this.Callback.Call(ControlGUID, e)
			fn := this.InputEvent.Bind(this, ControlGUID, e)
			SetTimer, % fn, -0
			if (e && this._AHKBindings[ControlGUID].HasNoRelease){
				; Mouse wheel only has a down event, simulate an up event so that bind mode properly ends
				fn := this.InputEvent.Bind(this, ControlGUID, 0)
				SetTimer, % fn, -50
			}
		}
		
		InputEvent(ControlGUID, state){
			this.Callback.Call(ControlGUID, state)
			;~ OutputDebug % "UCR| AHK_KBM_Input Key event for GuiControl " ControlGUID " key: " this._AHKBindings[ControlGUID].KeyName
		}

		; Builds an AHK hotkey string (eg ~^a) from a BindObject
		BuildHotkeyString(bo){
			if (!bo.Binding.Length())
				return ""
			str := ""
			if (bo.BindOptions.Wild)
				str .= "*"
			if (!bo.BindOptions.Block)
				str .= "~"
			max := bo.Binding.Length()
			Loop % max {
				key := bo.Binding[A_Index]
				if (A_Index = max){
					islast := 1
					nextkey := 0
				} else {
					islast := 0
					nextkey := bo[A_Index+1]
				}
				if (this.IsModifier(key) && (max > A_Index)){
					str .= this.RenderModifier(key)
				} else {
					str .= this.BuildKeyName(key)
				}
			}
			return str
		}
		
		HasNoReleaseEvent(bo){
			max := bo.Binding.Length()
			Loop % max {
				key := bo.Binding[A_Index]
				if (key >= 156 && key <= 159){
					; Mouse Wheel
					return true
				}
			}
			return false
		}
		
		; === COMMON WITH IOCLASS. MOVE TO INCLUDE =====
		static _Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
		,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
		,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
		,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

		; Builds the AHK key name
		BuildKeyName(code){
			static replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 45: "Insert", 46: "Delete"}
			static additions := {14: "NumpadEnter"}
			if (ObjHasKey(replacements, code)){
				return replacements[code]
			} else if (ObjHasKey(additions, code)){
				return additions[code]
			} else {
				return GetKeyName("vk" Format("{:x}", code))
			}
		}
		
		; Returns true if this Button is a modifier key on the keyboard
		IsModifier(code){
			return ObjHasKey(this._Modifiers, code)
		}
		
		; Renders the keycode of a Modifier to it's AHK Hotkey symbol (eg 162 for LCTRL to ^)
		RenderModifier(code){
			return this._Modifiers[code].s
		}
		; ================= END MOVE TO INCLUDE ======================
	}
	
	class XInput_Button {
		; static buttonNames := ["A", "B", "X", "Y", "LB", "RB", "LS", "RS", "Back", "Start", "Up", "Right", "Down", "Left"]
		buttonFlags := [ 0x1000, 0x2000, 0x4000, 0x8000, 0x0100, 0x0200, 0x0040, 0x0080, 0x0020, 0x0010, 0x0001, 0x0008, 0x0002, 0x0004 ]
	
		StickBindings := {}
		/*
		StickBindings structure:
		{
			<Stick ID>: (eg 1) {
				<BindString (eg "1")>: {
					State: <current state>
					Subscriptions: {
						<guid>: 1,
						<guid>: 1,
					}
				}
			}
		}
		*/
	
		__New(Callback){
			this.Callback := Callback
			this.TimerFn := this.StickWatcher.Bind(this)
		}
		
		StickWatcher(){
			for dev, inputs in this.StickBindings {
				deviceState := XInput_GetState(dev-1)
				for flag, input_info in inputs {
					state := ((deviceState.Buttons & flag) == flag)
					
					if (state != input_info.state){
						input_info.state := state
						;~ OutputDebug % "UCR| XInput Firing Button " bindstring " Callback - " state
						for ControlGUID, unused in input_info.Subscriptions {
							fn := this.InputEvent.Bind(this, ControlGUID, state)
							SetTimer, % fn, -0
						}
					}
				}
			}
		}
		
		UpdateBinding(ControlGUID, bo){
			dev := bo.DeviceID, btn := bo.Binding[1]
			;~ OutputDebug % "UCR| XInput Update subscription device " dev ", button " btn
			; Remove old binding
			for id, inputs in this.StickBindings {
				for bindstring, input_info in inputs {
					for cguid, unused in input_info.Subscriptions {
						if (cguid == ControlGuid){
							input_info.Subscriptions.Delete(cguid)
							;OutputDebug % "UCR| Removing Binding for ControlGUID " cguid
							; ToDo: Should prune StickBindings array and stop watcher if needed
							break 3
						}
					}
				}
			}
			if (dev && btn){
				;~ str := this.axisNames[axis]
				str := this.buttonFlags[btn]
				if (!ObjHasKey(this.StickBindings, dev))
					this.StickBindings[dev] := {}
				if (!ObjHasKey(this.StickBindings[dev], str))
					this.StickBindings[dev, str] := {State: 0, Subscriptions: {}}
								
				this.StickBindings[dev, str, "Subscriptions", ControlGuid] := 1
				;OutputDebug % "UCR| SubCount: " this.StickBindings[dev, str, "Subscriptions", ControlGuid]
				this.TimerWanted := 1
			}
			this.ProcessTimerState()
		}
		
		SetDetectionState(state){
			;~ OutputDebug % "UCR| XInput_Button SetDetectionState = " state
			this.DetectionState := state
			this.ProcessTimerState()
		}
		
		ProcessTimerState(){
			fn := this.TimerFn
			if (this.TimerWanted && this.DetectionState && !this.TimerRunning){
				SetTimer, % fn, 10
				this.TimerRunning := 1
				OutputDebug % "UCR| XInput_Button Started ButtonWatcher"
			} else if ((!this.TimerWanted || !this.DetectionState) && this.TimerRunning){
				SetTimer, % fn, Off
				this.TimerRunning := 0
				OutputDebug % "UCR| XInput_Button Stopped ButtonWatcher"
			}
		}
		
		InputEvent(ControlGUID, state){
			this.Callback.Call(ControlGUID, state)
		}
	}
	
	class XInput_Axis {
		static axisNames := ["ThumbLX", "ThumbLY", "ThumbRX", "ThumbRY", "LeftTrigger", "RightTrigger"]

		StickBindings := {}
		/*
		StickBindings structure:
		{
			<Stick ID>: (eg 1) {
				<BindString (eg "LeftTrigger")>: {
					State: <current state>
					Subscriptions: {
						<guid>: 1,
						<guid>: 1,
					}
				}
			}
		}
		*/
		ConnectedSticks := [0,0,0,0]
		
		__New(Callback){
			this.Callback := Callback
			this.TimerFn := this.StickWatcher.Bind(this)
		}
		
		UpdateBinding(ControlGUID, bo){
			dev := bo.DeviceID, axis := bo.Binding[1]
			; Remove old binding
			for id, inputs in this.StickBindings {
				for bindstring, input_info in inputs {
					for cguid, unused in input_info.Subscriptions {
						if (cguid == ControlGuid){
							input_info.Subscriptions.Delete(cguid)
							;OutputDebug % "UCR| Removing Binding for ControlGUID " cguid
							break 3
						}
					}
				}
			}
			if (dev && axis){
				;~ str := this.axisNames[axis]
				str := axis
				if (!ObjHasKey(this.StickBindings, dev))
					this.StickBindings[dev] := {}
				if (!ObjHasKey(this.StickBindings[dev], str))
					this.StickBindings[dev, str] := {State: 0, Subscriptions: {}}
								
				this.StickBindings[dev, str, "Subscriptions", ControlGuid] := 1
				;OutputDebug % "UCR| SubCount: " this.StickBindings[dev, str, "Subscriptions", ControlGuid]
				this.TimerWanted := 1
			}
			this.ProcessTimerState()
		}
		
		SetDetectionState(state){
			OutputDebug % "UCR| XInput_Axis SetDetectionState = " state
			this.DetectionState := state
			this.ProcessTimerState()
		}
		
		ProcessTimerState(){
			fn := this.TimerFn
			if (this.TimerWanted && this.DetectionState && !this.TimerRunning){
				SetTimer, % fn, 10
				this.TimerRunning := 1
				OutputDebug % "UCR| XInput_Axis Started AxisWatcher"
			} else if ((!this.TimerWanted || !this.DetectionState) && this.TimerRunning){
				SetTimer, % fn, Off
				this.TimerRunning := 0
				OutputDebug % "UCR| XInput_Axis Stopped AxisWatcher"
			}
		}

		StickWatcher(){
			for dev, inputs in this.StickBindings {
				deviceState := XInput_GetState(dev-1)
				for axisIndex, input_info in inputs {
					;~ OutputDebug % "UCR| HERE - " axisIndex
					bindstring := this.axisNames[axisIndex]
					state := deviceState[bindstring]
					if (axisIndex == 5 || axisIndex == 6){
						; Triggers
						state := state / 2.55
					} else {
						state := (state + 32768) / 655.35
					}
					if (state != input_info.state){
						input_info.state := state
						;~ OutputDebug % "UCR| XInput Firing Axis " bindstring " Callback - " state
						for ControlGUID, unused in input_info.Subscriptions {
							fn := this.InputEvent.Bind(this, ControlGUID, state)
							SetTimer, % fn, -0
						}
					}
				}
			}
		}
		
		InputEvent(ControlGUID, state){
			this.Callback.Call(ControlGUID, state)
		}
	}
	
	; Listens for Joystick Button input using AHK's Hotkey command
	; Joystick button Hotkeys in AHK immediately fire the up event after the down event...
	; ... so up events are emulated up using AHK's GetKeyState() function
	class AHK_JoyBtn_Input {
		HeldButtons := {}
		TimerWanted := 0		; Whether or not we WANT to run the ButtonTimer (NOT if it is actually running!)
		TimerRunning := 0
		DetectionState := 0		; Whether or not we are allowed to have hotkeys or be running the timer
		
		__New(Callback){
			this.Callback := Callback
			this.TimerFn := this.ButtonWatcher.Bind(this)
			Suspend, On	; Start with detection off, even if we are passed bindings
		}
		
		UpdateBinding(ControlGUID, bo){
			this.RemoveBinding(ControlGUID)
			if (bo.Binding[1]){
				keyname := this.BuildHotkeyString(bo)
				fn := this.KeyEvent.Bind(this, ControlGUID, 1)
				if (GetKeyState(bo.DeviceID "JoyAxes")) 
					try {
						hotkey, % keyname, % fn, On
					}
				else
					OutputDebug % "UCR| Warning! AHK_JoyBtn_Input did not declare hotkey " keyname " because the stick is disconnected"
				;OutputDebug % "UCR| AHK_JoyBtn_Input Added hotkey " keyname " for ControlGUID " ControlGUID
				this._AHKBindings[ControlGUID] := {KeyName: keyname, HasNoRelease: 0}
			}
		}
		
		SetDetectionState(state){
			; Are we already in the requested state?
			if (A_IsSuspended == state){
				;OutputDebug % "UCR| Thread: AHK_JoyBtn_Input IOClass turning Hotkey detection " (state ? "On" : "Off")
				Suspend, % (state ? "Off" : "On")
			}
			this.DetectionState := state
			this.ProcessTimerState()
		}
		
		RemoveBinding(ControlGUID){
			keyname := this._AHKBindings[ControlGUID].KeyName
			if (keyname){
				;OutputDebug % "UCR| AHK_JoyBtn_Input Removing hotkey " keyname " for ControlGUID " ControlGUID
				try{
					hotkey, % keyname, UCR_INPUTHREAD_DUMMY_LABEL
				}
				try{
					hotkey, % keyname, Off
				}
				this._AHKBindings.Delete(ControlGUID)
			}
			;this._CurrentBinding := 0
		}
		
		KeyEvent(ControlGUID, e){
			; ToDo: Parent will not exist in thread!
			
			;OutputDebug % "UCR| AHK_JoyBtn_Input Key event " e " for GuiControl " ControlGUID
			;this.Callback.Call(ControlGUID, e)
			fn := this.InputEvent.Bind(this, ControlGUID, e)
			SetTimer, % fn, -0
			
			this.HeldButtons[this._AHKBindings[ControlGUID].KeyName] := ControlGUID
			if (!this.TimerWanted){
				this.TimerWanted := 1
				this.ProcessTimerState()
			}
		}
		
		InputEvent(ControlGUID, state){
			this.Callback.Call(ControlGUID, state)
		}

		ButtonWatcher(){
			for bindstring, ControlGUID in this.HeldButtons {
				if (!GetKeyState(bindstring)){
					this.HeldButtons.Delete(bindstring)
					;OutputDebug % "UCR| AHK_JoyBtn_Input Key event 0 for GuiControl " ControlGUID
					;this.Callback.Call(ControlGUID, 0)
					fn := this.InputEvent.Bind(this, ControlGUID, 0)
					SetTimer, % fn, -0
					if (IsEmptyAssoc(this.HeldButtons)){
						this.TimerWanted := 0
						this.ProcessTimerState()
						return
					}
				}
			}
		}
		
		ProcessTimerState(){
			fn := this.TimerFn
			if (this.TimerWanted && this.DetectionState && !this.TimerRunning){
				SetTimer, % fn, 10
				this.TimerRunning := 1
				;OutputDebug % "UCR| AHK_JoyBtn_Input Started ButtonWatcher " ControlGUID
			} else if ((!this.TimerWanted || !this.DetectionState) && this.TimerRunning){
				SetTimer, % fn, Off
				this.TimerRunning := 0
				;OutputDebug % "UCR| AHK_JoyBtn_Input Stopped ButtonWatcher " ControlGUID
			}
		}

		BuildHotkeyString(bo){
			return bo.Deviceid "Joy" bo.Binding[1]
		}
	}

	; Listens for Joystick Axis input using AHK's GetKeyState() function
	class AHK_JoyAxis_Input {
		StickBindings := {}
		/*
		StickBindings structure:
		{
			<Stick ID>: {
				<BindString (eg "2JoyX")>: {
					State: <current state>
					Subscriptions: {
						<guid>: 1,
						<guid>: 1,
					}
				}
			}
		}
		*/
		ConnectedSticks := [0,0,0,0,0,0,0,0]
		
		__New(Callback){
			this.Callback := Callback
			
			this.TimerFn := this.StickWatcher.Bind(this)
		}
		
		UpdateBinding(ControlGUID, bo){
			static AHKAxisList := ["X","Y","Z","R","U","V"]
			dev := bo.DeviceID, axis := bo.Binding[1]
			; Remove old binding
			for id, inputs in this.StickBindings {
				for bindstring, input_info in inputs {
					for cguid, unused in input_info.Subscriptions {
						if (cguid == ControlGuid){
							input_info.Subscriptions.Delete(cguid)
							;OutputDebug % "UCR| Removing Binding for ControlGUID " cguid
							break
						}
					}
				}
			}
			if (dev && axis){
				str := dev "joy" AHKAxisList[axis]
				if (!ObjHasKey(this.StickBindings, dev))
					this.StickBindings[dev] := {}
				if (!ObjHasKey(this.StickBindings[dev], str))
					this.StickBindings[dev, str] := {State: 0, Subscriptions: {}}
								
				this.StickBindings[dev, str, "Subscriptions", ControlGuid] := 1
				;OutputDebug % "UCR| SubCount: " this.StickBindings[dev, str, "Subscriptions", ControlGuid]
				this.TimerWanted := 1
			}
			this.ProcessTimerState()
		}
		
		SetDetectionState(state){
			;OutputDebug % "UCR| AHK_JoyAxis_Input SetDetectionState = " state
			this.DetectionState := state
			this.ProcessTimerState()
		}
		
		ProcessTimerState(){
			fn := this.TimerFn
			if (this.TimerWanted && this.DetectionState && !this.TimerRunning){
				; Pre-cache connected sticks, as polling disconnected sticks takes lots of CPU
				Loop 8 {
					this.ConnectedSticks[A_Index] := (GetKeyState(A_Index "JoyAxes") > 0)
				}
				SetTimer, % fn, 10
				this.TimerRunning := 1
				;OutputDebug % "UCR| AHK_JoyAxis_Input Started AxisWatcher"
			} else if ((!this.TimerWanted || !this.DetectionState) && this.TimerRunning){
				SetTimer, % fn, Off
				this.TimerRunning := 0
				;OutputDebug % "UCR| AHK_JoyAxis_Input Stopped AxisWatcher"
			}
		}

		StickWatcher(){
			for dev, inputs in this.StickBindings {
				if (!this.ConnectedSticks[dev]){
					; Do not poll unconnected sticks, it consumes a lot of cpu
					;OutputDebug % "UCR| JI" obj.dev " JoyInfo: " GetKeyState(obj.dev "JoyInfo")
					continue
				}
				for bindstring, input_info in inputs {
					state := GetKeyState(bindstring)
					if (state != input_info.state){
						input_info.state := state
						;OutputDebug % "UCR| Firing Axis Callback - " state
						for ControlGUID, unused in input_info.Subscriptions {
							fn := this.InputEvent.Bind(this, ControlGUID, state)
							SetTimer, % fn, -0
						}
					}
				}
			}
		}
		
		InputEvent(ControlGUID, state){
			this.Callback.Call(ControlGUID, state)
		}
	}

	; Listens for Joystick Hat input using AHK's GetKeyState() function
	class AHK_JoyHat_Input {
		; Indexed by GetKeyState string (eg "1JoyPOV")
		; The HatWatcher timer is active while this array has items.
		; Contains an array of objects whose keys are the GUIDs of GuiControls mapped to that POV
		; Properties of those keys are the direction of the mapping and the state of the binding
		HatBindings := {}
		
		; GUID-Indexed array of sticks + directions that each GUIControl is mapped to, plus it's current state
		ControlMappings := {}
		
		; Which cardinal directions are pressed for each of the 8 compass directions, plus centre
		; Order is U, R, D, L
		static PovMap := {-1: [0,0,0,0], 1: [1,0,0,0], 2: [1,1,0,0] , 3: [0,1,0,0], 4: [0,1,1,0], 5: [0,0,1,0], 6: [0,0,1,1], 7: [0,0,0,1], 8: [1,0,0,1]}
		
		TimerRunning := 0
		TimerWanted := 0
		ConnectedSticks := [0,0,0,0,0,0,0,0]
		
		__New(Callback){
			this.Callback := Callback
			
			this.TimerFn := this.HatWatcher.Bind(this)
		}
		
		; Request from main thread to update binding
		UpdateBinding(ControlGUID, bo){
			;OutputDebug % "UCR| AHK_JoyHat_Input " (bo.Binding[1] ? "Update" : "Remove" ) " Hat Binding - Device: " bo.DeviceID ", Direction: " bo.Binding[1]
			this._UpdateArrays(ControlGUID, bo)
			this.TimerWanted := !IsEmptyAssoc(this.ControlMappings)
			this.ProcessTimerState()
		}
		
		SetDetectionState(state){
			this.DetectionState := state
			this.ProcessTimerState()
		}
		
		ProcessTimerState(){
			fn := this.TimerFn
			if (this.TimerWanted && this.DetectionState && !this.TimerRunning){
				; Pre-cache connected sticks, as polling disconnected sticks takes lots of CPU
				Loop 8 {
					this.ConnectedSticks[A_Index] := GetKeyState(A_Index "JoyInfo")
				}
				SetTimer, % fn, 10
				this.TimerRunning := 1
				;OutputDebug % "UCR| AHK_JoyHat_Input Started HatWatcher"
			} else if ((!this.TimerWanted || !this.DetectionState) && this.TimerRunning){
				SetTimer, % fn, Off
				this.TimerRunning := 0
				;OutputDebug % "UCR| AHK_JoyHat_Input Stopped HatWatcher"
			}
		}

		; Updates the arrays which drive hat detection
		_UpdateArrays(ControlGUID, bo := 0){
			if (ObjHasKey(this.ControlMappings, ControlGUID)){
				; GuiControl already has binding
				bindstring := this.ControlMappings[ControlGUID].bindstring
				this.HatBindings[bindstring].Delete(ControlGUID)
				this.ControlMappings.Delete(ControlGUID)
				if (IsEmptyAssoc(this.HatBindings[bindstring])){
					this.HatBindings.Delete(bindstring)
					;OutputDebug % "UCR| AHK_JoyHat_Input Removing Hat Bindstring " bindstring
				}
			}
			if (bo != 0 && bo.Binding[1]){
				; there is a new binding
				bindstring := bo.DeviceID "JoyPOV"
				if (!ObjHasKey(this.HatBindings, bindstring)){
					this.HatBindings[bindstring] := {}
					;OutputDebug % "UCR| AHK_JoyHat_Input Adding Hat Bindstring " bindstring
				}
				this.HatBindings[bindstring, ControlGUID] := {dir: bo.Binding[1], state: 0}
				this.ControlMappings[ControlGUID] := {bindstring: bindstring}
			}
		}
		
		; Called on a timer when we are trying to detect hats
		HatWatcher(){
			for bindstring, bindings in this.HatBindings {
				if (!this.ConnectedSticks[SubStr(bindstring, 1, 1)]){
					; Do not poll unconnected sticks, it consumes a lot of cpu
					continue
				}
				state := GetKeyState(bindstring)
				state := (state = -1 ? -1 : round(state / 4500) + 1)
				for ControlGUID, obj in bindings {
					new_state := (this.PovMap[state, obj.dir] == 1)
					if (obj.state != new_state){
						obj.state := new_state
						;OutputDebug % "UCR| InputThread: AHK_JoyHat_Input Direction " obj.dir " state " new_state " calling ControlGUID " ControlGUID
						; Use the thread-safe object to tell the main thread that the hat direction changed state
						;this.Callback.Call(ControlGUID, new_state)
						fn := this.InputEvent.Bind(this, ControlGUID, new_state)
						SetTimer, % fn, -0
					}
				}
			}
		}
		
		InputEvent(ControlGUID, state){
			this.Callback.Call(ControlGUID, state)
		}
	}
	
	class RawInput_Mouse_Delta {
		_DeltaBindings := {}
		Registered := 0
		DetectionState := 0
		
		__New(Callback){
			this.Callback := Callback
			this.MouseMoveFn := this.OnMouseMove.Bind(this)
			Gui, +HwndHwnd		; Get a unique hwnd so we can register for messages
			this.hwnd := hwnd
		}
		
		; Is an associative array empty?
		IsEmptyAssoc(assoc){
			return !assoc._NewEnum()[k, v]
		}

		UpdateBinding(ControlGUID, bo){

			;OutputDebug % "UCR| InputDelta UpdateBinding for GUID " ControlGUID " binding: " bo.Binding[1]
			this.RemoveBinding(ControlGUID)
			
			if (bo.Binding[1]){
				this._DeltaBindings[ControlGUID] := bo.DeviceID
				
				if (!this.Registered){	
					this.RegisterMouse()
				}
			}
		}
		
		RemoveBinding(ControlGUID){
			this._DeltaBindings.Delete(ControlGUID)
			if (this.Registered && IsEmptyAssoc(this._DeltaBindings)){
				this.UnRegisterMouse()
			}
		}
		
		SetDetectionState(state){
			;OutputDebug % "UCR| InputDelta SetDetectionState " state
			this.DetectionState := state
			this._ProcessDetectionState()
		}
		
		_ProcessDetectionState(){
			if (this.DetectionState && !this.Registered && !IsEmptyAssoc(this._DeltaBindings)){
				this.RegisterMouse()
			} else if (!this.DetectionState && this.Registered){
				this.UnRegisterMouse()
			}
		}
		
		RegisterMouse(){
			
			static RIDEV_INPUTSINK := 0x00000100
			; Register mouse for WM_INPUT messages.
			static DevSize := 8 + A_PtrSize
			static RAWINPUTDEVICE := 0
				
			if (this.Registered)
				return
			;OutputDebug % "UCR| ProfileInputThread registering for mouse delta"
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
			this.Registered := 1
		}
		
		UnRegisterMouse(){
			static RIDEV_REMOVE := 0x00000001
			static DevSize := 8 + A_PtrSize

			if (!this.Registered)
				return
			;OutputDebug % "UCR| ProfileInputThread unregistering for mouse delta"
			;fn := this.MouseTimeoutFn
			;SetTimer, % fn, Off
			
			;RAWINPUTDEVICE := this.RAWINPUTDEVICE
			static RAWINPUTDEVICE := 0
			if (RAWINPUTDEVICE == 0){
				VarSetCapacity(RAWINPUTDEVICE, DevSize)
				NumPut(1, RAWINPUTDEVICE, 0, "UShort")
				NumPut(2, RAWINPUTDEVICE, 2, "UShort")
				NumPut(RIDEV_REMOVE, RAWINPUTDEVICE, 4, "Uint")
			}
			DllCall("RegisterRawInputDevices", "Ptr", &RAWINPUTDEVICE, "UInt", 1, "UInt", DevSize )
			OnMessage(0x00FF, this.MouseMoveFn, 0)
			this.Registered := 0
		}
		
		; Called when the mouse moved.
		; Messages tend to contain small (+/- 1) movements, and happen frequently (~20ms)
		OnMouseMove(wParam, lParam){
			; RawInput statics
			static DeviceSize := 2 * A_PtrSize, iSize := 0, sz := 0, offsets := {x: (20+A_PtrSize*2), y: (24+A_PtrSize*2)}, uRawInput
	 
			static axes := {x: 1, y: 2}
			VarSetCapacity(raw, 40, 0)
			If (!DllCall("GetRawInputData",uint,lParam,uint,0x10000003,uint,&raw,"uint*",40,uint, 16) or ErrorLevel)
				Return 0
			
			
			
			
			; Find size of rawinput data - only needs to be run the first time.
			if (!iSize){
				r := DllCall("GetRawInputData", "UInt", lParam, "UInt", 0x10000003, "Ptr", 0, "UInt*", iSize, "UInt", 8 + (A_PtrSize * 2))
				VarSetCapacity(uRawInput, iSize)
			}
			sz := iSize	; param gets overwritten with # of bytes output, so preserve iSize
			; Get RawInput data
			r := DllCall("GetRawInputData", "UInt", lParam, "UInt", 0x10000003, "Ptr", &uRawInput, "UInt*", sz, "UInt", 8 + (A_PtrSize * 2))
	        
			ThisMouse := NumGet(&uRawInput, 8)

			x := NumGet(&uRawInput, offsets.x, "Int")
			y := NumGet(&uRawInput, offsets.y, "Int")
			
			xy := {}
			if (x){
				xy.x := x
			}
			if (y){
				xy.y := y
			}
			if (!ObjHasKey(xy, "x") && !ObjHasKey(xy, "y"))
				return

			state := {axes: xy, MouseID: ThisMouse}
			for ControlGuid, DeviceID in this._DeltaBindings {
				if (DeviceID == -1 || DeviceID == ThisMouse){
					;Outputdebug % "UCR| ProfileInputThread Firing callback for MouseDelta ControlGUID " ControlGuid ", DeviceID: " ThisMouse
					this.Callback.Call(ControlGuid, state)
					; Using SetTimer -0 seems to utterly hammer performance, so don't do it for mouse delta
					;~ fn := this.InputEvent.Bind(this, ControlGUID, state)
					;~ SetTimer, % fn, -0
				}
			}
	 
			; There is no message for "Stopped", so simulate one
			;fn := this.MouseTimeoutFn
			;SetTimer, % fn, % -this.MouseTimeOutDuration
		}

		InputEvent(ControlGUID, state){
			this.Callback.Call(ControlGUID, state)
		}

		;OnMouseTimeout(){
		;	for hwnd, obj in this.MouseDeltaMappings {
		;		this.InputEvent(obj, {x: 0, y: 0})
		;	}
		;}
	}
}