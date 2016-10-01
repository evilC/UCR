; =================================================================== INPUT HANDLER ==========================================================
; Manages input (ie keyboard, mouse, joystick) during "normal" operation (ie when not in Bind Mode)
; Holds the "master list" of bound inputs and decides whether or not to allow bindings.
; All actual detection of input is handled in separate threads.
; Each profile has it's own thread of bindings which this class can turn on/off or add/remove bindings.
Class _InputHandler {
	RegisteredBindings := {}
	__New(){
		
	}
	
	; Check InputButtons for duplicates etc
	IsBindable(hk, bo){
		; Do not allow bind of LMB with block enabled
		if (bo.Block && bo.Buttons.length() = 1 && bo.Buttons[1].Type = 1 && bo.Buttons[1].code == 1){
			; ToDo: provide proper notification
			SoundBeep
			return 0
		}
		; ToDo: Implement duplicate check
		return 1
	}
	
	; Turns on or off Hotkey(s)
	ChangeHotkeyState(state, hk := 0){
		;hk.ParentPlugin.ParentProfile._SetHotkeyState(state)
	}
	
	; Builds an AHK hotkey string (eg ~^a) from a BindObject
	BuildHotkeyString(bo){
		if (!bo.Buttons.Length())
			return ""
		str := ""
		if (bo.Type = 1){
			if (bo.Wild)
				str .= "*"
			if (!bo.Block)
				str .= "~"
		}
		max := bo.Buttons.Length()
		Loop % max {
			key := bo.Buttons[A_Index]
			if (A_Index = max){
				islast := 1
				nextkey := 0
			} else {
				islast := 0
				nextkey := bo.Buttons[A_Index+1]
			}
			if (key.IsModifier() && (max > A_Index)){
				str .= key.RenderModifier()
			} else {
				str .= key.BuildKeyName()
			}
		}
		return str
	}
	
	InputEvent(ControlGUID, e){
		if (ObjHasKey(UCR.BindControlLookup, ControlGUID)){
			;OutputDebug % "UCR| InputHandler Received event " e " from GuiControl " ControlGUID
			lu := UCR.BindControlLookup[ControlGUID]
			;UCR.BindControlLookup[ControlGUID].ChangeStateCallback.Call(e)
			UCR.BindControlLookup[ControlGUID].OnStateChange(e)
			UCR._InputEvent(ControlGUID, e)
		} else {
			OutputDebug % "UCR| Guid not found in UCR.BindControlLookup"
		}

	}
	
	_DelayCallback(cb, state){
		cb.Call(state)
	}
	
}
