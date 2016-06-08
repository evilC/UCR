/*
OneSwitch pulse (J2K version) for UCR
*/

; All plugins must derive from the _Plugin class
class OneSwitchPulse extends _Plugin {
	Type := "OneSwitch Pulse"
	Description := "OneSwitch Pulse for UCR. Designed to be used with JoyToKey. Add to Global profile."
	; The Init() method of a plugin is called when one is added. Use it to create your Gui etc
	Init(){
		; Create the GUI
		Gui, % this.hwnd ":Add", GroupBox, xm ym w310 h75, Inputs
		Gui, % this.hwnd ":Add", Text, xm+5 yp+20, % "Toggle On/Off"
		this.AddInputButton("Toggle", 0, this.Toggle.Bind(this), "x100 yp-2 w200")
		
		Gui, % this.hwnd ":Add", Text, xm+5 y+10, % "Choice"
		this.AddInputButton("Choice1", 0, this.ChoiceChangedState.Bind(this), "x100 yp-2 w200")
		
		Gui, % this.hwnd ":Add", GroupBox, x+30 ym w310 h75, Outputs
		
		Gui, % this.hwnd ":Add", Text, xp+5 yp+20 Section, % "Pulse Button"
		this.AddOutputButton("PulseButton", 0, "xs+100 yp-2 w200")
		
		Gui, % this.hwnd ":Add", Text, xs y+10, % "Timeout Button"
		this.AddOutputButton("TimeoutButton", 0, "xs+100 yp-2 w200")
		
		Gui, % this.hwnd ":Add", GroupBox, xm yp+40 w440 h100 Section, Timer Settings (All in MilliSeconds)
		
		Gui, % this.hwnd ":Add", Text, xm+5 yp+20, % "Pulse Rate (How often to hit the Pulse Button)"
		this.AddControl("PulseRate", 0, "Edit", "x400 yp-2 w40", 500)
		
		Gui, % this.hwnd ":Add", Text, xm+5 y+10, % "Choice Delay (After input activity, how long to wait before pulsing again)"
		this.AddControl("SuspendTime", 0, "Edit", "x400 yp-2 w40", 2000)
		
		Gui, % this.hwnd ":Add", Text, xm+5 y+10, % "Timeout (If no input activity for this time, hit Timeout Button)"
		this.AddControl("TimeOut", 0, "Edit", "x400 yp-2 w40", 5000)

		Gui, % this.hwnd ":Add", Text, x+10 ys+10 Center w200 h100 hwndhStatus
		Gui, % this.hwnd ":Font"
		this.hStatus := hStatus

		this.Enabled := 0	; Whether the state is toggled on or off
		this.ShowStatus()
		
		this.PulseFn := this.Pulse.Bind(this)
		this.TimeoutFn := this.Timeout.Bind(this)
		this.ResumePulseFn := this.SetTimerState.Bind(this, 1)
	}
	
	; The user pressed the Toggle on / off hotkey
	Toggle(e){
		if (e){
			this.Enabled := !this.Enabled
			this.ShowStatus()
			OutputDebug % "Setting State - " this.Enabled
			this.SetSubscriptionState(this.Enabled)
			this.SetTimerState(this.Enabled)
		}
	}
	
	ShowStatus(){
		GuiControl, , % this.hStatus, % (this.Enabled ? "ON" : "OFF")
		Gui, % this.hwnd ":Font", % (this.Enabled ? "cGreen" : "cRed") " s60"
		GuiControl, Font, % this.hStatus
		Gui, % this.hwnd ":Font"
	}
	
	; One of the Input Button / Axis bindings in UCR changed state
	; even ones in other profiles / plugins
	InputActivity(ipt, state){
		if (ipt == this.InputButtons.Toggle)
			return	; ignore input from the Toggle Button
		if (ipt.value.type == 4){
			OutputDebug % "InputActivity (Axis)"
			;this.DelayTimers()
			this.ScheduleTimers()
		} else {
			; Button type input - stop timers while button is down, call DelayTimers() on up
			OutputDebug % "InputActivity (Button) - state: " state
			if (state){
				this.SetTimerState(0)
			} else {
				this.ScheduleTimers()
			}
		}
	}

	; Schedules the timers to restart after the amount of time specified by the SuspendTime GuiControl
	ScheduleTimers(){
		fn := this.ResumePulseFn
		SetTimer, % fn, % "-" this.GuiControls.SuspendTime.value
	}
	
	; Send a pulse to J2K
	Pulse(){
		OutputDebug % "Pulse " round(A_TickCount / 1000, 2)
		this.OutputButtons.PulseButton.SetState(1)
		Sleep 50
		this.OutputButtons.PulseButton.SetState(0)
	}
	
	; Send a timeout to J2K
	Timeout(){
		OutputDebug % "Timeout " round(A_TickCount / 1000, 2)
		this.SetTimerState(0)
		this.OutputButtons.TimeoutButton.SetState(1)
		Sleep 50
		this.OutputButtons.TimeoutButton.SetState(0)
		this.SetTimerState(1)
	}
	
	; Called when the Choice button changes state (key is pressed or released)
	; Does nothing, the choice button is handled by InputActivity() like all other input
	ChoiceChangedState(e){
		;~ OutputDebug, % "Choice changed state to: " (e ? "Down" : "Up")
		;~ this.DelayTimers()
	}

	; Called when plugin (ie profile) becomes active
	OnActive(){
		if (this.Enabled){
			this.SetSubscriptionState(1)
			this.SetTimerState(1)
		}
	}
	
	OnInActive(){
		if (this.Enabled){
			this.SetTimerState(0)
			this.SetSubscriptionState(0)
		}
	}
	
	; Turns on or off the listening of input activity
	SetSubscriptionState(state){
		if (state){
			UCR.SubscribeToInputActivity(this.hwnd, this.InputActivity.Bind(this))
		} else {
			UCR.UnSubscribeToInputActivity(this.hwnd)
		}
	}
	
	; Turns on or off the timers
	SetTimerState(state){
		OutputDebug % "Changing Timer state to: " state
		pfn := this.PulseFn
		tfn := this.TimeoutFn
		rfn := this.ResumePulseFn
		if (state && this.Enabled){
			SetTimer, % pfn, % this.GuiControls.PulseRate.Value
			SetTimer, % tfn, % "-" this.GuiControls.TimeOut.Value
		} else if (!state){
			SetTimer, % pfn, Off
			SetTimer, % tfn, Off
			SetTimer, % rfn, Off
		}
	}
}
