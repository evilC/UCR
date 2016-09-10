#SingleInstance force

global UCR
new UCR()

; Set up the test mappings system that feeds the GuiControls with sample mappings to simulate Bind Mode
; A sample keyboard mapping as it would come from the INI file
KeyMapping := {"Block": 0,"Buttons": [{"Code": 123,"DeviceID": 0,"IsVirtual": 0,"Type": 1,"UID": ""}],"Suppress": 0,"Type": 1,"Wild": 0}
; A sample input joystick mapping as it would come from the INI file
InputJoyBtnMapping := {"Block": 0, "Buttons": [{"Code": "1","DeviceID": 2,"IsVirtual": 0,"Type": 2,"UID": ""}],"Suppress": 0,"Type": 2,"Wild": 0}
UCR.AddTestMappings({TestIB: [KeyMapping, InputJoyBtnMapping], TestOB: [KeyMapping]})

; Add a Mock Plugin
UCR.plug := new MockPlugin()

; Show the Mock GUI
Gui, Show, x0 y0, Bind Control Sandbox
return

GuiClose:
	ExitApp

; Mock Plugin that adds mock GuiControls
Class MockPlugin extends _UCRBase {
	__New(){
		Gui, +HwndhMain
		this.hwnd := hMain
		ib := new _InputButton(this, "TestIB", 0, 0, "w300")
		
		ob := new _OutputButton(this, "TestOB", 0, "w300")
		
		ia := new _InputAxis(this, "TestIA", 0, 0, "w300")
	}
}

; Mock UCR - handles binding requests etc
#include MockUCR.ahk

; The new menu system
#include Menu.ahk

; Normal UCR classes that are needed
#include ..\Classes\GuiControls\BindObject.ahk
#include ..\Classes\Button.ahk
#include ..\Classes\Axis.ahk

; Classes that are being worked on
;#include ..\Classes\GuiControls\BannerCombo.ahk
;#include ..\Classes\GuiControls\InputButton.ahk
;#include ..\Classes\GuiControls\OutputButton.ahk
;#include ..\Classes\GuiControls\InputAxis.ahk


; ======================================================================== BANNER COMBO ===============================================================
; Wraps a ComboBox GuiControl to turn it into a DDL with a "Cue Banner" 1st item, that is re-selected after every choice.
class _BannerCombo extends _Menu {
	__New(ParentHwnd, aParams*){
		this._ParentHwnd := ParentHwnd
		this._Ptr := &this
		
		base.__New()
		Gui, Add, Button, % "hwndhReadout " aParams[1]
		this.hReadout := hReadout
		fn := this.OpenMenu.Bind(this)
		GuiControl, +g, % this.hReadout, % fn

		this.hwnd := hReadout	; all classes that represent Gui objects should have a unique hwnd property
	}
	
	; Shows the menu
	OpenMenu(){
		ControlGetPos, cX, cY, cW, cH,, % "ahk_id " this.hReadout
		Menu, % this.id, Show, % cX+1, % cY + cH
	}
	
	; Sets the text of the Cue Banner
	SetCueBanner(text){
		GuiControl,, % this.hReadout, % text
	}
	
	; Override
	_ChangedValue(o){
		
	}
	
	; All Input controls should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		; do nothing
	}
}


; ======================================================================== INPUT BUTTON ===============================================================
; A class the script author can instantiate to allow the user to select a hotkey.
class _InputButton extends _BannerCombo {
	; Public vars
	State := -1			; State of the input. -1 is unset. GET ONLY
	; Internal vars describing the bindstring
	__value := ""		; Holds the BindObject class
	; Other internal vars
	_IsOutput := 0
	_DefaultBanner := "Click to select an Input Button"
	_OptionMap := {Select: 1, Wild: 2, Block: 3, Suppress: 4, Clear: 5}
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ID := UCR.CreateGUID()
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
		this.__value := new _BindObject()

		this._BuildMenu()
		
