; ======================================================================== PROFILE ===============================================================
; The Profile class handles everything to do with Profiles.
; It has it's own GUI (this.hwnd), which is parented to the main GUI.
; The Profile's is parent to 0 or more plugins, which are each an instance of the _Plugin class.
; The Gui of each plugin appears inside the Gui of this profile.
Class _Profile {
	ID := ""				; Unique ID. Set in Ctor
	Name := ""				; The name the user gave to the profile
	ParentProfile := 0		; The ID of the parent profile, or 0 if no parent
	Plugins := {}			; A ID-indexed array of Plugin instances
	PluginOrder := []		; The order that plugins are listed in
	_IsGlobal := 0			; 1 if this Profile is Global (Always active)
	_InputThread := 0		; Holds the handle to the Input Thread, if loaded
	InputThread := 0		; Holds the Interface functions for the thread, or 0 if thread not loaded
	_LinkedProfiles := {}	; Profiles with which this one is associated
	__LinkedProfiles := {}	; Table of plugin to profile links, used to build _LinkedProfiles
	InheritsFromParent := 0	
	State := 0				; State of the profile. 0=InActive, 1=InputThread loaded, but disabled, 2=Active (InputThread active)
	StateNames := {0: "Inactive", 1: "PreLoaded", 2: "Active"}
	
	__New(id, name, parent){
		static fn
		this.ID := id
		this.Name := name
		this.ParentProfile := parent
		if (this.Name = "global"){
			this._IsGlobal := 1
		}
		;this._StartInputThread()
		this._CreateGui()
	}

	; Sets the State of the Profile
	; 0 = InActive (Profile stopped, InputThread not loaded)
	; 1 = Preloaded (Profile stopped, InputThread loaded but disabled)
	; 2 = Active (Profile started, InputThread loaded and enabled)
	SetState(state){
		if (this.State == state)
			return
		OutputDebug % "UCR| Profile " this.Name "(" this.id "): SetState to " this.StateNames[state]
		; Start or stop the InputThread
		if (state){
			; InputThread needs to be active in some way
			if (this.State < 1){
				this._StartInputThread()
				this._ActivateOutputs()
			}
			; Activate if State is 2, Deactivate if State is 1
			a := state - 1
		} else {
			; De-Activate
			if (this.State){
				this._StopInputThread()
				this._DeActivateOutputs()
			}
			a := 0
		}
		
		; Activate / Deactivate profile (Cause timers etc in the profile to stop)
		if (a){
			this._Activate()
		} else {
			this._DeActivate()
		}
		
		; Set State
		this.State := state	
	}

	; Updates the list of "Linked" profiles...
	; plugin = plugin altering it's link status with a profile
	; profile = profile that the plugin is altering it's relation to
	; state = new state of the plugin's relation to that profile
	UpdateLinkedProfiles(plugin_id, profile_id, state){
		; Update plugin_id -> profile_id links
		if (!IsObject(this.__LinkedProfiles[plugin_id])){
			this.__LinkedProfiles[plugin_id] := {}
		}
		this.__LinkedProfiles[plugin_id, profile_id] := state
		
		this._RebuildLinkedProfiles()
		UCR.ProfileLinksChanged()
	}
	
	_RebuildLinkedProfiles(){
		; Rebuild profile -> profile links
		this._LinkedProfiles := {}
		for plug, profs in this.__LinkedProfiles {
			for prof, linked in profs {
				if (linked) {
					this._LinkedProfiles[prof] := 1
				}
			}
		}
	}
	
	RemovePluginLinks(id){
		this.__LinkedProfiles.Delete(id)
		this._RebuildLinkedProfiles()
		UCR.ProfileLinksChanged()
	}
	
	; Starts the "Input Thread" which handles detection of input for this profile
	_StartInputThread(){
		if (this.InputThread == 0){
			this._InputThread := AhkThread(UCR._ThreadHeader "`nInputThread := new _InputThread(""" this.id """," ObjShare(UCR._InputHandler.InputEvent.Bind(UCR._InputHandler)) ")`n" UCR._InputThreadScript)

			While !this._InputThread.ahkgetvar.autoexecute_done
				Sleep 10 ; wait until variable has been set.
			OutputDebug % "UCR| Profile " this.Name "(" this.id "): Input Thread started"

			; Get thread-safe boundfunc object for thread's SetHotkeyState
			this.InputThread := {}
			this.InputThread.UpdateBinding := ObjShare(this._InputThread.ahkgetvar("InterfaceUpdateBinding"))
			this.InputThread.UpdateBindings := ObjShare(this._InputThread.ahkgetvar("InterfaceUpdateBindings"))
			this.InputThread.SetDetectionState := ObjShare(this._InputThread.ahkgetvar("InterfaceSetDetectionState"))
			
			Bindings := []
			; Load bindings
			Loop % this.PluginOrder.length() {
				plugin := this.Plugins[this.PluginOrder[A_Index]]
				plugin._RequestOutputBindings()	; ToDo - Output bindings should probably not be handled in here.
				for i, b  in plugin._GetBindings() {
					Bindings.push(b)
				}
			}
			this.InputThread.UpdateBindings(ObjShare(Bindings))
		}
	}
	
	; Stops the "Input Thread" which handles detection of input for this profile
	_StopInputThread(){
		if (this.InputThread != 0){
			ahkthread_free(this._InputThread)
			this._InputThread := 0	; Kill thread
			this.InputThread := 0	; Set var to 0 to indicate thread is off
			OutputDebug % "UCR| Profile " this.Name "(" this.id "): Input Thread Stopped"
		}
		this.UpdateBinding := 0
		this.SetDetectionState := 0
	}
	
	_ActivateOutputs(){
		Loop % this.PluginOrder.length() {
			plugin := this.Plugins[this.PluginOrder[A_Index]]
			plugin._ActivateOutputs()
		}
	}
	
	_DeActivateOutputs(){
		Loop % this.PluginOrder.length() {
			plugin := this.Plugins[this.PluginOrder[A_Index]]
			;plugin._DeActivateOutputs()
		}
	}
	
	; Delete requested
	OnClose(){
		; Kill the InputThread
		this._StopInputThread()
		; Remove child plugins
		for id, plugin in this.Plugins {
			; Close plugin, but do not remove binding as thread is closing anyway
			this._RemovePlugin(plugin, 0)
		}
		Gui, % this.hwnd ":Destroy"
		this.hwnd := 0
	}
	
	__Delete(){
		
	}
	
	_CreateGui(){
		Gui, +HwndhOld	; Preserve previous default Gui
		Gui, Margin, 5, 5
		Gui, new, HwndHwnd
		this.hwnd := hwnd
		try {
			Gui, +Scroll
		}
		Gui, -Caption
		Gui, Add, Edit, % "+Hidden hwndhSpacer y0 w2 h10 x" UCR.PLUGIN_WIDTH + 10
		this.hSpacer := hSpacer
		Gui, Color, 777777
		Gui, % UCR.hProfilePanel ":Add", Gui, % "x0 y0 ah w" UCR.PLUGIN_FRAME_WIDTH " h" UCR.PLUGIN_FRAME_HEIGHT, % this.hwnd
		Gui, % hOld ":Default"	; Restore previous default Gui
	}
	
	; The profile became active
	_Activate(){
		if (this.State == 2)
			return
		OutputDebug % "UCR| Profile " this.Name "(" this.id "): Input Thread Activated"

		if (this.InputThread == 0){
			OutputDebug % "UCR| WARNING: Tried to Activate profile # " this.id " (" this.name " ) without an active Input Thread"
		}
		this.InputThread.SetDetectionState(1)

		this.State := 2
		; Fire Activate on each plugin
		Loop % this.PluginOrder.length() {
			plugin := this.Plugins[this.PluginOrder[A_Index]]
			plugin._OnActive()	; Call base OnActive method of plugin
		}
	}
	
	; The profile went inactive
	_DeActivate(){
		if (this.State == 0)
			return
		;if (this.InputThread != 0){
			;this._SetHotkeyState(0)
			this.InputThread.SetDetectionState(0)
			OutputDebug % "UCR| Profile " this.Name "(" this.id "): Input Thread DeActivated"
		;}
		this._HotkeysActive := 0
		Loop % this.PluginOrder.length() {
			plugin := this.Plugins[this.PluginOrder[A_Index]]
			plugin._OnInactive()
		}
	}
	
	; Show the GUI
	_Show(){
		if (this.hwnd){
			rect := this.GetClientRect(UCR.hProfilePanel)
			Gui, % this.hwnd ":Show", % "w" rect.w " h" rect.h
		}
	}
	
	; Hide the GUI
	_Hide(){
		if (this.hwnd)
			Gui, % this.hwnd ":Hide"
	}
	
	GetClientRect(hwnd){
		VarSetCapacity(RC, 16, 0)
		DllCall("User32.dll\GetClientRect", "Ptr", hwnd, "Ptr", &RC)
		return {w: NumGet(RC, 8, "Int"), h: Numget(RC, 12, "Int")}
	}

	; User clicked Add Plugin button
	_AddPlugin(){
		GuiControlGet, idx, % UCR.hTopPanel ":", % UCR.hPluginSelect
		plugin := UCR.PluginDetails[UCR.PluginList[idx]].ClassName
		name := this._GetUniqueName(plugin)
		if (name = 0)
			return
		id := CreateGUID()
		this.PluginOrder.push(id)
		this.Plugins[id] := new %plugin%(id, name, this)
		this.Plugins[id].Type := plugin
		this._LayoutPlugin()
		UCR._ProfileChanged(this)
		if (IsFunc(this.Plugins[id, "OnActive"]))
			this.Plugins[id].OnActive()
	}
	
	; Layout a plugin.
	; Pass PluginOrder index to lay out, or leave blank to lay out last plugin
	_LayoutPlugin(index := -1){
		static SCROLLINFO:="UINT cbSize;UINT fMask;int  nMin;int  nMax;UINT nPage;int  nPos;int  nTrackPos"
				,scroll:=Struct(SCROLLINFO,{cbSize:sizeof(SCROLLINFO),fMask:4})
		; Find scrollbar position
		GetScrollInfo(this.hwnd,true,scroll[])
		scroll_pos := scroll.nPos

		; Get index of plugin
		plugin_index := (index = -1 ? this.PluginOrder.length() : index)
		; Get reference to plugin
		plugin := this.Plugins[this.PluginOrder[plugin_index]]

		; Calculate y coord for plugin
		new_y := 0
		; Find y coord of previous plugin, if it exists
		if (plugin_index > 1){
			ControlGetPos,,window_y,,,,% "ahk_id " this.hwnd
			ControlGetPos,,new_y,,h,,% "ahk_id " this.Plugins[this.PluginOrder[plugin_index-1]].hFrame
			new_y += h - window_y
		}
		
		; Add gap
		new_y += 5 - (index=-1 ? 0 : scroll_pos)
		
		; Move the plugin
		Gui, % plugin.hFrame ":Show", % "x5 y" new_y " w" UCR.PLUGIN_WIDTH
		
		; Resize the spacer
		ControlGetPos, , , , h, , % "ahk_id " plugin.hFrame
		spacer_height := new_y + h + scroll_pos
		GuiControl, Move, % this.hSpacer, % "h" spacer_height
		
		;OutputDebug % "UCR| Moved plugin " plugin.Name " to y " new_y " and set spacer to height " spacer_height ". Scroll pos is: " scroll_pos " and window_y was " window_y

	}
	
	; Lays out all plugins
	_LayoutPlugins(){
		;~ static SCROLLINFO:="UINT cbSize;UINT fMask;int  nMin;int  nMax;UINT nPage;int  nPos;int  nTrackPos"
				;~ ,scroll:=Struct(SCROLLINFO,{cbSize:sizeof(SCROLLINFO)})
		;~ scroll.fMask:=0x17
		;~ GetScrollInfo(this.hwnd,true,scroll[])
		;~ scrollPos:=scroll.nPos
		max := this.PluginOrder.length()
		if (max){
			Loop % max{
				this._LayoutPlugin(A_Index)
			}
			;~ GetScrollInfo(this.hwnd,true,scroll[])
			;~ scroll.nPos:=scrollPos>scroll.nMax ? scroll.nMax : scrollPos
			;~ SendMessage,0x115,0,% LoWord(4)|HiWord(scrollPos>scroll.nMax ? -scroll.nMax : -scrollPos),,% "ahk_id " this.hwnd
		} else {
			GuiControl, Move, % this.hSpacer, % "h10"
		}
	}
	
	; Rename a plugin
	_RenamePlugin(plugin){
		name := this._GetUniqueName(plugin.Name, 0)
		if (name = 0)
			return
		plugin.ChangeName(name)
		UCR._ProfileChanged(this)
	}
	
	_ReorderPlugin(plugin, dir){
		i := 0
		max := this.PluginOrder.length()
		Loop % max {
			if (this.PluginOrder[A_Index] == plugin.id){
				i := A_Index
				break
			}
		}
		if (i == 0 || (dir == -1 && i == 1) || (dir == 1 && i == max))
			return
		other_plugin := this.Plugins[this.PluginOrder[i + dir]]
		id := this.PluginOrder.RemoveAt(i)
		this.PluginOrder.InsertAt(i + dir, id)
		
		if (dir == 1){
			this.SwapPluginOrder(other_plugin, plugin)
		} else {
			this.SwapPluginOrder(plugin, other_plugin)
		}
		UCR._ProfileChanged(this)
	}
	
	SwapPluginOrder(plugin, other_plugin){
		ControlGetPos,, other_y,,,,% "ahk_id " other_plugin.hFrame
		new_top := this.GetYCoord(other_y)
		Gui, % plugin.hFrame ":Show", % "x5 y" new_top " w" UCR.PLUGIN_WIDTH
		ControlGetPos,,plugin_y,,plugin_h,,% "ahk_id " plugin.hFrame
		Gui, % other_plugin.hFrame ":Show", % "x5 y" this.GetYCoord(plugin_y + plugin_h + 5) " w" UCR.PLUGIN_WIDTH
	}
	
	GetYCoord(y){
		ControlGetPos,,window_y,,,,% "ahk_id " this.hwnd
		return y - window_y
	}
	
	; Delete a plugin
	_RemovePlugin(plugin, remove_binding := 1){
		plugin.OnClose(remove_binding)
		ControlGetPos, , , , height_frame, ,% "ahk_id " plugin.hFrame
		Gui, % plugin.hwnd ":Destroy"
		Gui, % plugin.hFrame ":Destroy"
		Loop % this.PluginOrder.length(){
			if (this.PluginOrder[A_Index] = plugin.id){
				this.PluginOrder.RemoveAt(A_Index)
				break
			}
		}
		
		this.RemovePluginLinks(plugin.id)
		ControlGetPos, , , , height_spacer, ,% "ahk_id " this.hSpacer
		GuiControl, Move, % this.hSpacer, % "h" height_spacer - height_frame
		this.Plugins.Delete(plugin.id)
		plugin := ""
		this._PluginChanged()
		this._LayoutPlugins()
	}
	
	; Obtain a profile-unique name for the plugin, with a suggestion
	; Name param is the base from which suggestions are generated
	; eg passing "MyPlugin" would suggest "MyPlugin 1"
	_GetUniqueName(name, build_name := 1){
		if (build_name){
			name .= " "
			num := 1
			Loop {
				this_name := name num
				if (this._IsNameUnique(this_name))
					break
				else
					num++
			}
			name := this_name
		}
		prompt := "Enter a name for the Plugin"
		Loop {
			coords := UCR.GetCenteredCoordinates(375, 130)
			InputBox, name, Add Plugin, % prompt, ,,130,% coords.x,% coords.y,,, % name
			if (!ErrorLevel){
				if (!this._IsNameUnique(name) && (name != name)){
					prompt := "Duplicate name chosen, please enter a unique name"
					name := suggestedname
				} else {
					return name
				}
			} else {
				return 0
			}
		}
	}
	
	; Returns true if no profile has a plugin with the same name
	_IsNameUnique(name){
		for id, plugin in this.Plugins {
			if (plugin.Name = name){
				return 0
			}
		}
		return 1
	}

	; Save the profile to disk
	_Serialize(){
		obj := {Name: this.Name}
		obj.ParentProfile := this.ParentProfile
		obj.InheritsFromParent := this.InheritsFromParent
		obj.Plugins := {}
		obj.PluginOrder := this.PluginOrder
		for id, plugin in this.Plugins {
			obj.Plugins[id] := plugin._Serialize()
		}
		return obj
	}
	
	; Load the profile from disk
	_Deserialize(obj){
		this.ParentProfile := obj.ParentProfile
		this.InheritsFromParent := obj.InheritsFromParent
		Loop % obj.PluginOrder.length() {
			id := obj.PluginOrder[A_Index]
			this.PluginOrder.push(id)
			plugin := obj.Plugins[id]
			cls := plugin.Type
			if (!IsObject(%cls%)){
				msgbox % "Plugin class " cls " not found - removing from profile """ this.Name """"
				this.PluginOrder.Pop()
				obj.Plugins.Delete(id)
				continue
			}
			this.Plugins[id] := new %cls%(id, plugin.name, this)
			this.Plugins[id]._Deserialize(plugin)
			this._LayoutPlugin()
		}
	}

	_PluginChanged(){
		;OutputDebug % "UCR| Profile " this.Name " called UCR._ProfileChanged()"
		UCR._ProfileChanged(this)
	}
}
