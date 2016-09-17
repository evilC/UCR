; =================================================================== INPUT HANDLER ==========================================================
; Manages input (ie keyboard, mouse, joystick) during "normal" operation (ie when not in Bind Mode)
; Holds the "master list" of bound inputs and decides whether or not to allow bindings.
; All actual detection of input is handled in separate threads.
; Each profile has it's own thread of bindings which this class can turn on/off or add/remove bindings.
Class _InputHandler {
	RegisteredBindings := {}
	__New(){
		
	}
	
	; Set a Button Binding
	SetButtonBinding(BtnObj, delete := 0){
		; ToDo: Move building of bindstring inside thread? BuildHotkeyString is AHK input-specific, what about XINPUT?
		if (delete)
			bindstring := ""
		else
			bindstring := this.BuildHotkeyString(BtnObj.value)
		; Set binding in Profile's InputThread
		;BtnObj.ParentPlugin.ParentProfile._SetButtonBinding(ObjShare(BtnObj), bindstring )
		BtnObj.ParentPlugin.ParentProfile._InputThread.UpdateBindings()
		return 1
	}
	
	; Set an Axis Binding
	SetAxisBinding(AxisObj, delete := 0){
		;AxisObj.ParentPlugin.ParentProfile._SetAxisBinding(ObjShare(AxisObj), delete)
	}
	
	SetDeltaBinding(DeltaObj, delete := 0){
		;DeltaObj.ParentPlugin.ParentProfile._SetDeltaBinding(ObjShare(DeltaObj), delete)
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
	
	; An input event (eg key, mouse, joystick) occured for a bound input
	; This will have come from another thread
	; ipt will be an object of class _InputButton or _InputAxis
	; event will be 0 or 1 for a Button type, or the value of the axis for an axis type
	InputEvent(ipt, state){
		ipt := Object(ipt)	; Resolve input object back from pointer
		if (ipt.__value.Suppress && state && ipt.State > 0){
			; Suppress repeats option
			return
		}
		ipt.State := state
		if (IsObject(ipt.ChangeStateCallback)){
			ipt.ChangeStateCallback.Call(state)
		}
		; Notify UCR that there was activity.
		UCR._InputEvent(ipt, state)
	}
	
	_DelayCallback(cb, state){
		cb.Call(state)
	}
	
}