		this.SetComboState()
	}
	
	__Delete(){
		OutputDebug % "UCR| Hotkey " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		this.ChangeValueCallback := ""
		this.ChangeStateCallback := ""
	}
	
	value[]{
		get {
			return this.__value
		}
		
		set {
			this._value := value	; trigger _value setter to set value and cuebanner etc
			OutputDebug % "UCR| Hotkey " this.Name " called ParentPlugin._ControlChanged()"
			this.ParentPlugin._ControlChanged(this)
		}
	}
	
	_value[]{
		get {
			return this.__value
		}
		
		; Parent class told this hotkey what it's value is. Set value, but do not fire ParentPlugin._ControlChanged
		set {
			this.__value := value
			this.SetComboState()
		}
	}

	_BuildMenu(){
		this.AddMenuItem("Select Binding", this._ChangedValue.Bind(this, 1))
		wild := this.AddMenuItem("Wild", this._ChangedValue.Bind(this, 2))
		block := this.AddMenuItem("Block", this._ChangedValue.Bind(this, 3))
		suppress := this.AddMenuItem("Suppress Repeats", this._ChangedValue.Bind(this, 4))
		this._KeyOnlyOptions := {wild: wild, block: block, suppress: suppress}
		this.AddMenuItem("Clear", this._ChangedValue.Bind(this, 5))
	}
	
	; Builds the list of options in the DropDownList
	_BuildOptions(){
		ko := (this.__value.Type == 1 && this.__value.Buttons.length())
		for n, opt in this._KeyOnlyOptions {
			opt.SetEnableState(ko)
			opt.SetCheckState(this.__value[n])
		}
	}

	; Set the state of the GuiControl (Inc Cue Banner)
	SetComboState(){
		this._BuildOptions()
		if ( this.__value.Buttons.length()) {
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner			
		}
		this.SetCueBanner(Text)
	}
	
	; An option was selected from the list
	_ChangedValue(o){
		if (o){
			;o := this._CurrentOptionMap[o]
			
			; Option selected from list
			if (o = 1){
				; Bind
				UCR._RequestBinding(this)
				return
			} else if (o = 2){
				; Wild
				mod := {wild: !this.__value.wild}
			} else if (o = 3){
				; Block
				mod := {block: !this.__value.block}
			} else if (o = 4){
				; Suppress
				mod := {suppress: !this.__value.suppress}
			} else if (o = 5){
				; Clear Binding
				mod := {Buttons: []}
			} else {
				; not one of the options from the list, user must have typed in box
				return
			}
			if (IsObject(mod)){
				UCR._RequestBinding(this, mod)
				return
			}
		}
	}
	
	; All Input controls should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		UCR._InputHandler.SetButtonBinding(this)
	}
	
	_Serialize(){
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Trigger _value setter to set gui state but not fire change event
		this._value := new _BindObject(obj)
		; Register hotkey on load
		;UCR._InputHandler.SetButtonBinding(this)
	}
}

