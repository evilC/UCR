; =================================================================== BIND MODE HANDLER ==========================================================
; Prompts the user for input and detects their choice of binding
class _BindModeHandler {
	DebugMode := 2
	SelectedBinding := 0
	BindMode := 0
	EndKey := 0
	HeldModifiers := {}
	ModifierCount := 0
	_Callback := 0
	
	__New(){
		;this._BindModeThread:=AhkThread(A_ScriptDir "\Threads\BindModeThread.ahk",,1) ; Loads the AutoHotkey module and starts the script.
		;While !this._BindModeThread.ahkgetvar.autoexecute_done
		;	Sleep 50 ; wait until variable has been set.
		;this._BindModeThread.ahkExec["BindMapper := new _BindMapper(" ObjShare(this.ProcessInput.Bind(this)) ")"]
		;this._BindModeThread := new _BindMapper(this.ProcessInput.Bind(this))

		this.__BindModeThread:=AhkThread(A_ScriptDir "\Threads\BindModeThread.ahk",,1) ; Loads the AutoHotkey module and starts the script.
		While !this.__BindModeThread.ahkgetvar.autoexecute_done
			Sleep 50 ; wait until variable has been set.
		this.__BindModeThread.ahkExec["BindMapper := new _BindMapper(" ObjShare(this.ProcessInput.Bind(this)) ")"]
		
		this._BindModeThread := {}
		this._BindModeThread.SetDetectionState := ObjShare(this.__BindModeThread.ahkgetvar("InterfaceSetDetectionState"))

		Gui, new, +HwndHwnd
		Gui +ToolWindow -Border
		Gui, Font, S15
		Gui, Color, Red
		this.hBindModePrompt := hwnd
		Gui, Add, Text, Center, Press the button(s) you wish to bind to this control.`n`nBind Mode will end when you release a key.
	}
	
	;IOClassMappings, this._BindModeEnded.Bind(this, callback)
	StartBindMode(IOClassMappings, callback){
		this._callback := callback
		
		this.SelectedBinding := {Binding: [], DeviceID: 0, IOClass: 0}
		this.BindMode := 1
		this.EndKey := 0
		this.HeldModifiers := {}
		this.ModifierCount := 0
		this.IOClassMappings := IOClassMappings
		
		; When detecting an output, tell the Bind Handler to ignore physical joysticks...
		; ... as output cannot be "sent" to physical sticks
		;this.SetHotkeyState(1, !hk._IsOutput)
		this.SetHotkeyState(1, 1)
	}
	
	; Turns on or off the hotkeys
	SetHotkeyState(state, enablejoystick := 1){
		if (state){
			Gui, % this.hBindModePrompt ":Show"
			UCR.MoveWindowToCenterOfGui(this.hBindModePrompt)
		} else {
			Gui, % this.hBindModePrompt ":Hide"
		}
		;this._BindModeThread.ahkExec["BindMapper.SetHotkeyState(" state "," enablejoystick ")"]
		;this._BindModeThread.SetHotkeyState(state, enablejoystick)
		this._BindModeThread.SetDetectionState(state, ObjShare(this.IOClassMappings))
	}
	
	; The BindModeThread calls back here
	ProcessInput(e, i, deviceid, IOClass){
		;ToolTip % "e " e ", i " i ", deviceid " deviceid ", IOClass " IOClass
		;if (ObjHasKey(this._Modifiers, i))
		if (this.SelectedBinding.IOClass && (this.SelectedBinding.IOClass != IOClass)){
			; Changed binding IOCLass part way through.
			if (e){
				SoundBeep, 500, 100
			}
			return
		}
		max := this.SelectedBinding.Binding.length()
		if (e){
			for idx, code in  this.SelectedBinding.Binding {
				if (i == code)
					return	; filter repeats
			}
			this.SelectedBinding.Binding.push(i)
			this.SelectedBinding.DeviceID := DeviceID
			if (this.AHK_KBM_Input.IsModifier(i)){
				if (max > this.ModifierCount){
					; Modifier pressed after end key
					SoundBeep, 500, 100
					return
				}
				this.ModifierCount++
			} else if (max > this.ModifierCount) {
				; Second End Key pressed after first held
				SoundBeep, 500, 100
				return
			}
			this.SelectedBinding.IOClass := IOClass
		} else {
			this.BindMode := 0
			this.SetHotkeyState(0, this.IOClassMappings)
			;ret := {Binding:[i], DeviceID: deviceid, IOClass: this.IOClassMappings[IOClass]}
			
			OutputDebug % "UCR| BindModeHandler: Bind Mode Ended. Binding[1]: " this.SelectedBinding.Binding[1] ", DeviceID: " this.SelectedBinding.DeviceID ", IOClass: " this.SelectedBinding.IOClass
			; Convert IOClass from input type to output type, if needed.
			; This should be done inside the BindModeThread, but I am currently unable to pass in the IOClassMappings object
			old_class := this.SelectedBinding.IOClass
			if (ObjHasKey(this.IOClassMappings, old_class)){
				this.SelectedBinding.IOClass := this.IOClassMappings[old_class]
			}
			this._Callback.Call(this.SelectedBinding)
		}
	}
	
	; Implements IsModifier to tell the BindMode Handler that this IOClass can be a modifier
	class AHK_KBM_Input {
		static _Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
			,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
			,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
			,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})
		
		IsModifier(code){
			return ObjHasKey(this._Modifiers, code)
		}
	}
}
