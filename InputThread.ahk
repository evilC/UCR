; ToDo: Split IOClasses out into individual files
; ToDo: Rename these type of IOClasses to IOInputClasses?

; Can use  #Include %A_LineFile%\..\other.ahk to include in same folder
Class _InputThread {
	DetectionState := 0
	IOClasses := {AHK_KBM_Input: 0, AHK_Joy_Buttons: 0, AHK_Joy_Hats: 0, AHK_Joy_Axes: 0}
	__New(ProfileID, CallbackPtr){
		this.Callback := ObjShare(CallbackPtr)
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
		;msgbox new
	}
	
	; A request was received from the main thread to update a binding.
	UpdateBinding(ControlGUID, j){
		OutputDebug % "UCR| _InputThread.UpdateBinding - cls: " j.IOClass
		; Direct the request to the appropriate IOClass that handles it
		this.IOClasses[j.IOClass].UpdateBinding(ControlGUID, j)
	}
	
	; A request was received from the main thread to set the Dection state
	SetDetectionState(state){
		if (state == this.DetectionState)
			return
		for name, cls in this.IOClasses {
			cls.SetDetectionState(state)
		}
		DetectionState := state
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
		
		UpdateBinding(ControlGUID, j){
			;msgbox Update binding
			;return
			this.RemoveBinding(ControlGUID)
			if (j.Binding[1]){
				keyname := "$" this.BuildHotkeyString(j)
				fn := this.KeyEvent.Bind(this, ControlGUID, 1)
				hotkey, % keyname, % fn, On
				fn := this.KeyEvent.Bind(this, ControlGUID, 0)
				hotkey, % keyname " up", % fn, On
				OutputDebug % "UCR| AHK_KBM_Input Added hotkey " keyname " for ControlGUID " ControlGUID
				this._AHKBindings[ControlGUID] := keyname
			}
		}
		
		SetDetectionState(state){
			str := state ? "Off" : "On"
			OutputDebug % "UCR| Thread: AHK_KBM_Input IOClass turning Suspend " str
			Suspend, % str
			this.DetectionState := state
		}
		
		RemoveBinding(ControlGUID){
			keyname := this._AHKBindings[ControlGUID]
			if (keyname){
				OutputDebug % "UCR| AHK_KBM_Input Removing hotkey " keyname " for ControlGUID " ControlGUID
				hotkey, % keyname, UCR_DUMMY_LABEL
				hotkey, % keyname, Off
				hotkey, % keyname " up", UCR_DUMMY_LABEL
				hotkey, % keyname " up", Off
				this._AHKBindings.Delete(ControlGUID)
			}
		}
		
		KeyEvent(ControlGUID, e){
			;OutputDebug % "UCR| AHK_KBM_Input Key event for GuiControl " ControlGUID
			;msgbox % "Hotkey pressed - " this.ParentControl.Parentplugin.id
			this.Callback.Call(ControlGUID, e)
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
	
	; Listens for Joystick Button input using AHK's Hotkey command
	; Joystick button Hotkeys in AHK immediately fire the up event after the down event...
	; ... so up events are emulated up using AHK's GetKeyState() function
	class AHK_Joy_Buttons {
		HeldButtons := {}
		ButtonTimerRunning := 0
		
		__New(Callback){
			this.Callback := Callback
			this.ButtonWatcherFn := this.ButtonWatcher.Bind(this)
		}
		
		UpdateBinding(ControlGUID, bo){
			;msgbox Update binding
			;return
			this.RemoveBinding(ControlGUID)
			if (bo.Binding[1]){
				keyname := this.BuildHotkeyString(bo)
				fn := this.KeyEvent.Bind(this, ControlGUID, 1)
				hotkey, % keyname, % fn, On
				;fn := this.KeyEvent.Bind(this, ControlGUID, 0)
				;hotkey, % keyname " up", % fn, On
				OutputDebug % "UCR| AHK_Joy_Buttons Added hotkey " keyname " for ControlGUID " ControlGUID
				;this._CurrentBinding := keyname
				this._AHKBindings[ControlGUID] := keyname
			}
		}
		
		SetDetectionState(state){
			
		}
		
		RemoveBinding(ControlGUID){
			keyname := this._AHKBindings[ControlGUID]
			if (keyname){
				OutputDebug % "UCR| AHK_Joy_Buttons Removing hotkey " keyname " for ControlGUID " ControlGUID
				try{
					hotkey, % keyname, UCR_DUMMY_LABEL
				}
				try{
					hotkey, % keyname, Off
				}
				try{
					hotkey, % keyname " up", UCR_DUMMY_LABEL
				}
				try{
					hotkey, % keyname " up", Off
				}
				this._AHKBindings.Delete(ControlGUID)
			}
			;this._CurrentBinding := 0
		}
		
		KeyEvent(ControlGUID, e){
			; ToDo: Parent will not exist in thread!
			
			;OutputDebug % "UCR| AHK_Joy_Buttons Key event " e " for GuiControl " ControlGUID
			this.Callback.Call(ControlGUID, e)
			
			this.HeldButtons[this._AHKBindings[ControlGUID]] := ControlGUID
			if (!this.ButtonTimerRunning){
				this.ButtonTimerRunning := 1
				fn := this.ButtonWatcherFn
				SetTimer, % fn, 10
				;OutputDebug % "UCR| AHK_Joy_Buttons Starting ButtonWatcher " ControlGUID
			}
		}
		
		ButtonWatcher(){
			for bindstring, ControlGUID in this.HeldButtons {
				if (!GetKeyState(bindstring)){
					this.HeldButtons.Delete(bindstring)
					;OutputDebug % "UCR| AHK_Joy_Buttons Key event 0 for GuiControl " ControlGUID
					this.Callback.Call(ControlGUID, 0)
					if (this.IsEmptyAssoc(this.HeldButtons)){
						this.ButtonTimerRunning := 0
						fn := this.ButtonWatcherFn
						SetTimer, % fn, Off
						;OutputDebug % "UCR| AHK_Joy_Buttons Stopping ButtonWatcher " ControlGUID
						return
					}
				}
			}
		}
		
		BuildHotkeyString(bo){
			return bo.Deviceid "Joy" bo.Binding[1]
		}
		
		; Is an associative array empty?
		IsEmptyAssoc(assoc){
			return !assoc._NewEnum()[k, v]
		}
	}

	; Listens for Joystick Axis input using AHK's GetKeyState() function
	class AHK_Joy_Axes {
		StickBindings := {}
		
		__New(Callback){
			this.Callback := Callback
			
			fn := this.StickWatcher.Bind(this)
			this.StickWatcherFn := fn
		}
		
		UpdateBinding(ControlGUID, bo){
			OutputDebug % "UCR| AHK_Joy_Axes " (bo.Binding[1] ? "Update" : "Remove" ) " Axis Binding - Device: " bo.DeviceID ", Axis: " bo.Binding[1]
		}
		
		SetDetectionState(state){
			
		}
		
		StickWatcher(){
			
		}
	}

	; Listens for Joystick Hat input using AHK's GetKeyState() function
	class AHK_Joy_Hats {
		; Indexed by GetKeyState string (eg "1JoyPOV")
		; The HatWatcher timer is active while this array has items.
		; Contains an array of objects whose keys are the GUIDs of GuiControls mapped to that POV
		; Properties of those keys are the direction of the mapping and the state of the binding
		HatBindings := {}
		
		; GUID-Indexed array of sticks + directions that each GUIControl is mapped to, plus it's current state
		ControlMappings := {}
		
		; Is the Hat Watcher timer running?
		HatTimerRunning := 0
		
		; Which cardinal directions are pressed for each of the 8 compass directions, plus centre
		; Order is U, R, D, L
		static PovMap := {-1: [0,0,0,0], 1: [1,0,0,0], 2: [1,1,0,0] , 3: [0,1,0,0], 4: [0,1,1,0], 5: [0,0,1,0], 6: [0,0,1,1], 7: [0,0,0,1], 8: [1,0,0,1]}
		
		__New(Callback){
			this.Callback := Callback
			
			this.HatWatcherFn := this.HatWatcher.Bind(this)
		}
		
		; Request from main thread to update binding
		UpdateBinding(ControlGUID, bo){
			OutputDebug % "UCR| AHK_Joy_Hats " (bo.Binding[1] ? "Update" : "Remove" ) " Hat Binding - Device: " bo.DeviceID ", Direction: " bo.Binding[1]
			this._UpdateArrays(ControlGUID, bo)
			t := this.HatTimerRunning, k := ObjHasKey(this.ControlMappings, ControlGUID)
			fn := this.HatWatcherFn
			if (t && !k){
				OutputDebug % "UCR| AHK_Joy_Hats Stopping Hat Watcher" ;*[UCR]
				SetTimer, % fn, Off
				this.HatTimerRunning := 0
			} else if (!t && k){
				OutputDebug % "UCR| AHK_Joy_Hats Starting Hat Watcher"
				this.HatTimerRunning := 1
				SetTimer, % fn, 10
			}
		}
		
		SetDetectionState(state){
			
		}
		
		; Updates the arrays which drive hat detection
		_UpdateArrays(ControlGUID, bo := 0){
			if (ObjHasKey(this.ControlMappings, ControlGUID)){
				; GuiControl already has binding
				bindstring := this.ControlMappings[ControlGUID].bindstring
				this.HatBindings[bindstring].Delete(ControlGUID)
				this.ControlMappings.Delete(ControlGUID)
				if (this.IsEmptyAssoc(this.HatBindings[bindstring])){
					this.HatBindings.Delete(bindstring)
					;OutputDebug % "UCR| AHK_Joy_Hats Removing Hat Bindstring " bindstring
				}
			}
			if (bo != 0 && bo.Binding[1]){
				; there is a new binding
				bindstring := bo.DeviceID "JoyPOV"
				if (!ObjHasKey(this.HatBindings, bindstring)){
					this.HatBindings[bindstring] := {}
					;OutputDebug % "UCR| AHK_Joy_Hats Adding Hat Bindstring " bindstring
				}
				this.HatBindings[bindstring, ControlGUID] := {dir: bo.Binding[1], state: 0}
				this.ControlMappings[ControlGUID] := {bindstring: bindstring}
			}
		}
		
		; Called on a timer when we are trying to detect hats
		HatWatcher(){
			for bindstring, bindings in this.HatBindings {
				state := GetKeyState(bindstring)
				state := (state = -1 ? -1 : round(state / 4500) + 1)
				for ControlGUID, obj in bindings {
					new_state := (this.PovMap[state, obj.dir] == 1)
					if (obj.state != new_state){
						obj.state := new_state
						OutputDebug % "UCR| AHK_Joy_Hats Direction " obj.dir " state " new_state " calling ControlGUID " ControlGUID
						; Use the thread-safe object to tell the main thread that the hat direction changed state
						this.Callback.Call(ControlGUID, new_state)
					}
				}
			}
		}
		
		; Is an associative array empty?
		IsEmptyAssoc(assoc){
			return !assoc._NewEnum()[k, v]
			;for k, v in assoc {
			;	return 0
			;}
			;return 1
		}
	}
}