; ======================================================================== OUTPUT BUTTON ===============================================================
; An Output allows the end user to specify which buttons to press as part of a plugin's functionality
Class _OutputButton extends _InputButton {
	State := 0
	_DefaultBanner := "Click to select an Output Button"
	_IsOutput := 1
	;_OptionMap := {Select: 1, vJoyButton: 2, Clear: 3}
	JoyMenus := []
	
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
		; Create Select vJoy Button / Hat Select GUI
	}
	
	_BuildMenu(){
		static HatDirections := ["Up", "Right", "Down", "Left"]
		static XBoxButtons := ["A", "B", "X", "Y", "LB", "RB", "LS", "RS", "Back", "Start", "Guide"]
		this.AddMenuItem("Select Keyboard / Mouse Binding", this._ChangedValue.Bind(this, 1))
		menu := this.AddSubMenu("vJoy Stick", "vJoy Stick")
		Loop 8 {
			menu.AddMenuItem(A_Index, this._ChangedValue.Bind(this, 100 + A_Index))
		}
		chunksize := 16
		Loop % round(128 / chunksize) {
			offset := (A_Index-1) * chunksize
			menu := this.AddSubMenu("vJoy Buttons " offset + 1 "-" offset + chunksize, "vJoyBtns" A_Index)
			this.JoyMenus.Push(menu)
			Loop % chunksize {
				btn := A_Index + offset
					menu.AddMenuItem(btn, this._ChangedValue.Bind(this, 1000 + btn))	; Set the callback when selected
			}
		}

		Loop 4 {
			menu := this.AddSubMenu("vJoy Hat " A_Index, "vJoyHat" A_Index)
			offset := (1 + A_Index) * 1000
			this.JoyMenus.Push(menu)
			Loop 4 {
				menu.AddMenuItem(HatDirections[A_Index], this._ChangedValue.Bind(this, offset + A_Index))	; Set the callback when selected
			}
		}
		
		/*
		menu := this.AddSubMenu("vXBox Pad", "vXBoxPad")
		Loop 4 {
			menu.AddMenuItem(A_Index, this._ChangedValue.Bind(this, 200 + A_Index))
		}

		menu := this.AddSubMenu("vXBox Buttons", "vXBoxBtns")
		this.JoyMenus.Push(menu)
		Loop 11 {
			menu.AddMenuItem(XBoxButtons[A_Index] " (" A_Index ")", this._ChangedValue.Bind(this, 6000 + A_Index))
		}
		*/

		this.AddMenuItem("Clear", this._ChangedValue.Bind(this, 2))
	}
	
	; Builds the list of options in the DropDownList
	_BuildOptions(){
		joy := (this.__value.Type >= 2 && this.__value.Type <= 6)
		for n, opt in this.JoyMenus {
			opt.SetEnableState(joy)
		}
	}
	
	; Used by script authors to set the state of this output
	SetState(state, delay_done := 0){
		static PovMap := {0: {x:0, y:0}, 1: {x: 0, y: 1}, 2: {x: 1, y: 0}, 3: {x: 0, y: 2}, 4: {x: 2, y: 0}}
		static PovAngles := {0: {0:-1, 1:0, 2:18000}, 1:{0:9000, 1:4500, 2:13500}, 2:{0:27000, 1:31500, 2:22500}}
		static Axes := ["x", "y"]
		if (UCR._CurrentState == 2 && !delay_done){
			fn := this.SetState.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.State := state
			max := this.__value.Buttons.Length()
			if (state)
				i := 1
			else
				i := max
			Loop % max{
				key := this.__value.Buttons[i]
				if (key.Type = 2 && key.IsVirtual){
					; Virtual Joystick Button
					UCR.Libraries.vJoy.Devices[key.DeviceID].SetBtn(state, key.code)
				} else if (key.Type >= 3 && key.IsVirtual){
					; Virtual Joystick POV Hat
					device := UCR.Libraries.vJoy.Devices[key.DeviceID]
					if (!IsObject(device.PovState))
						device.PovState := {x: 0, y: 0}
					if (state)
						new_state := PovMap[key.code].clone()
					else
						new_state := PovMap[0].clone()
					
					this_angle := PovMap[key.code]
					Loop 2 {
						ax := Axes[A_Index]
						if (this_angle[ax]){
							if (device.PovState[ax] && device.PovState[ax] != new_state[ax])
								new_state[ax] := 0
						} else {
							; this key does not control this axis, look at device.PovState for value
							new_state[ax] := device.PovState[ax]
						}
					}
					device.SetContPov(PovAngles[new_state.x,new_state.y], key.Type - 2)
					device.PovState := new_state
				} else {
					; Keyboard / Mouse
					name := key.BuildKeyName()
					Send % "{" name (state ? " Down" : " Up") "}"
				}
				if (state)
					i++
				else
					i--
			}
		}
	}
	
	; An option was selected from the list
	_ChangedValue(o){
		if (o){
			;o := this._CurrentOptionMap[o]
			
			; Option selected from list
			if (o = 1){
				; Bind
				UCR._RequestBinding(this)
				return
			} else if (o = 2){
				; Clear Binding
				mod := {Buttons: [], type: 0}
			} else if (o > 100 && o < 109) {
				; Stick ID
				o -= 100
				reopen := 0
				if (this.__value.type >= 2 && this.__value.type <= 6){
					; stick already selected
					bo := this.__value.clone()
				} else {
					reopen := 1
					bo := new _BindObject()
					bo.Type := 2
					btn := new _Button()
					btn.Type := 2
					btn.IsVirtual := 1
					bo.Buttons.push(btn)
				}
				
				bo.Buttons[1].DeviceID := o
				this._value := bo
				; Re-open the menu if we just changed to stick
				if (reopen)
					this.OpenMenu()
			} else if (o > 1000 && o < 1129){
				o -= 1000
				bo := this.__value.clone()
				bo.Buttons[1].code := o
				bo.Buttons[1].type := 2
				bo.Type := 2
				this._value := bo
			} else if (o > 2000 && o < 6000){
				o -= 2000
				hat := 1
				while (o > 1000){
					o -= 1000
					hat++
				}
				bo := this.__value.clone()
				bo.Buttons[1].code := o
				bo.Buttons[1].type := 2 + hat
				bo.Type := 2 + hat
				this._value := bo
			}
			if (IsObject(mod)){
				UCR._RequestBinding(this, mod)
				return
			}
		}
	}
	
	_Deserialize(obj){
		; Trigger _value setter to set gui state but not fire change event
		this._value := new _BindObject(obj)
	}
	
	_RequestBinding(){
		; override base and do nothing
	}
	
	__Delete(){
		OutputDebug % "UCR| Output " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		base._KillReferences()
		;~ GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		;~ this.ChangeValueCallback := ""
		;~ this.ChangeStateCallback := ""
	}
}

