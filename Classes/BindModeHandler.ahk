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
		;this._BindModeThread := new _BindMapper(this.ProcessInput.Bind(this))

		FileRead, Script, % A_ScriptDir "\Threads\BindModeThread.ahk"
		this.__BindModeThread := AhkThread(UCR._ThreadHeader "`nBindMapper := new _BindMapper(" ObjShare(this.ProcessInput.Bind(this)) ")`n" UCR._ThreadFooter Script)
		While !this.__BindModeThread.ahkgetvar.autoexecute_done
			Sleep 50 ; wait until variable has been set.
		
		; Create object to hold thread-safe boundfunc calls to the thread
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
		; IOClassMappings controls which type each IOClass reports as.
		; ie we need the AHK_KBM_Input class to report as AHK_KBM_Output when we are binding an output key
		this.IOClassMappings := IOClassMappings
		this.SetHotkeyState(1)
	}
	
	; Turns on or off the hotkeys
	SetHotkeyState(state){
		if (state){
			Gui, % this.hBindModePrompt ":Show"
			UCR.MoveWindowToCenterOfGui(this.hBindModePrompt)
		} else {
			Gui, % this.hBindModePrompt ":Hide"
		}
		; Convert associative array to indexed, as ObjShare breaks associative array enumeration
		IOClassMappings := this.AssocToIndexed(this.IOClassMappings)
		this._BindModeThread.SetDetectionState(state, ObjShare(IOClassMappings))
	}
	
	; Converts an associative array to an indexed array of objects
	; If you pass an associative array via ObjShare, you cannot enumerate it
	; So each base key/value pair is added to an indexed array
	; And the thread can re-build the associative array on the other end.
	AssocToIndexed(arr){
		ret := []
		for k, v in arr {
			ret.push({k: k, v: v})
		}
		return ret
	}
	
	; The BindModeThread calls back here
	ProcessInput(e, i, deviceid, IOClass){
		;OutputDebug % "UCR| BindModeHandler saw input: e " e ", i " i ", deviceid " deviceid ", IOClass " IOClass
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
