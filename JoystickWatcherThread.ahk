#Persistent
#NoTrayIcon
JoystickWatcher := new _JoystickWatcher()
autoexecute_done := 1

class _JoystickWatcher {
	AHKAxisList := ["X","Y","Z","R","U","V"]
	PollTimerFn := 0
	RegisteredSticks := []
	RegisteredAxes := [{},{},{},{},{},{},{},{}]
	RegisteredHats := [{},{},{},{},{},{},{},{}]
	__New(){
		this.MasterThread := AhkExported()
		this.PollTimerFn := this.PollJoystick.Bind(this)
	}

	PollJoystick(){
		Loop % this.RegisteredSticks.length() {
			stick := this.RegisteredSticks[A_Index]
			axes := this.RegisteredAxes[stick]
			if (axes = {})
				continue
			for index, obj in axes {
				val := Round(GetKeyState(obj.string) * 327.67, 2)
				if (val != obj.state){
					; don't fire if just registered, just initialize
					if (obj.state != -1){
						this.MasterThread.ahkExec("UCR._InputHandler.AxisEvent(" obj.stick "," obj.axis "," val ")")
					}
					obj.state := val
				}
			}

		}
	}

	RegisterAxis(state, stick, axis){
		OutputDebug, % "Registering Axis"
		this.SetPollState(0)
		if (state){
			if (this.RegisterStick(state, stick)){
				this.RegisteredAxes[stick][axis] := {stick: stick, axis: axis, state: -1, string: stick "joy" this.AHKAxisList[axis]}
			}
		} else {
			this.RegisteredAxes[stick].RemoveAt(axis)
			; check if axis is last one on stick
			if (this.RegisteredAxes[stick] == {}){
				this.RegisterStick(0, stick)
			}
		}
		this.SetPollState(1)
	}
	
	RegisterStick(state, stick){
		if (state){
			Loop % this.RegisteredSticks.length(){
				if (this.RegisteredSticks[A_Index] = stick){
					return 1
				}
			}
			if (stick >= 1 && stick <= 8){
				this.RegisteredSticks.push(stick)
				return 1
			} else {
				return 0
			}
		} else {
			Loop % this.RegisteredSticks.length(){
				if (this.RegisteredSticks[A_Index] = stick){
					this.RegisteredSticks.RemoveAt(A_Index)
					break
				}
			}
			return 1
		}
	}
	
	SetPollState(state){
		if (state = this.PollState)
			return 1
		fn := this.PollTimerFn
		this.PollState := state
		t := state ? 10 : "Off"
		SetTimer, % fn, % t
		return 1
	}
}