; ======================================================================== INPUT AXIS ===============================================================
class _InputAxis extends _BannerCombo {
	AHKAxisList := ["X","Y","Z","R","U","V"]
	__value := new _Axis()
	_OptionMap := []
	
	State := -1
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this._BuildOptions()
		this.SetComboState()
	}
	
	_BuildOptions(){
		Loop 8 {
			ji := GetKeyState( A_Index "JoyInfo")
			if (!ji)
				continue
			offset := A_Index * 10
			menu := this.AddSubMenu("Stick " A_index, "Stick" A_index)
			Loop 6 {
				menu.AddMenuItem(A_Index " (" this.AHKAxisList[A_Index] ")", this._ChangedValue.Bind(this, offset + A_Index))
			}
		}
		this.AddMenuItem("Clear", this._ChangedValue.Bind(this, 2))
	}
	
	; The Axis Select DDL changed value
	_ChangedValue(o){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		
		if (o > 10){
			o -= 10
			DeviceID := 1
			while (o > 10){
				DeviceID++
				o -= 10
			}
			axis := o
		} else if (o == 2){
			; Clear Selected
			axis := DeviceID := 0
		}
		this.__value.Axis := axis
		this.__value.DeviceID := DeviceID
		this.SetComboState()
		this.value := this.__value
		UCR.RequestAxisBinding(this)
	}
	
	; All Input types should implement this function, so that if the Input Thread for the profile is terminated...
	; ... then it can be re-built by calling this method on each control.
	_RequestBinding(){
		UCR.RequestAxisBinding(this)
	}
	
	; Set the state of the GuiControl (Inc Cue Banner)
	SetComboState(){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		this._OptionMap := []
		opts := []
		if (DeviceID){
			; Show Sticks and Axes
			max := 14
			index_offset := 0
			if (!Axis)
				str := "Pick an Axis (Stick " DeviceID ")"
		} else {
			str := "Click to select an Input Axis"
			max := 8
			index_offset := 6
		}
		Loop % max {
			map_index := A_Index + index_offset
			if ((map_index > 6 && map_index <= 14))
				joyinfo := GetKeyState( map_index - 6 "JoyInfo")
			else
				joyinfo := 0
			if ((map_index > 6 && map_index <= 14) && !JoyInfo)
				continue
			opts.push(this._Options[map_index])
			this._OptionMap.push(map_index)
		}
		if (DeviceID || axis){
			opts.push(this._Options[15])
			this._OptionMap.push(15)
		}
		
		if (DeviceID && Axis)
			str := "Stick " DeviceID ", Axis " axis " (" this.AHKAxisList[axis] ")"
		
		this.SetOptions(opts)
		this.SetCueBanner(str)
	}
	
	; Get / Set of .value
	value[]{
		; Read of current contents of GuiControl
		get {
			return this.__value
		}
		
		; When the user types something in a guicontrol, this gets called
		; Fire _ControlChanged on parent so new setting can be saved
		set {
			this._value := value
			OutputDebug % "UCR| GuiControl " this.Name " called ParentPlugin._ControlChanged()"
			this.ParentPlugin._ControlChanged(this)
		}
	}
	
	; Get / Set of ._value
	_value[]{
		; this will probably not get called
		get {
			return this.__value
		}
		; Update contents of GuiControl, but do not fire _ControlChanged
		; Parent has told child state to be in, child does not need to notify parent of change in state
		set {
			this.__value := value
			this.SetComboState()
			if (IsObject(this.ChangeValueCallback)){
				this.ChangeValueCallback.Call(this.__value)
			}
		}
	}
	
	_Serialize(){
		obj := {value: this._value}
		return obj
	}
	
	_Deserialize(obj){
		this._value := obj.value
		;UCR.RequestAxisBinding(this)
	}
}
