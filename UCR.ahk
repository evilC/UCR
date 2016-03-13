#SingleInstance force

#include Libraries\JSON.ahk
OutputDebug DBGVIEWCLEAR
SetBatchLines, -1
global UCR	; set UCR as a super-global
new UCRMain()
return

; ======================================================================== MAIN CLASS ===============================================================
Class UCRMain {
	Version := "0.0.7"				; The version of the main application
	SettingsVersion := "0.0.2"		; The version of the settings file format
	_StateNames := {0: "Normal", 1: "InputBind", 2: "GameBind"}
	_State := {Normal: 0, InputBind: 1, GameBind: 2}
	_GameBindDuration := 0	; The amount of time to wait in GameBind mode (ms)
	_CurrentState := 0				; The current state of the application
	;Profiles := []					; A hwnd-indexed sparse array of instances of _Profile objects
	Profiles := {}					; A unique-id indexed sparse array of instances of _Profile objects
	ProfileTree := {}				; A lookup table for Profile order. A sparse array of Parent IDs, containing Ordered Arrays of Profile IDs
	Libraries := {}					; A name indexed array of instances of library objects
	CurrentProfile := 0				; Points to an Instance of the _Profile class which is the current active profile
	PluginList := []				; A list of plugin Types (Lookup to PluginDetails), indexed by order of Plugin Select DDL
	PluginDetails := {}				; A name-indexed list of plugin Details (Classname, Description etc). Name is ".Type" property of class
	PLUGIN_WIDTH := 680				; The Width of a plugin
	PLUGIN_FRAME_WIDTH := 720		; The width of the app
	TOP_PANEL_HEIGHT := 75			; The amount of space reserved for the top panel (profile select etc)
	GUI_MIN_HEIGHT := 300			; The minimum height of the app. Required because of the way AHK_H autosize/pos works
	CurrentSize := {w: this.PLUGIN_FRAME_WIDTH, h: this.GUI_MIN_HEIGHT}	; The current size of the app.
	CurrentPos := {x: "", y: ""}										; The current position of the app.
	_ProfileTreeChangeSubscriptions := {}	; An hwnd-indexed array of callbacks for things that wish to be notified if the profile tree changes
	
	__New(){
		global UCR := this			; Set super-global UCR to point to class instance
		Gui +HwndHwnd
		this.hwnd := hwnd
		
		str := A_ScriptName
		if (A_IsCompiled)
			str := StrSplit(str, ".exe")
		else
			str := StrSplit(str, ".ahk")
		this._SettingsFile := A_ScriptDir "\" str.1 ".ini"
		
		; Load the Joystick OEM name DLL
		#DllImport,joystick_OEM_name,%A_ScriptDir%\Resources\JoystickOEMName.dll\joystick_OEM_name,double,,CDecl AStr
		;~ DllCall("LoadLibrary", Str, A_ScriptDir "\Resources\JoystickOEMName.dll")
		;~ if (ErrorLevel != 0){
			;~ MsgBox Error Loading \Resources\JoystickOEMName.dll. Exiting...
			;~ ExitApp
		;~ }
		; Provide a common repository of libraries for plugins (vJoy, HID libs etc)
		this._LoadLibraries()
		
		; Start the input detection system
		this._BindModeHandler := new _BindModeHandler()
		this._InputHandler := new _InputHandler()

		; Add the Profile Toolbox - this is used to add and edit profiles
		this._ProfileToolbox := new _ProfileToolbox()
		this._ProfilePicker := new _ProfilePicker()

		; Create the Main Gui
		this._CreateGui()
		
		; Load settings. This will cause all plugins to load.
		p := this._LoadSettings()

		; Update state of Profile Toolbox
		this.UpdateProfileToolbox()

		; Now we have settings from disk, move the window to it's last position and size
		this._ShowGui()
		
		this.Profiles.1._Activate()
		this.ChangeProfile(p, 0)

		; Watch window position and size using MessageFilter thread
		this._MessageFilterThread := AhkThread(A_ScriptDir "\Threads\MessageFilterThread.ahk",,1)
		While !this._MessageFilterThread.ahkgetvar.autoexecute_done
			Sleep 50 ; wait until variable has been set.
		matchobj := {msg: 0x5, hwnd: this.hwnd}
		filterobj := {hwnd: this.hwnd}
		this._MessageFilterThread.ahkExec["new MessageFilter(" ObjShare(this._OnSize.Bind(this)) "," &matchobj "," &filterobj ")"]
		matchobj.msg := 0x3
		this._MessageFilterThread.ahkExec["new MessageFilter(" ObjShare(this._OnMove.Bind(this)) "," &matchobj "," &filterobj ")"]
	}
	
	GuiClose(hwnd){
		if (hwnd = this.hwnd)
			ExitApp
	}
	
	; Libraries can be used to easily add functionality to UCR.
	; Place a folder in the Libraries folder eg "MyLib", with an ahk file of the same name (eg "MyLib.ahk") and it will be included.
	; It should contain a class definition of the same name (eg "Class MyLib") which will be instantiated and added to the Libraries array
	; Once instantiated, the method _UCR_LoadLibrary() will be called on the instance. It has the opportunity to return 1 for OK, 0 for fail
	; The class instance will be available for all plugins as UCR.Libraries.MyLib
	_LoadLibraries(){
		Loop, Files, % A_ScriptDir "\Libraries\*.*", D
		{
			str := A_LoopFileName
			filename := A_ScriptDir "\Libraries\" A_LoopFileName "\" A_LoopFileName ".ahk"
			if (FileExist(filename)){
				AddFile(filename, 1)
				lib := new %A_LoopFileName%()
				res := lib._UCR_LoadLibrary()
				if (res == 1)
					this.Libraries[A_LoopFileName] := lib
			}
		}
	}
	
	_CreateGui(){
		Gui, % this.hwnd ":Margin", 0, 0
		Gui, % this.hwnd ":+Resize"
		Gui, % this.hwnd ":Show", % "Hide w" UCR.PLUGIN_FRAME_WIDTH " h" UCR.GUI_MIN_HEIGHT, % "UCR - Universal Control Remapper v" this.Version
		Gui, % this.hwnd ":+Minsize" UCR.PLUGIN_FRAME_WIDTH "x" UCR.GUI_MIN_HEIGHT
		Gui, % this.hwnd ":+Maxsize" UCR.PLUGIN_FRAME_WIDTH
		Gui, new, HwndHwnd
		this.hTopPanel := hwnd
		Gui % this.hTopPanel ":-Border"
		;Gui % this.hTopPanel ":Show", % "x0 y0 w" UCR.PLUGIN_FRAME_WIDTH " h" UCR.TOP_PANEL_HEIGHT, Main UCR Window
		
		; Profile Select DDL
		Gui, % this.hTopPanel ":Add", Text, xm y+10, Current Profile:
		Gui, % this.hTopPanel ":Add", Edit, % "x100 yp-5 hwndhCurrentProfile Disabled w" UCR.PLUGIN_FRAME_WIDTH - 220
		this.hCurrentProfile := hCurrentProfile
		
		Gui, % this.hTopPanel ":Add", Button, % "x+5 yp-1 hwndhProfileToolbox w100", Profile Toolbox
		this.hProfileToolbox := hProfileToolbox
		fn := this._ProfileToolbox.ShowButtonClicked.Bind(this._ProfileToolbox)
		GuiControl +g, % this.hProfileToolbox, % fn

		; Add Plugin
		Gui, % this.hTopPanel ":Add", Text, xm y+10, Plugin Selection:
		Gui, % this.hTopPanel ":Add", DDL, % "x100 yp-5 hwndhPluginSelect AltSubmit w" UCR.PLUGIN_FRAME_WIDTH - 150
		this.hPluginSelect := hPluginSelect

		Gui, % this.hTopPanel ":Add", Button, % "hwndhAddPlugin x+5 yp-1", Add
		this.hAddPlugin := hAddPlugin
		fn := this._AddPlugin.Bind(this)
		GuiControl % this.hTopPanel ":+g", % this.hAddPlugin, % fn
		
		Gui, % this.hwnd ":Add", Gui, % "w" UCR.PLUGIN_FRAME_WIDTH " h" UCR.TOP_PANEL_HEIGHT, % this.hTopPanel

		;Gui, % this.hwnd ":Show"
	}
	
	_ShowGui(){
		xy := (this.CurrentPos.x != "" && this.CurrentPos.y != "" ? "x" this.CurrentPos.x " y" this.CurrentPos.y : "")
		Gui, % this.hwnd ":Show", % xy " h" this.CurrentSize.h
	}
	
	_OnMove(wParam, lParam, msg, hwnd){
		;this.CurrentPos := {x: LoWord(lParam), y: HiWord(lParam)}
		; Use WinGetPos rather than pos in message, as this is the top left of the Gui, not the client rect
		; ToDo: andle minimize / maximize better
		if (IsIconic(this.hwnd))
			return
		WinGetPos, x, y, , , % "ahk_id " this.hwnd
		if (x != "" && y != ""){
			this.CurrentPos := {x: x, y: y}
			this._SaveSettings()
		}
	}
	
	_OnSize(wParam, lParam, msg, hwnd){
		this.CurrentSize.h := HiWord(lParam)
		this._SaveSettings()
	}
	
	; The user clicked the "Add Plugin" button
	_AddPlugin(){
		this.CurrentProfile._AddPlugin()
	}
	
	; We wish to change profile. This may happen due to user input, or application changing
	ChangeProfile(id, save := 1){
		if (!ObjHasKey(this.Profiles, id))
			return 0
		newprofile := this.Profiles[id]
		OutputDebug % "Changing Profile from " this.CurrentProfile.Name " to: " newprofile.Name
		if (IsObject(this.CurrentProfile)){
			if (id = this.CurrentProfile.id)
				return 1
			this.CurrentProfile._Hide()
			if (!this.CurrentProfile._IsGlobal)
				this.CurrentProfile._DeActivate()
		}
		
		this.CurrentProfile := this.Profiles[id]
		
		this.UpdateCurrentProfileReadout()
		this._ProfileToolbox.SelectProfileByID(id)
		
		this.CurrentProfile._Activate()
		this.CurrentProfile._Show()
		if (save){
			this._ProfileChanged(this.CurrentProfile)
		}
		return 1
	}
	
	UpdateCurrentProfileReadout(){
		GuiControl, % this.hTopPanel ":", % this.hCurrentProfile, % this.BuildProfilePathName(this.CurrentProfile.id)
	}
	
	BuildProfilePathName(id){
		if (!ObjHasKey(this.profiles, id))
			return ""
		str := this.Profiles[id].Name
		while (this.Profiles[id].ParentProfile != 0){
			p := this.Profiles[id], pp := this.Profiles[p.ParentProfile]
			str := pp.Name " >> " str
			id := pp.id
		}
		return str
	}
	
	; Some aspect of the Profile Tree changed - eg structure or names of profiles in tree
	; Rebuild the tree
	UpdateProfileToolbox(){
		this._ProfileToolbox.BuildProfileTree()
		this.FireProfileTreeChangeCallbacks()
	}
	
	SubscribeToProfileTreeChange(hwnd, callback){
		this._ProfileTreeChangeSubscriptions[hwnd] := callback
	}
	
	UnSubscribeToProfileTreeChange(hwnd){
		this._ProfileTreeChangeSubscriptions.Delete(hwnd)
	}
	
	FireProfileTreeChangeCallbacks(){
		for hwnd, cb in this._ProfileTreeChangeSubscriptions {
			if (IsObject(cb))
				cb.Call()
		}
	}
	
	; Update hPluginSelect with a list of available Plugins
	_UpdatePluginSelect(){
		this.PluginList := []
		str := ""
		i := 1
		for type, obj in this.PluginDetails {
			if (i > 1)
				str .= "|"
			str .= type "     - " obj.Description
			this.PluginList.push(type)
			if (i == 1){
				str .= "|"
			}
			i++
		}
		GuiControl,  % this.hTopPanel ":", % this.hPluginSelect, % str
	}
	
	; User clicked add new profile button
	_AddProfile(parent := 0){
		name := this._GetProfileName()
		if (name = 0)
			return
		id := this._CreateProfile(name, 0, parent)
		if (!IsObject(this.ProfileTree[parent]))
			this.ProfileTree[parent] := []
		this.ProfileTree[parent].push(id)
		this.UpdateProfileToolbox()
		this.ChangeProfile(id)
	}
	
	RenameProfile(id){
		if (!ObjHasKey(this.Profiles, id))
			return 0
		name := this._GetProfileName()
		if (name = 0)
			return 0
		this.Profiles[id].Name := name
		this.UpdateProfileToolbox()
		this.UpdateCurrentProfileReadout()
		this._SaveSettings()
	}

	MoveProfile(profile_id, parent_id, after){
		if (parent_id == "")
			parent_id := 0
		OutputDebug % "UCR.MoveProfile: profile: " profile_id ", parent: " parent_id ", after: " after
		; Do not allowing move of default or global profile
		if (profile_id < 3 || !ObjHasKey(this.Profiles, profile_id))
			return 0
		; Make sure parent_id is 0 or a valid profile_id
		if (parent_id != 0 && !ObjHasKey(this.Profiles, parent_id))
			return 0
		; Make sure requested move is valid
		if (after = 1 || (parent_id = 0 && after == "First") || parent_id == 1 || parent_id == 2)
			return 0

		profile := this.Profiles[profile_id]
		; Remove from old parent list
		for k, v in this.ProfileTree[profile.ParentProfile] {
			if (v == profile_id){
				this.ProfileTree[profile.ParentProfile].Remove(k)
				break
			}
		}
		; Add to new parent list
		if (!IsObject(this.ProfileTree[parent_id]))
			this.ProfileTree[parent_id] := []
		if (after == ""){
			this.ProfileTree[parent_id].push(profile_id)
		} else if (after == "First"){
			this.ProfileTree[parent_id].InsertAt(1, profile_id)
		} else {
			Loop % this.ProfileTree[parent_id].length(){
				if (this.ProfileTree[parent_id, A_Index] = after){
					this.ProfileTree[parent_id].InsertAt(A_Index + 1, profile_id)
					break
				}
			}
		}
		profile.ParentProfile := parent_id
		this.UpdateProfileToolbox()
		this.UpdateCurrentProfileReadout()
		this._SaveSettings()
	}
	
	; Creates a new profile and assigns it a unique ID, if needed.
	_CreateProfile(name, id := 0, parent := 0){
		if (id = 0){
			Loop {
				;id := A_NOW
				Random, id, 3, 2147483647
				;Sleep 10
			} until !IsObject(this.ProfileIDs[id])
		}
		profile := new _Profile(id, name, parent)
		this.Profiles[id] := profile
		return id
	}
	
	; user clicked the Delete Profile button
	_DeleteProfile(){
		id := this.CurrentProfile.id
		if (id = 1 || id = 2)
			return
		pp := this.CurrentProfile.ParentProfile
		if pp != 0
			newprofile := pp
		else
			newprofile := 2
		this._DeleteChildProfiles(id)
		this.__DeleteProfile(id)
		this.UpdateProfileToolbox()
		this.ChangeProfile(newprofile)
	}
	
	; Actually deletes a profile
	__DeleteProfile(id){
		; Remove profile's entry from ProfileTree
		profile := this.Profiles[id]
		treenode := this.ProfileTree[profile.ParentProfile]
		for k, v in treenode {
			if (v == id){
				treenode.Remove(k)	; Use Remove, so indexes shuffle down.
				; If array is empty, remove from tree
				if (!treenode.length())
					this.ProfileTree.Delete(profile.ParentProfile)	; Sparse array - use Delete instead of Remove
				break
			}
		}
		; Kill profile object
		this.profiles.Delete(profile.id)
	}
	
	; Recursively deletes child profiles
	_DeleteChildProfiles(id){
		for i, profile in this.Profiles{
			if (profile.ParentProfile = id){
				this._DeleteChildProfiles(profile.id)
				this.__DeleteProfile(profile.id)
			}
		}
	}
	
	; Load a list of available plugins
	_LoadPluginList(){
		Loop, Files, % A_ScriptDir "\Plugins\*.ahk", FR
		{
			FileRead,plugincode,% A_LoopFileFullPath
			RegExMatch(plugincode,"i)class\s+(\w+)\s+extends\s+_Plugin",classname)
			
			
			; Check if the classname already exists.
			if (IsObject(%classname1%)){
				cls := %classname1%
				if (cls.base.__Class = "_Plugin"){
					; Existing class extends plugin
					; Class has been included via other means (eg to debug it), so do not try to include again.
					continue
				}
			}
			dllthread := AhkThread("#NoTrayIcon`ntest := new " classname1 "()`ntype := test.type, description := test.description, autoexecute_done := 1`nLoop {`nsleep 10`n}`nclass _Plugin {`n}`n" plugincode)
			t := A_TickCount + 1000
			While !(autoexecute_done := dllthread.ahkgetvar.autoexecute_done) && A_TickCount < t
				Sleep 10
			if (autoexecute_done){
				Type := dllthread.ahkgetvar.Type
				Description := dllthread.ahkgetvar.Description
			}
			ahkthread_free(dllthread)
			dllthread := ""
			if (!autoexecute_done){
				MsgBox % "Plugin " classname1 " failed to load. Removing from list."
				continue
			} else if (Type == "" || Description == ""){
				MsgBox % "Plugin " classname1 " does not have a type or description. Removing from list."
				continue
			}
			this.PluginDetails[Type] := {Description: Description, ClassName: classname1}
			AddFile(A_LoopFileFullPath, 1)
		}
	}
	
	; Load settings from disk
	_LoadSettings(){
		this._LoadPluginList()
		this._UpdatePluginSelect()
		
		FileRead, j, % this._SettingsFile
		if (j = ""){
			; Settings file empty or not found, create new settings
			j := {"CurrentProfile":"2", "SettingsVersion": this.SettingsVersion, "ProfileTree": {0: [1, 2]}, "Profiles":{"1":{"Name": "Global", "ParentProfile": "0"}, "2": {"Name": "Default", "ParentProfile": "0"}}}
		} else {
			OutputDebug % "Loading JSON from disk"
			j := JSON.Load(j)
		}
		
		; Check if Settings file is a compatible version
		if (j.SettingsVersion != this.SettingsVersion){
			; No, try to upgrade
			j := this._UpdateSettings(j)
			; Did upgrade succeed?
			if (j.SettingsVersion != this.SettingsVersion){
				; No, warn and exit.
				msgbox % this._SettingsFile " is incompatible with this version of UCR."
				ExitApp
			}
		}
		; Load profiles / plugins from settings file
		this._Deserialize(j)
		return j.CurrentProfile
	}
	
	; Save settings to disk
	; ToDo: improve. Only the thing that changed needs to be re-serialized. Cache values.
	_SaveSettings(){
		static SettingsFile, obj
		SetTimer, Save, Off
		obj := this._Serialize()
		SettingsFile := this._SettingsFile
		SetTimer, Save, -1000
		Return
		Save:
			OutputDebug % "Saving JSON to disk"
			FileReplace(JSON.Dump(obj, ,true), SettingsFile)
		Return

	}
	
	; If SettingsVersion changes, this handles converting the INI file to the new format
	_UpdateSettings(obj){
		if (obj.SettingsVersion = "0.0.1"){
			; Upgrade from 0.0.1 to 0.0.2
			; Convert profiles from name-indexed to unique-id indexed
			oldprofiles := obj.Profiles.clone()
			obj.Profiles := {}
			obj.ProfileTree := {0: [1, 2]}
			obj.CurrentProfile := 2
			for name, profile in oldprofiles {
				if (name = "global"){
					id := 1
				} else if (name = "default"){
					id := 2
				} else {
					Loop {
						;id := A_NOW
						Random, id, 3, 2147483647
						;Sleep 10
					} until (!ObjHasKey(obj.Profiles, id))
					obj.ProfileTree[0].push(id)
				}
				profile.id := id
				profile.Name := name
				profile.ParentProfile := 0
				obj.Profiles[id] := profile
			}
			obj.SettingsVersion := "0.0.2"
			return obj
		}
		; Default to making no changes
		return obj
	}
	
	; A child profile changed in some way
	_ProfileChanged(profile){
		this._SaveSettings()
	}
	
	; Turns on or off GameBind mode. In GameBind mode, all outputs are delayed
	SetGameBindState(state){
		if (state){
			if (this._CurrentState == this._State.Normal){
				this._CurrentState := this._State.GameBind
				return 1
			}
		} else {
			if (this._CurrentState == this._State.GameBind){
				this._CurrentState := this._State.Normal
				return 1
			}
		}
		return 0
	}
	
	; The user selected the "Bind" option from an Input/OutputButton GuiControl,
	;  or changed an option such as "Wild" in an InputButton
	_RequestBinding(hk, delta := 0){
		if (delta = 0){
			; Change Buttons requested - start Bind Mode.
			if (this._CurrentState == this._State.Normal){
				this._CurrentState := this._State.InputBind
				this.Profiles.Global._SetHotkeyState(0)
				hk.ParentPlugin.ParentProfile._SetHotkeyState(0)
				this._BindModeHandler.StartBindMode(hk, this._BindModeEnded.Bind(this))
				return 1
			}
			return 0
		} else {
			; Change option (eg wild, passthrough) requested
			bo := hk.value.clone()
			for k, v in delta {
				bo[k] := v
			}
			if (this._InputHandler.IsBindable(hk, bo)){
				hk.value := bo
				this._InputHandler.SetButtonBinding(hk)
			}
			hk.ParentPlugin.ParentProfile._SetHotkeyState(1)
			this.Profiles.Global._SetHotkeyState(1)
		}
	}
	
	; Bind Mode Ended.
	; Decide whether or not binding is valid, and if so set binding and re-enable inputs
	_BindModeEnded(hk, bo){
		OutputDebug % "Bind Mode Ended: " bo.Buttons[1].code
		this._CurrentState := this._State.Normal
		if (hk._IsOutput){
			hk.value := bo
		} else {
			if (this._InputHandler.IsBindable(hk, bo)){
				hk.value := bo
				this._InputHandler.SetButtonBinding(hk)
			}
		}
		this.Profiles.Global._SetHotkeyState(1)
		hk.ParentPlugin.ParentProfile._SetHotkeyState(1)
	}
	
	; Request an axis binding.
	RequestAxisBinding(axis){
		this._InputHandler.SetAxisBinding(axis)
	}
	
	; Request a Mouse Axis Delta binding
	RequestDeltaBinding(delta){
		this._InputHandler.SetDeltaBinding(delta)
	}
	
	; Picks a suggested name for a new profile, and presents user with a dialog box to set the name of a profile
	_GetProfileName(){
		c := 1
		found := 0
		while (!found){
			found := 1
			for id, profile in this.Profiles {
				if (profile.Name = "Profile " c){
					c++
					found := 0
					break
				}
			}
		}
		suggestedname := "Profile " c
		; Allow user to pick name
		prompt := "Enter a name for the Profile"
		InputBox, name, Add Profile, % prompt, ,,130,,,,, % suggestedname
		return (ErrorLevel ? 0 : name)
	}
	
	; Serialize this object down to the bare essentials for loading it's state
	_Serialize(){
		obj := {SettingsVersion: this.SettingsVersion
			, CurrentProfile: this.CurrentProfile.id
			, CurrentSize: this.CurrentSize
			, CurrentPos: this.CurrentPos
			, Profiles: {}
			, ProfileTree: this.ProfileTree}
		for id, profile in this.Profiles {
			obj.Profiles[id] := profile._Serialize()
		}
		return obj
	}

	; Load this object from simple data strutures
	_Deserialize(obj){
		this.Profiles := {}
		this.ProfileTree := obj.ProfileTree
		for id, profile in obj.Profiles {
			this._CreateProfile(profile.Name, id, profile.ParentProfile)
			this.Profiles[id]._Deserialize(profile)
			this.Profiles[id]._Hide()
		}
		;this.CurrentProfile := this.Profiles[obj.CurrentProfile]
		
		if (IsObject(obj.CurrentSize))
			this.CurrentSize := obj.CurrentSize
		if (IsObject(obj.CurrentPos))
			this.CurrentPos := obj.CurrentPos
	}
}

; =================================================================== MAIN PROFILE SELECT / ADD ==========================================================
; The main tool that the user uses to change profile, add / remove / rename / re-order profiles etc
class _ProfileToolbox extends _ProfileSelect {
	__New(){
		base.__New()
		Gui, Add, Button, xm w30 hwndhAdd y210 aya aw1/4, Add
		fn := this.AddProfile.Bind(this,0)
		GuiControl +g, % hAdd, % fn

		Gui, Add, Button, x+5 w60 hwndhAdd y210 aya axa aw1/4, Add Child
		fn := this.AddProfile.Bind(this,1)
		GuiControl +g, % hAdd, % fn

		Gui, Add, Button, x+5 w50 hwndhRename y210 aya axa aw1/4, Rename
		fn := this.RenameProfile.Bind(this)
		GuiControl +g, % hRename, % fn
		
		Gui, Add, Button, x+5 w40 hwndhDelete y210 aya axa aw1/4, Delete
		fn := this.DeleteProfile.Bind(this)
		GuiControl +g, % hDelete, % fn

		this.DragMidFn := this.Treeview_Dragging.Bind(this)
		this.DragEndFn := this.Treeview_EndDrag.Bind(this)
	}
	
	AddProfile(childmode){
		if (childmode)
			parent := this.ProfileIDOfSelection()
		else
			parent := 0
		UCR._AddProfile(parent)
	}
	
	DeleteProfile(){
		id := this.ProfileIDOfSelection()
		UCR._DeleteProfile(id)
	}
	
	RenameProfile(){
		id := this.ProfileIDOfSelection()
		UCR.RenameProfile(id)
	}
	
	TV_Event(){
		if (A_GuiEvent == "Normal" || A_GuiEvent == "S"){
			UCR.ChangeProfile(this.LvHandleToProfileId[A_EventInfo])
		} else if (A_GuiEvent == "D"){
			this.hDragitem := A_EventInfo
			this.Treeview_BeginDrag()
		}
	}
	
	ShowButtonClicked(){
		CoordMode, Mouse, Screen
		MouseGetPos, x, y
		Gui, % this.hwnd ":Show", % "x" x - 110 " y" y - 5, Profile Toolbox
	}
	
	;~ DeleteNode(node){
		;~ pid := this.LvHandleToProfileId[node]
		;~ this.LvHandleToProfileId.Delete(node)
		;~ this.ProfileIdToLvHandle.Delete(pid)
	;~ }
	
	MoveNode(node, parent, after){
		profile_id := this.LvHandleToProfileId[node]
		parent_id := this.LvHandleToProfileId[parent]
		if (ObjHasKey(this.LvHandleToProfileId, after))
			after := this.LvHandleToProfileId[after]
		UCR.MoveProfile(profile_id, parent_id, after)
	}
	
	; A drag started on a TreeView item
	Treeview_BeginDrag( )
	{
		static TVM_SELECTITEM := 0x110B, TVGN_CARET := 0x9
 
		; Select the item before dragging so it's clear what you're dragging
		SendMessage_( this.hTreeview, TVM_SELECTITEM, TVGN_CARET, this.hDragitem )
 
		; Set the dragging flag
		this.TV_is_dragging := 1	
		OnMessage( 0x200, this.DragMidFn ) ; WM_MOUSEMOVE
	}
	
	; A drag is in progress on a treeview item - called each time the mouse moves
	Treeview_Dragging( wParam, lParam )
	{
		static TVM_HITTEST := 0x1111, TVM_SETINSERTMARK := 0x111A, TVM_GETITEMRECT := 0x1104
		static TVM_SELECTITEM := 0x110B, TVGN_DROPHILITE := 0x8, TVM_GETITEMHEIGHT := 0x111C
 
		If (this.TV_is_dragging)
		{
			if (!this.height)
				this.height := SendMessage_( this.hTreeview, TVM_GETITEMHEIGHT, 0, 0 )
 
			; Get the mouse location out of lParam
			x := lParam & 0xFFFF
			y := lParam >> 16
 
			; Create the TVHITTESTINFO struct...
			VarSetCapacity( tvht, 16, 0 )
			NumPut( x, tvht, 0, "int" ), NumPut( y, tvht, 4, "int" )
 
			; ... to determine whether the pointer is over an item. If it is...
			If (hitTarget := SendMessage_( this.hTreeview, TVM_HITTEST, 0, &tvht ))
			{
				; ... highlight the item as a drop target, and / or ...
				SendMessage_( this.hTreeview, TVM_SELECTITEM, TVGN_DROPHILITE, hitTarget )
 
				; ... if the pointer is in the top or bottom quarter of the item,
				; show an insertion mark before or after, respectively.
				; This way you can decide whether to make the dragged item
				; a child or sibling of the drop target item.	
				;
				; If you really wanted, you could check here to see what kind of 
				; item hitTarget was and display the insertion mark accordingly.
				VarSetCapacity( rcitem, 16, 0 ), NumPut( hitTarget, rcitem )
				SendMessage_( this.hTreeview, TVM_GETITEMRECT, 1, &rcitem )
				rcitem_top := NumGet( rcitem, 4, "int" )
				rcitem_bottom := NumGet( rcitem, 12, "int" )
				fAfter := -1 ; just a default that's not 0 or 1
				fAfter := ( y - rcitem_top ) < ( this.height/4 ) ? 0 : ( rcitem_bottom - y) < ( this.height/4 ) ? 1 : fAfter
				If ( fAfter = -1 )
					SendMessage_( this.hTreeview, TVM_SETINSERTMARK, 0, 0 ) ; hide insertionmark
				Else
					SendMessage_( this.hTreeview, TVM_SETINSERTMARK, fAfter, hitTarget ) ; show insertion mark
				this.BeforeAfter := fAfter + 1
				;OutputDebug % "Treeview_Dragging: this.BeforeAfter: " this.BeforeAfter
			}
		}
		OnMessage( 0x202, this.DragEndFn ) ; WM_LBUTTONUP
	}
	
	; A drag on a treeview item ended (The mouse went up)
	Treeview_EndDrag( wParam, lParam )
	{
		static TVM_SETINSERTMARK := 0x111A, TVM_SELECTITEM := 0x110B, TVGN_DROPHILITE := 0x8
		static TVM_HITTEST := 0x1111
 
		If (this.TV_is_dragging)
		{
			; Remove the drop-target highlighting and insertion mark
			SendMessage_( this.hTreeview, TVM_SELECTITEM, TVGN_DROPHILITE, 0 )
			SendMessage_( this.hTreeview, TVM_SETINSERTMARK, 1, 0 )
 
			; Add code here to handle the moving of the dragged node
			; - hDragitem is the handle to the item currently being dragged
			; - you can use the code from the WM_MOUSEMOVE to determine 
			;   where the pointer is and where/how the item should be inserted
			;
			; For the sake of simplicity, this script will always move the 
			; dragitem to be a child of the drop target
 
				; Get the mouse location out of lParam
				x := lParam & 0xFFFF
				y := lParam >> 16
 
				; Create the TVHITTESTINFO struct...
				VarSetCapacity( tvht, 16, 0 )
				NumPut( x, tvht, 0, "int" ), NumPut( y, tvht, 4, "int" )
 
				; ... to determine whether the pointer is over an item.
				If (hDroptarget := SendMessage_( this.hTreeview, TVM_HITTEST, 0, &tvht ))
				{
					; Only do stuff if the droptarget is different from the drag item
					If ( this.hDragitem != hDroptarget )
					{
						; To prevent infinite loops, first make sure "parent" isn't actually a 
						; descendant of node (it's like going back in time and becoming your own
						; great-grandfather: no good can come of it)
						If (!this.IsParentADescendant( this.hDragitem, hDroptarget ))
						{
							after := ""
							; 0 = dropped on target, 1 = before, 2 = after
							if (this.BeforeAfter = 2){
								parent := TV_GetParent(hDroptarget)
								after := hDroptarget
							} else if (this.BeforeAfter = 1) {
								parent := TV_GetParent(hDroptarget)
								after := TV_GetPrev(hDroptarget)
								after := after ? after : "First"
							} else {
								parent := hDroptarget
							}
							;OutputDebug % "Treeview_EndDrag: this.BeforeAfter: " this.BeforeAfter
							this.MoveNode(this.hDragitem, parent, after)
							;~ this.AddNodeToParent( this.hDragitem, parent, after )
							;~ TV_Modify( hDropTarget, "Expand" )
							;~ ;this.DeleteNode(this.hDragitem)
							;~ TV_Delete( node )
						}
					}				
				}
 
			; Set the dragging flag and dragitem handle to false		
			this.TV_is_dragging := 0, this.hDragitem := 0
		}
		OnMessage( 0x202, this.DragEndFn, 0 ) ; WM_LBUTTONUP
		OnMessage( 0x200, this.DragMidFn, 0 ) ; WM_MOUSEMOVE
	}
	
	IsParentADescendant( node, parent )
	{
		dlist := this.GetDescendantsList( node )
		Loop, parse, dlist, `,
			If ( A_LoopField = parent )
				return 1
		return 0
	}
 
	; Wheeeee! Recursion is fun!
	GetDescendantsList( node )
	{
		If ( kid := TV_GetChild( node ) )
		{
			kids .= kid . "," . this.GetDescendantsList( kid )
			While ( kid := TV_GetNext( kid ) )
				kids .= kid . "," . this.GetDescendantsList( kid )
		}
		return kids
	}
 
	; Moves a node to a new parent and/or set position amongst siblings
	; After param:	"First" = move to start
	;				<tv handle> = move after that item
	AddNodeToParent( node, parent, after := "" )
	{	
		TV_GetText( t, node)
		node_id := TV_Add( t, parent, "Expand " after  )
		If ( kid := TV_GetChild( node ) )
		{
			this.AddNodeToParent( kid, node_id )
			While ( kid := TV_GetNext( kid ) )
				this.AddNodeToParent( kid, node_id )
		}
		return node_id
	}
}

; =================================================================== PROFILE PICKER ==========================================================
; A tool for plugins that allows users to pick a profile (eg for a profile switcher plugin). Cannot alter profile tree
class _ProfilePicker extends _ProfileSelect {
	_CurrentCallback := 0
	TV_Event(){
		if (A_GuiEvent == "DoubleClick"){
			this._CurrentCallback.Call(this.LvHandleToProfileId[A_EventInfo])
			Gui, % this.hwnd ":Hide"
			this._CurrentCallback := 0
		}
	}
	
	PickProfile(callback, currentprofile){
		this._CurrentCallback := callback
		CoordMode, Mouse, Screen
		MouseGetPos, x, y
		this.BuildProfileTree()
		this.SelectProfileByID(currentprofile)
		Gui, % this.hwnd ":Show", % "x" x - 110 " y" y - 5, Profile Picker
	}
}

; =================================================================== BASE PROFILE TREE ==========================================================
; Creates a treeview that can parse UCR's profiles and display a treeview of them
class _ProfileSelect {
	__New(){
		Gui, New, HwndHwnd
		Gui +ToolWindow
		Gui +Resize
		this.hwnd := hwnd
		Gui, Add, TreeView, w200 h200 aw ah hwndhTreeview AltSubmit
		this.hTreeview := hTreeview
		;Gui, Show
		this.TV_EventFn := this.TV_Event.Bind(this)
		;this.BuildProfileTree()
	}
	
	TV_Event(){
		; Base class - override
	}
	
	Show(Callback){
		; Base class - override
	}
	
	; Builds the treeview GuiControl, and the lookup tables ProfileIdToLvHandle and LvHandleToProfileId
	; ... which convert to / from profile id / listview node handles
	BuildProfileTree(){
		Gui, % this.hwnd ":Default"
		Gui, TreeView, % this.hTreeview
		TV_Delete()
		fn := this.TV_EventFn
		GuiControl -g, % this.hTreeview, % fn
		
		this.ProfileIdToLvHandle := {}
		this.LvHandleToProfileId := {}
		; Iterate sparse ProfileTree array
		ctr := 0
		for parent, profiles in UCR.ProfileTree {
			ctr += profiles.length()
		}
		addedparents := {}
		while (ctr > 0){
			for parent, profiles in UCR.ProfileTree {
				; Ignore profiles whose parents have not yet been added to the tree.
				if (addedparents[parent] = 1 || (parent != 0 && !ObjHasKey(this.ProfileIdToLvHandle, parent)))
					continue
				addedparents[parent] := 1
				for i, id in profiles {
					this.AddProfileNode(UCR.Profiles[id], parent)
					ctr--
				}
			}
		}
		GuiControl +g, % this.hTreeview, % fn
	}
	
	AddProfileNode(profile, parent){
		Gui, % this.hwnd ":Default"
		Gui, TreeView, % this.hTreeview
		if (parent != 0){
			parent := this.ProfileIdToLvHandle[parent]
		}
		hnode := TV_Add(profile.Name, parent, "Expand")
		this.ProfileIdToLvHandle[profile.id] := hnode
		this.LvHandleToProfileId[hnode] := profile.id
	}
	
	; Select an item in the treeview from a profile ID
	SelectProfileByID(id){
		;Gui, % this.hwnd ":Default"
		;Gui, TreeView, % this.hTreeview
		static TVM_SELECTITEM := 0x110B, TVGN_CARET := 0x9
 
		fn := this.TV_EventFn
		GuiControl -g, % this.hTreeview, % fn
		SendMessage_( this.hTreeview, TVM_SELECTITEM, TVGN_CARET, this.ProfileIdToLvHandle[id] )
		GuiControl +g, % this.hTreeview, % fn
	}
	
	; Get the profile ID of the current selection in the treeview
	ProfileIDOfSelection(){
		Gui, % this.hwnd ":Default"
		Gui, TreeView, % this.hTreeview
		id := this.LvHandleToProfileId[TV_GetSelection()]
		return id
	}

}

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
	SetButtonBinding(BtnObj){
		; ToDo: Move building of bindstring inside thread? BuildHotkeyString is AHK input-specific, what about XINPUT?
		bindstring := this.BuildHotkeyString(BtnObj.value)
		; Set binding in Profile's InputThread
		BtnObj.ParentPlugin.ParentProfile._SetButtonBinding(ObjShare(BtnObj), bindstring )
		return 1
	}
	
	; Set an Axis Binding
	SetAxisBinding(AxisObj){
		AxisObj.ParentPlugin.ParentProfile._SetAxisBinding(ObjShare(AxisObj))
	}
	
	SetDeltaBinding(DeltaObj){
		DeltaObj.ParentPlugin.ParentProfile._SetDeltaBinding(ObjShare(DeltaObj))
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
		hk.ParentPlugin.ParentProfile._SetHotkeyState(state)
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
			; ToDo: don't do this check for axes
			; Suppress repeats option
			return
		}
		ipt.State := state
		if (IsObject(ipt.ChangeStateCallback)){
			ipt.ChangeStateCallback.Call(state)
			ipt.ParentPlugin.InputEvent(ipt, state)
		}
	}
	
	_DelayCallback(cb, state){
		cb.Call(state)
	}
	
}

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
	
	_Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
	,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
	,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
	,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	__New(){
		this._BindModeThread:=AhkThread(A_ScriptDir "\Threads\BindModeThread.ahk",,1) ; Loads the AutoHotkey module and starts the script.
		While !this._BindModeThread.ahkgetvar.autoexecute_done
			Sleep 50 ; wait until variable has been set.
		this._BindModeThread.ahkExec["BindMapper := new _BindMapper(" ObjShare(this._ProcessInput.Bind(this)) ")"]
		
		Gui, new, +HwndHwnd
		Gui +ToolWindow -Border
		this.hBindModePrompt := hwnd
		Gui, Add, Text, Center, Press the button(s) you wish to bind to this input.`n`nBind Mode will end when you release a key.
	}
	
	StartBindMode(hk, callback){
		this._callback := callback
		this._OriginalHotkey := hk
		
		this.SelectedBinding := 0
		this.BindMode := 1
		this.EndKey := 0
		this.HeldModifiers := {}
		this.ModifierCount := 0
		
		; When detecting an output, tell the Bind Handler to ignore physical joysticks...
		; ... as output cannot be "sent" to physical sticks
		this.SetHotkeyState(1, !hk._IsOutput)
	}
	
	; Turns on or off the hotkeys
	SetHotkeyState(state, enablejoystick := 1){
		if (state){
			Gui, % this.hBindModePrompt ":Show"
		} else {
			Gui, % this.hBindModePrompt ":Hide"
		}
		this._BindModeThread.ahkExec["BindMapper.SetHotkeyState(" state "," enablejoystick ")"]
	}
	
	; The BindModeThread calls back here
	_ProcessInput(e, type, code, deviceid){
		;OutputDebug % "e: " e ", type: " type ", code: " code ", deviceid: " deviceid
		; Build Key object and pass to ProcessInput
		i := new _Button({type: type, code: code, deviceid: deviceid})
		this.ProcessInput(i,e)
	}
	
	; Called when a key was pressed
	ProcessInput(i, e){
		if (!this.BindMode)
			return
		if (i.type > 1){
			is_modifier := 0
		} else {
			is_modifier := i.IsModifier()
			; filter repeats
			;if (e && (is_modifier ? ObjHasKey(HeldModifiers, i.code) : EndKey) )
			if (e && (is_modifier ? ObjHasKey(this.HeldModifiers, i.code) : i.code = this.EndKey.code) )
				return
		}

		;~ ; Are the conditions met for end of Bind Mode? (Up event of non-modifier key)
		;~ if ((is_modifier ? (!e && ModifierCount = 1) : !e) && (i.type > 1 ? !ModifierCount : 1) ) {
		; Are the conditions met for end of Bind Mode? (Up event of any key)
		if (!e){
			; End Bind Mode
			this.BindMode := 0
			this.SetHotkeyState(0)
			bindObj := this._OriginalHotkey.value.clone()
			
			bindObj.Buttons := []
			for code, key in this.HeldModifiers {
				bindObj.Buttons.push(key)
			}
			
			bindObj.Buttons.push(this.EndKey)
			bindObj.Type := this.EndKey.Type
			this._Callback.(this._OriginalHotkey, bindObj)
			
			return
		} else {
			; Process Key Up or Down event
			if (is_modifier){
				; modifier went up or down
				if (e){
					this.HeldModifiers[i.code] := i
					this.ModifierCount++
				} else {
					this.HeldModifiers.Delete(i.code)
					this.ModifierCount--
				}
			} else {
				; regular key went down or up
				if (i.type > 1 && this.ModifierCount){
					; Reject joystick button + modifier - AHK does not support this
					if (e)
						SoundBeep
				} else if (e) {
					; Down event of non-modifier key - set end key
					this.EndKey := i
				}
			}
		}
		
		; Mouse Wheel u/d/l/r has no Up event, so simulate it to trigger it as an EndKey
		if (e && (i.code >= 156 && i.code <= 159)){
			this.ProcessInput(i, 0)
		}
	}
}

; ======================================================================== PROFILE ===============================================================
; The Profile class handles everything to do with Profiles.
; It has it's own GUI (this.hwnd), which is parented to the main GUI.
; The Profile's is parent to 0 or more plugins, which are each an instance of the _Plugin class.
; The Gui of each plugin appears inside the Gui of this profile.
Class _Profile {
	Name := ""
	ParentProfile := 0
	Plugins := {}
	PluginOrder := []
	AssociatedApss := 0
	PluginStateSubscriptions := {}
	_IsGlobal := 0
	
	__New(id, name, parent){
		static fn
		this.ID := id
		this.Name := name
		this.ParentProfile := parent
		if (this.Name = "global"){
			this._IsGlobal := 1
		}
		FileRead, Script, % A_ScriptDir "\Threads\ProfileInputThread.ahk"
		this._InputThread := AhkThread("InputThread := new _InputThread(" ObjShare(UCR._InputHandler.InputEvent.Bind(UCR._InputHandler)) ")`n" Script)
		While !this._InputThread.ahkgetvar.autoexecute_done
			Sleep 50 ; wait until variable has been set.
		; Get thread-safe boundfunc object for thread's SetHotkeyState
		this._SetHotkeyState := ObjShare(this._InputThread.ahkgetvar("_InterfaceSetHotkeyState"))
		this._SetButtonBinding := ObjShare(this._InputThread.ahkgetvar("_InterfaceSetButtonBinding"))
		this._SetAxisBinding := ObjShare(this._InputThread.ahkgetvar("_InterfaceSetAxisBinding"))
		this._SetDeltaBinding := ObjShare(this._InputThread.ahkgetvar("_InterfaceSetDeltaBinding"))
		this._CreateGui()
	}
	
	__Delete(){
		Gui, % this.hwnd ":Destroy"
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
		Gui, % UCR.hwnd ":Add", Gui, % "x0 y" UCR.TOP_PANEL_HEIGHT " w" UCR.PLUGIN_FRAME_WIDTH " ah h" UCR.GUI_MIN_HEIGHT - UCR.TOP_PANEL_HEIGHT, % this.hwnd
		Gui, % hOld ":Default"	; Restore previous default Gui
	}
	
	; The profile became active
	_Activate(){
		this._SetHotkeyState(1)
		Loop % this.PluginOrder.length() {
			plugin := this.Plugins[this.PluginOrder[A_Index]]
			if (IsFunc(plugin["OnActive"])){
				plugin.OnActive()
			}
		}
	}
	
	; The profile went inactive
	_DeActivate(){
		this._SetHotkeyState(0)
		Loop % this.PluginOrder.length() {
			plugin := this.Plugins[this.PluginOrder[A_Index]]
			plugin._OnInactive()
		}
	}
	
	; Show the GUI
	_Show(){
		Gui, % this.hwnd ":Show"
	}
	
	; Hide the GUI
	_Hide(){
		Gui, % this.hwnd ":Hide"
	}
	
	; User clicked Add Plugin button
	_AddPlugin(){
		GuiControlGet, idx, % UCR.hTopPanel ":", % UCR.hPluginSelect
		plugin := UCR.PluginDetails[UCR.PluginList[idx]].ClassName
		name := this._GetUniqueName(plugin)
		if (name = 0)
			return
		this.PluginOrder.push(name)
		this.Plugins[name] := new %plugin%(this, name)
		this.Plugins[name].Type := plugin
		this._LayoutPlugin()
		UCR._ProfileChanged(this)
		if (IsFunc(this.Plugins[name, "OnActive"]))
			this.Plugins[name].OnActive()
	}
	
	; Layout a plugin.
	; Pass PluginOrder index to lay out, or leave blank to lay out last plugin
	_LayoutPlugin(index := -1){
		static SCROLLINFO:="UINT cbSize;UINT fMask;int  nMin;int  nMax;UINT nPage;int  nPos;int  nTrackPos"
				,scroll:=Struct(SCROLLINFO,{cbSize:sizeof(SCROLLINFO),fMask:4})
		GetScrollInfo(this.hwnd,true,scroll[])
		i := (index = -1 ? this.PluginOrder.length() : index)
		name := this.PluginOrder[i]
		y := 0
		if (i > 1){
			ControlGetPos,,wy,,,,% "ahk_id " this.hwnd
			prev := this.PluginOrder[i-1]
			ControlGetPos,,y,,h,,% "ahk_id " this.Plugins[prev].hFrame
			y += h - wy
		}
		y += 5 - (index=-1 ? 0 : scroll.nPos)
		Gui, % this.Plugins[name].hFrame ":Show", % "x5 y" y " w" UCR.PLUGIN_WIDTH
		ControlGetPos, , , , h, , % "ahk_id " this.Plugins[name].hFrame
		GuiControl, Move, % this.hSpacer, % "h" y + h + scroll.nPos
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
	
	; Delete a plugin
	_RemovePlugin(plugin){
		ControlGetPos, , , , height_frame, ,% "ahk_id " plugin.hFrame
		Gui, % plugin.hwnd ":Destroy"
		Gui, % plugin.hFrame ":Destroy"
		Loop % this.PluginOrder.length(){
			if (this.PluginOrder[A_Index] = plugin.name){
				this.PluginOrder.RemoveAt(A_Index)
				break
			}
		}
		
		ControlGetPos, , , , height_spacer, ,% "ahk_id " this.hSpacer
		GuiControl, Move, % this.hSpacer, % "h" height_spacer - height_frame
		this.Plugins.Delete(plugin.name)
		this._PluginChanged(plugin)
		this._LayoutPlugins()
	}
	
	; Obtain a profiel-unique name for the plugin
	_GetUniqueName(name){
		name .= " "
		num := 1
		while (ObjHasKey(this.Plugins, name num)){
			num++
		}
		name := name num
		prompt := "Enter a name for the Plugin"
		Loop {
			InputBox, name, Add Plugin, % prompt, ,,130,,,,, % name
			if (!ErrorLevel){
				if (ObjHasKey(this.Plugins, Name)){
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
	
	; Save the profile to disk
	_Serialize(){
		obj := {Name: this.Name}
		obj.ParentProfile := this.ParentProfile
		obj.Plugins := {}
		obj.PluginOrder := this.PluginOrder
		for name, plugin in this.Plugins {
			obj.Plugins[name] := plugin._Serialize()
		}
		return obj
	}
	
	; Load the profile from disk
	_Deserialize(obj){
		this.ParentProfile := obj.ParentProfile
		Loop % obj.PluginOrder.length() {
			name := obj.PluginOrder[A_Index]
			this.PluginOrder.push(name)
			plugin := obj.Plugins[name]
			cls := plugin.Type
			if (!IsObject(%cls%)){
				msgbox % "Plugin class " cls " not found - removing from profile """ this.Name """"
				this.PluginOrder.Pop()
				obj.Plugins.Delete(name)
				continue
			}
			this.Plugins[name] := new %cls%(this, name)
			this.Plugins[name]._Deserialize(plugin)
			this._LayoutPlugin()
		}
	}

	_PluginChanged(plugin){
		OutputDebug % "Profile " this.Name " --> UCR"
		UCR._ProfileChanged(this)
	}
	
	; Plugin authors can call this to allow a plugin to be notified whenever an Input in any other plugin in this profile changes state
	; This is primarily used for temporal plugins
	SubscribeToStateChange(plugin, callback){
		if (!ObjHasKey(this.PluginStateSubscriptions, plugin.Name)){
			this.PluginStateSubscriptions[plugin.Name] := callback
		}
	}
	
	InputEvent(ipt, state){
		for name, callback in this.PluginStateSubscriptions {
			callback.Call(ipt, state)
		}
	}
	
}

; ======================================================================== PLUGIN ===============================================================
; The _Plugin class itself is never instantiated.
; Instead, plugins derive from the base _Plugin class.
Class _Plugin {
	Type := "_Plugin"			; The class of the plugin
	ParentProfile := 0			; Will point to the parent profile
	Name := ""					; The name the user chose for the plugin
	GuiControls := {}			; An associative array, indexed by name, of child GuiControls
	InputButtons := {}			; An associative array, indexed by name, of child Input Buttons (aka Hotkeys)
	InputDeltas := {}
	OutputButtons := {}			; An associative array, indexed by name, of child Output Buttons
	InputAxes := {}				; An associative array, indexed by name, of child Input Axes
	OutputAxes := {}			; An associative array, indexed by name, of child Output (virtual) Axes
	_SerializeList := ["GuiControls", "InputButtons", "InputDeltas", "OutputButtons", "InputAxes", "OutputAxes"]
	
	; Override this class in your derived class and put your Gui creation etc in here
	Init(){
		
	}

	; === Plugins can call these commands to add various GuiControls to their Gui ===
	; Adds a GuiControl that allows the end-user to choose a value, often used to configure the script
	AddControl(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.GuiControls, name)){
			this.GuiControls[name] := new _GuiControl(this, name, ChangeValueCallback, aParams*)
			return this.GuiControls[name]
		}
	}
	
	; Adds a GuiControl that allows the end-user to pick Button(s) to use as Input(s)
	AddInputButton(name, ChangeValueCallback, ChangeStateCallback, aParams*){
		if (!ObjHasKey(this.InputButtons, name)){
			this.InputButtons[name] := new _InputButton(this, name, ChangeValueCallback, ChangeStateCallback, aParams*)
			return this.InputButtons[name]
		}
	}
	
	; Adds a GuiControl that allows the end-user to pick an Axis to be used as an input
	AddInputAxis(name, ChangeValueCallback, ChangeStateCallback, aParams*){
		if (!ObjHasKey(this.InputAxes,name)){
			this.InputAxes[name] := new _InputAxis(this, name, ChangeValueCallback, ChangeStateCallback, aParams*)
			return this.InputAxes[name]
		}
	}
	
	AddInputDelta(name, ChangeStateCallback, aParams*){
		if (!ObjHasKey(this.InputDeltas,name)){
			this.InputDeltas[name] := new _InputDelta(this, name, ChangeStateCallback, aParams*)
			return this.InputDeltas[name]
		}
	}
	
	; Adds a GuiControl that allows the end-user to pick Button(s) to be used as output(s)
	AddOutputButton(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.OutputButtons, name)){
			this.OutputButtons[name] := new _OutputButton(this, name, ChangeValueCallback, aParams*)
			return this.OutputButtons[name]
		}
	}

	; Adds a GuiControl that allows the end-user to pick an Axis to be used as an output
	AddOutputAxis(name, ChangeValueCallback, aParams*){
		if (!ObjHasKey(this.OutputAxes,name)){
			this.OutputAxes[name] := new _OutputAxis(this, name, ChangeValueCallback, aParams*)
			return this.OutputAxes[name]
		}
	}
	
	; An input in this plugin changed state. This happens after the ChangeStateCallback is fired.
	InputEvent(ipt, state){
		this.ParentProfile.InputEvent(ipt, state)
	}
	
	; === Private ===
	__New(parent, name){
		this.ParentProfile := parent
		this.Name := name
		this._CreateGui()
		this.Init()
		this._ParentGuis()
	}
	
	__Delete(){
		OutputDebug % "Plugin " this.name " in profile " this.ParentProfile.name " fired destructor"
	}
	
	; Initialize the GUI
	; Plugin controls will be added straight afterwards
	_CreateGui(){
		Gui, new, HwndHwnd
		this.hwnd := hwnd
		Gui -Caption
		;Gui, Color, 0000FF
	}
	
	; Add the chrome around the plugin, then add the plugin to the parent
	_ParentGuis(){
		Gui, new, HwndHwnd
		this.hFrame := hwnd
		Gui, Margin, 0, 0
		Gui -Caption
		Gui, Color, 7777FF
		Gui, Add, Button, % "hwndhClose y3 x" UCR.PLUGIN_WIDTH - 23, X
		Gui, Font, s15, Verdana
		Gui, Add, Text, % "hwndhTitle x5 y3 w" UCR.PLUGIN_WIDTH - 40, % this.Name
		this._hTitle := hTitle
		fn := this._Close.Bind(this)
		GuiControl, +g, % hClose, % fn
		Gui, % this.hwnd ":Show", % "w" UCR.PLUGIN_WIDTH
		Gui, % this.hFrame ":Add", Gui, x0 y30, % this.hwnd
		Gui, % this.hFrame ":+Parent" this.ParentProfile.hwnd
	}

	; A GuiControl / Hotkey changed
	_ControlChanged(ctrl){
		OutputDebug % "Plugin " this.Name " --> Profile"
		this.ParentProfile._PluginChanged(this)
	}
	
	; Save plugin to disk
	_Serialize(){
		obj := {Type: this.Type}
		Loop % this._SerializeList.length(){
			key := this._SerializeList[A_Index]
			obj[key] := {}
			for name, ctrl in this[key] {
				obj[key, name] := ctrl._Serialize()
			}
		}
		return obj
	}
	
	; Load plugin from disk
	_Deserialize(obj){
		this.Type := obj.Type
		Loop % this._SerializeList.length(){
			key := this._SerializeList[A_Index]
			for name, ctrl in obj[key] {
				this[key, name]._Deserialize(ctrl)
			}
		}
	}
	
	; Called when a plugin becomes inactive (eg profile changed)
	_OnInActive(){
		for k, v in this.OutputButtons{
			if (v.State == 1)
				v.SetState(0)
		}
		; Call user's OnInactive method (if it exists)
		if (IsFunc(this["OnInactive"])){
			plugin.OnInactive()
		}
	}
	
	; The plugin was closed (deleted)
	_Close(){
		; ToDo: These should call UCR.RequestXxxBinding, as bindings were added that way
		; Call plugin's OnDelete method, if it exists
		if (IsFunc(this["OnDelete"])){
			this.OnDelete()
		}
		; Remove input bindings etc here
		; Some attempt is also made to free resources so destructors fire, though this is a WIP
		for name, obj in this.InputButtons {
			this.ParentProfile._SetButtonBinding(ObjShare(obj))
			obj._KillReferences()
		}
		for Name, obj in this.InputAxes {
			this.ParentProfile._SetAxisBinding(ObjShare(obj),1)
			obj._KillReferences()
		}
		for name, obj in this.OutputButtons {
			obj._KillReferences()
		}
		for name, obj in this.InputDeltas {
			this.ParentProfile._SetDeltaBinding(ObjShare(obj),1)
			obj._KillReferences()
		}
		for name, obj in this.OutputAxes {
			obj._KillReferences()
		}
		for name, obj in this.GuiControls {
			obj._KillReferences()
		}
		this.ParentProfile._RemovePlugin(this)
		try {
			this._KillReferences()
		}
		this.InputButtons := this.OutputButtons := this.GuiControls := ""
	}
}

; ======================================================================== GUICONTROL ===============================================================
; Wraps a GuiControl to make it's value persistent between runs.
class _GuiControl {
	__value := ""	; variable that actually holds value. ._value and .__value handled by Setters / Getters
	__New(parent, name, ChangeValueCallback, aParams*){
		this.ParentPlugin := parent
		this.Name := name
		this.ControlType := aParams[1]
		; Detect what kind of GuiControl this is, so that later operations (eg set of value) work as intended.
		; Decide whether the control type is a "List" type: ListBox, DropDownList (ddl), ComboBox, and Tab (and tab2?)
		if (aParams[1] = "listbox" ||aParams[1] = "ddl" || aParams[1] = "dropdownlist" || aParams[1] = "combobox" || aParams[1] = "tab" || aParams[1] = "tab2"){
			this.IsListType := 1
			; Detect if this List Type uses AltSubmit
			if (InStr(aParams[2], "altsubmit"))
				this.IsAltSubmitType := 1
			else 
				this.IsAltSubmitType := 0
		} else {
			this.IsListType := 0
			this.IsAltSubmitType := 0
		}
		; Set which (internal) function gets called when the control changes value 
		this.ChangeValueFn := this._ChangedValue.Bind(this)
		; Store the user's callback that is to be fired when the Control changes value
		this.ChangeValueCallback := ChangeValueCallback
		; Add the Control
		Gui, % this.ParentPlugin.hwnd ":Add", % aParams[1], % "hwndhwnd " aParams[2], % aParams[3]
		this.hwnd := hwnd
		; Set default value - get this from state of GuiControl before any loading of settings is done
		GuiControlGet, value, % this.ParentPlugin.hwnd ":", % this.hwnd
		this.__value := value
		; Turn on the gLabel
		this._SetGlabel(1)
		
		; Fire ChangeValueCallback so that any variables that depend on GuiControl values can be initialized
		if (IsObject(ChangeValueCallback))
			ChangeValueCallback.Call(value)
	}
	
	__Delete(){
		OutputDebug % "GuiControl " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	_KillReferences(){
		this._SetGlabel(0)
		this.ChangeValueFn := ""
		this.ChangeValueCallback := ""
	}
	
	; Turns on or off the g-label for the GuiControl
	; This is needed to work around not being able to programmatically set GuiControl without triggering g-label
	_SetGlabel(state){
		if (state){
			fn := this.ChangeValueFn
			GuiControl, % this.ParentPlugin.hwnd ":+g", % this.hwnd, % fn
		} else {
			GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		}
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
			this.__value := value
			OutputDebug % "GuiControl " this.Name " --> Plugin"
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
			this._SetGlabel(0)						; Turn off g-label to avoid triggering save
			cmd := ""
			if (this.IsListType){
				cmd := (this.IsAltSubmitType ? "choose" : "choosestring")
			}
			GuiControl, % cmd, % this.hwnd, % value
			this._SetGlabel(1)						; Turn g-label back on
		}
	}
	
	; The user typed something into the GuiControl
	_ChangedValue(){
		GuiControlGet, value, % this.ParentPlugin.hwnd ":", % this.hwnd
		this.value := value		; Set control value and fire change events to parent
		; If the script author defined a callback for onchange event of this GuiControl, then fire it
		if (IsObject(this.ChangeValueCallback)){
			this.ChangeValueCallback.Call(value)
		}
	}
	
	_Serialize(){
		obj := {value: this._value}
		return obj
	}
	
	_Deserialize(obj){
		this._value := obj.value
		; Fire callback so plugins can initialize internal vars
		if (IsObject(this.ChangeValueCallback)){
			this.ChangeValueCallback.Call(obj.value)
		}
	}
}

; ======================================================================== BANNER COMBO ===============================================================
; Wraps a ComboBox GuiControl to turn it into a DDL with a "Cue Banner" 1st item, that is re-selected after every choice.
class _BannerCombo {
	__New(ParentHwnd, aParams*){
		this._ParentHwnd := ParentHwnd
		this._Ptr := &this
		Gui, % this._ParentHwnd ":Add", % "Combobox", % "hwndhwnd " aParams[1], % aParams[2]
		this.hwnd := hwnd
		
		fn := this.__ChangedValue.Bind(this)
		GuiControl, % this._ParentHwnd ":+g", % this.hwnd, % fn
		
		; Get Hwnd of EditBox part of ComboBox
		this._hEdit := DllCall("GetWindow","PTR",this.hwnd,"Uint",5) ;GW_CHILD = 5
		
		; == Hack to stop Mouse Wheel changing option when the control is focused.
		; ToDo: Find better solution (Probably involves changing AHK_H source code)
		; In a scrolling environment, this is really annoying.
		; Not the best solution, as if you scroll while the list is open, the list doesn't move.
		; Get the position of the Editbox
		ControlGetPos,x,y,,,,% "ahk_id " this._hEdit
		; Set the parent of the editbox to the main Gui instead of the Combobox
		DllCall("SetParent","PTR",this._hEdit,"PTR",this._ParentHwnd)
		; Move the Editbox back to where it should be
		ControlMove,,% x,% y,,,% "ahk_id " this._hEdit
		; == End Hack
	}
	
	; Pass an array of strings to set available options
	SetOptions(opts){
		str := "|", max := opts.length()
		Loop % max{
			str .= opts[A_Index]
			if (A_Index != max){
				str .= "|"
			}
		}
		GuiControl,% this._ParentHwnd ":" , % this.hwnd, % str
	}
	
	; Sets the text of the Cue Banner
	SetCueBanner(text){
		static EM_SETCUEBANNER:=0x1501
		DllCall("User32.dll\SendMessageW", "Ptr", this._hEdit, "Uint", EM_SETCUEBANNER, "Ptr", True, "WStr", text)
	}
	
	; The control changed through user interaction
	__ChangedValue(){
		; Find index of dropdown list. Will be really big number if text was typed into the Editbox
		SendMessage 0x147, 0, 0,, % "ahk_id " this.hwnd  ; CB_GETCURSEL
		o := ErrorLevel
		; Reset DDL to position 0 (The "Cue Banner")
		GuiControl, % this._ParentHwnd ":Choose", % this.hwnd, 0
		; Filter typed text
		if (o < 100){
			o++
			this._ChangedValue(o)
		}
	}
	
	; Override
	_ChangedValue(o){
		
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
	_DefaultBanner := "Drop down the list to select a binding"
	_OptionMap := {Select: 1, Wild: 2, Block: 3, Suppress: 4, Clear: 5}
	
	__New(parent, name, ChangeValueCallback, ChangeStateCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
		this.__value := new _BindObject()
		this.SetComboState()
	}
	
	__Delete(){
		OutputDebug % "Hotkey " this.name " in plugin " this.ParentPlugin.name " fired destructor"
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
			OutputDebug % "Hotkey " this.Name " --> Plugin"
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

	; Builds the list of options in the DropDownList
	_BuildOptions(){
		opts := []
		this._CurrentOptionMap := [this._OptionMap["Select"]]
		opts.push("Select New Binding")
		if (this.__value.Type = 1){
			; Joystick buttons do not have these options
			opts.push("Wild: " (this.__value.wild ? "On" : "Off"))
			this._CurrentOptionMap.push(this._OptionMap["Wild"])
			opts.push("Block: " (this.__value.block ? "On" : "Off"))
			this._CurrentOptionMap.push(this._OptionMap["Block"])
			opts.push("Suppress Repeats: " (this.__value.suppress ? "On" : "Off"))
			this._CurrentOptionMap.push(this._OptionMap["Suppress"])
		}
		opts.push("Clear Binding")
		this._CurrentOptionMap.push(this._OptionMap["Clear"])
		this.SetOptions(opts)
	}

	; Set the state of the GuiControl (Inc Cue Banner)
	SetComboState(){
		this._BuildOptions()
		if (this.__value.Buttons.length()) {
			Text := this.__value.BuildHumanReadable()
		} else {
			Text := this._DefaultBanner			
		}
		this.SetCueBanner(Text)
	}
	
	; An option was selected from the list
	_ChangedValue(o){
		if (o){
			o := this._CurrentOptionMap[o]
			
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
	
	_Serialize(){
		return this.__value._Serialize()
	}
	
	_Deserialize(obj){
		; Trigger _value setter to set gui state but not fire change event
		this._value := new _BindObject(obj)
		; Register hotkey on load
		UCR._InputHandler.SetButtonBinding(this)
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
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		this.ChangeStateCallback := ChangeStateCallback
		
		this._Options := []
		Loop 6 {
			this._Options.push("Axis " A_Index " (" this.AHKAxisList[A_Index] ")" )
		}
		Loop 8 {
			;this._Options.push("Stick " A_Index )
			;~ this._Options.push(A_Index ": " DllCall("JoystickOEMName\joystick_OEM_name", double,A_Index, "CDECL AStr"))
			this._Options.push(A_Index ": " joystick_OEM_name(A_Index))
		}
		this._Options.push("Clear Binding")
		this.SetComboState()
	}
	
	; The Axis Select DDL changed value
	_ChangedValue(o){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		
		; Resolve result of selection to index of full option list
		o := this._OptionMap[o]
		
		if (o <= 6){
			; Axis Selected
			axis := o
		} else if (o <= 14){
			; Stick Selected
			o -= 6
			DeviceID := o
		} else {
			; Clear Selected
			axis := DeviceID := 0
		}
		this.__value.Axis := axis
		this.__value.DeviceID := DeviceID
		this.SetComboState()
		this.value := this.__value
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
			str := "Pick a Stick"
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
			OutputDebug % "GuiControl " this.Name " --> Plugin"
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
		UCR.RequestAxisBinding(this)
	}
}

; ======================================================================== INPUT DELTA ===============================================================
; An input that reads delta move information from the mouse
class _InputDelta {
	__New(parent, name, ChangeStateCallback, aParams*){
		this._Ptr := &this
		this.ChangeStateCallback := ChangeStateCallback
		this.ParentPlugin := parent
		this.Name := name
		this.hwnd := parent.hwnd	; no gui for this input, so use hwnd of parent for unique id
		this.value := 0
	}

	Register(){
		this.value := 1
		UCR.RequestDeltaBinding(this)
	}
	
	UnRegister(){
		this.value := 0
		UCR.RequestDeltaBinding(this)
	}
	
	_Serialize(){
		obj := {value: this.value}
		return obj
	}
	
	_Deserialize(obj){
		this.value := obj.value
	}
}

; ======================================================================== OUTPUT BUTTON ===============================================================
; An Output allows the end user to specify which buttons to press as part of a plugin's functionality
Class _OutputButton extends _InputButton {
	_DefaultBanner := "Drop down the list to select an Output"
	_IsOutput := 1
	_OptionMap := {Select: 1, vJoyButton: 2, Clear: 3}
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent, name, ChangeValueCallback, 0, aParams*)
		; Create Select vJoy Button / Hat Select GUI
		Gui, new, HwndHwnd
		Gui -Border
		this.hVjoySelect := hwnd
		Gui, Add, Text, w50 xm Center, vJoy Stick
		Gui, Add, Text, w50 xp+55 Center, Button
		Gui, Add, Text, w50 xp+55 Center, Hat
		Gui, Add, ListBox, R11 xm w50 AltSubmit HwndHwnd , None||1|2|3|4|5|6|7|8
		this.hVjoyDevice := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "dev")
		GuiControl +g, % hwnd, % fn
		Gui, Add, ListBox, R11 w50 xp+55 AltSubmit HwndHwnd , None||01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|39|40|41|42|43|44|45|46|47|48|49|50|51|52|53|54|55|56|57|58|59|60|61|62|63|64|65|66|67|68|69|70|71|72|73|74|75|76|77|78|79|80|81|82|83|84|85|86|87|88|89|90|91|92|93|94|95|96|97|98|99|100|101|102|103|104|105|106|107|108|109|110|111|112|113|114|115|116|117|118|119|120|121|122|123|124|125|126|127|128|
		this.hVJoyButton := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "but")
		GuiControl +g, % hwnd, % fn
		Gui, Add, ListBox, R5 w50 xp+55 AltSubmit HwndHwnd , None||Hat 1|Hat 2|Hat 3|Hat 4
		this.hVJoyHatNumber := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "hn")
		GuiControl +g, % hwnd, % fn
		Gui, Add, ListBox, R5 w50 xp y+9 AltSubmit HwndHwnd , None||Up|Right|Down|Left
		this.hVJoyHatDir := hwnd
		fn := this.vJoyOptionSelected.Bind(this, "hd")
		GuiControl +g, % hwnd, % fn
		Gui, Add, Button, xm w75 Center HwndHwnd, Cancel
		this.hVJoyCancel := hwnd
		fn := this.vJoyInputCancelled.Bind(this)
		GuiControl +g, % this.hVJoyCancel, % fn
		Gui, Add, Button, xp+85 w75 Center HwndHwnd, Ok
		this.hVjoyOK := hwnd
		fn := this.vJoyOutputSelected.Bind(this)
		GuiControl +g, % this.hVjoyOK, % fn
	}
	
	; Builds the list of options in the DropDownList
	_BuildOptions(){
		opts := []
		this._CurrentOptionMap := [this._OptionMap["Select"]]
		opts.push("Select New Keyboard / Mouse Output")
		this._CurrentOptionMap.push(this._OptionMap["vJoyButton"])
		opts.push("Select New vJoy Button / Hat")
		this._CurrentOptionMap.push(this._OptionMap["Clear"])
		opts.push("Clear Output")
		this.SetOptions(opts)
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
					; ToDo: Make hat number selection actually work
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
			o := this._CurrentOptionMap[o]
			
			; Option selected from list
			if (o = 1){
				; Bind
				UCR._RequestBinding(this)
				return
			} else if (o = 2){
				; vJoy
				this._SelectvJoy()
			} else if (o = 3){
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
	
	; Present a menu to allow the user to select vJoy output
	_SelectvJoy(){
		Gui, % this.hVjoySelect ":Show"
		dev := this.__value.Buttons[1].DeviceId + 1
		GuiControl, % this.hVjoySelect ":Choose", % this.hVjoyDevice, % dev
		if (this.__value.Buttons[1].Type >= 3){
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatNumber, % this.__value.Buttons[1].Type - 1
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatDir, % this.__value.Buttons[1].code + 1
		} else {
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyButton, % this.__value.Buttons[1].code + 1
		}
	}
	
	vJoyOptionSelected(what){
		GuiControlGet, dev, % this.hVjoySelect ":" , % this.hVjoyDevice
		dev--
		GuiControlGet, but, % this.hVjoySelect ":" , % this.hVJoyButton
		but--
		GuiControlGet, hn, % this.hVjoySelect ":" , % this.hVJoyHatNumber
		hn--
		GuiControlGet, hd, % this.hVjoySelect ":" , % this.hVJoyHatDir
		hd--
		if (what = "but" && but){
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatNumber, 1
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyHatDir, 1
		} else if (what != "dev" && %what%){
			GuiControl, % this.hVjoySelect ":Choose", % this.hVJoyButton, 1
		}
	}
	
	vJoyOutputSelected(){
		Gui, % this.hVjoySelect ":Submit"
		GuiControlGet, device, % this.hVjoySelect ":" , % this.hVjoyDevice
		device--
		GuiControlGet, button, % this.hVjoySelect ":" , % this.hVJoyButton
		button--
		GuiControlGet, hn, % this.hVjoySelect ":" , % this.hVJoyHatNumber
		hn--
		GuiControlGet, hd, % this.hVjoySelect ":" , % this.hVJoyHatDir
		hd--
		
		bo := new _BindObject()
		
		if (device && button){
			t := 2
		} else if (device && hn && hd) {
			t := 2 + hn
		} else {
			return
		}
		bo.Type := t
		
		key := new _Button()
		key.DeviceID := device
		if (t = 2)
			key.code := button
		else
			key.code := hd
		key.IsVirtual := 1
		key.Type := t
		
		bo.Buttons := [key]
		this.value := bo
	}
	
	vJoyInputCancelled(){
		Gui, % this.hVjoySelect ":Submit"
	}

	_Deserialize(obj){
		; Trigger _value setter to set gui state but not fire change event
		this._value := new _BindObject(obj)
	}
	
	__Delete(){
		OutputDebug % "Output " this.name " in plugin " this.ParentPlugin.name " fired destructor"
	}
	
	; Kill references so destructor can fire
	_KillReferences(){
		base._KillReferences()
		;~ GuiControl, % this.ParentPlugin.hwnd ":-g", % this.hwnd
		;~ this.ChangeValueCallback := ""
		;~ this.ChangeStateCallback := ""
	}
}

; ======================================================================== OUTPUT AXIS ===============================================================
class _OutputAxis extends _BannerCombo {
	;__value := {DeviceID: 0, axis: 0}
	__value := new _Axis()
	vJoyAxisList := ["X", "Y", "Z", "Rx", "Ry", "Rz", "S1", "S2"]
	__New(parent, name, ChangeValueCallback, aParams*){
		base.__New(parent.hwnd, aParams*)
		this.ParentPlugin := parent
		this.Name := name
		this.ChangeValueCallback := ChangeValueCallback
		
		this._Options := []
		Loop 8 {
			this._Options.push("Axis " A_Index " (" this.vJoyAxisList[A_Index] ")" )
		}
		Loop 8 {
			this._Options.push("vJoy Stick " A_Index )
		}
		this._Options.push("Clear Binding")
		this.SetComboState()
	}
	
	; Plugin Authors call this to set the state of the output axis
	SetState(state, delay_done := 0){
		if (UCR._CurrentState == 2 && !delay_done){
			; In GameBind Mode - delay output.
			; Call this method again, but pass 1 to delay_done
			fn := this.SetState.Bind(this, state, 1)
			SetTimer, % fn, % -UCR._GameBindDuration
		} else {
			this.State := state
			UCR.Libraries.vJoy.Devices[this.__value.DeviceID].SetAxisByIndex(state, this.__value.Axis)
			;UCR.Libraries.vJoy.SetAxis(state, this.__value.DeviceID, this.__value.Axis)
		}
	}
	
	SetComboState(){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		this._OptionMap := []
		opts := []
		if (DeviceID){
			; Show Sticks and Axes
			max := 16
			index_offset := 0
			if (!Axis)
				str := "Pick an Axis (Stick " DeviceID ")"
		} else {
			str := "Pick a virtual Stick"
			max := 10
			index_offset := 8
		}
		Loop % max {
			map_index := A_Index + index_offset
			if (map_index > 8 && map_index <= 16){
				if (!UCR.Libraries.vJoy.Devices[map_index - 8].IsAvailable()){
					continue
				}
			}
			opts.push(this._Options[map_index])
			this._OptionMap.push(map_index)
		}
		if (DeviceID || axis){
			opts.push(this._Options[17])
			this._OptionMap.push(17)
		}

		if (DeviceID && Axis)
			str := "Stick " DeviceID ", Axis " axis " (" this.vJoyAxisList[axis] ")"
		
		this.SetOptions(opts)
		this.SetCueBanner(str)
	}
	
	_ChangedValue(o){
		axis := this.__value.Axis
		DeviceID := this.__value.DeviceID
		
		; Resolve result of selection to index of full option list
		o := this._OptionMap[o]
		
		if (o <= 8){
			; Axis Selected
			axis := o
		} else if (o <= 16){
			; Stick Selected
			o -= 8
			DeviceID := o
		} else {
			; Clear Selected
			axis := DeviceID := 0
		}
		this.__value.Axis := axis
		this.__value.DeviceID := DeviceID
		
		this.SetComboState()
		this.value := this.__value
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
			OutputDebug % "GuiControl " this.Name " --> Plugin"
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
	}

}
; ======================================================================== BINDOBJECT ===============================================================
; A BindObject represents a collection of keys / mouse / joystick buttons
class _BindObject {
	Type := 0 ; 0 = Unset, 1 = Key / Mouse, 2 = stick button, 3 = stick hat
	Buttons := []
	Wild := 0
	Block := 0
	Suppress := 0
	
	__New(obj){
		this._Deserialize(obj)
	}
	
	_Serialize(){
		obj := {Buttons: [], Wild: this.Wild, Block: this.Block, Suppress: this.Suppress, Type: this.Type}
		Loop % this.Buttons.length(){
			obj.Buttons.push(this.Buttons[A_Index]._Serialize())
		}
		return obj
	}
	
	_Deserialize(obj){
		for k, v in obj {
			if (k = "Buttons"){
				Loop % v.length(){
					this.Buttons.push(new _Button(v[A_Index]))
				}
			} else {
				this[k] := v
			}
		}
	}
	
	; Builds a human-readable form of the BindObject
	BuildHumanReadable(){
		max := this.Buttons.length()
		str := ""
		Loop % max {
			str .= this.Buttons[A_Index].BuildHumanReadable()
			if (A_Index != max)
				str .= " + "
		}
		return str
	}
}

; ======================================================================== BUTTON ===============================================================
; Represents a single digital input / output - keyboard key, mouse button, (virtual) joystick button or hat direction
class _Button {
	Type := 0 ; 0 = Unset, 1 = Key / Mouse, 2 = stick button, 3 = stick hat
	Code := 0
	DeviceID := 0
	UID := ""
	IsVirtual := 0		; Set to 1 for vJoy stick buttons / hats
	
	_Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
		,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
		,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
		,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	__New(obj){
		this._Deserialize(obj)
	}
	
	; Returns true if this Button is a modifier key on the keyboard
	IsModifier(){
		if (this.Type = 1 && ObjHasKey(this._Modifiers, this.Code))
			return 1
		return 0
	}
	
	; Renders the keycode of a Modifier to it's AHK Hotkey symbol (eg 162 for LCTRL to ^)
	RenderModifier(){
		return this._Modifiers[this.Code].s
	}
	
	; Builds the AHK key name
	BuildKeyName(){
		if this.Type = 1 {
			code := Format("{:x}", this.Code)
			return GetKeyName("vk" code)
		} else if (this.Type = 2){
			return this.DeviceID "Joy" this.code
		} else if (this.Type >= 3){
			return this.DeviceID "JoyPov"
		}
	}
	
	; Builds a human readable version of the key name (Mainly for joysticks)
	BuildHumanReadable(){
		static hat_directions := ["Up", "Right", "Down", "Left"]
		if (this.Type = 1) {
			return this.BuildKeyName()
		} else if (this.Type = 2){
			return (this.IsVirtual ? "Virtual " : "") "Stick " this.DeviceID ", Button " this.code
		} else if (this.Type >= 3){
			return (this.IsVirtual ? "Virtual " : "") "Stick " this.DeviceID ", Hat " this.Type - 2 " " hat_directions[this.code]
		}
	}
	
	_Serialize(){
		return {Type: this.Type, Code: this.Code, DeviceID: this.DeviceID, UID: this.UID, IsVirtual: this.IsVirtual}
	}
	
	_Deserialize(obj){
		for k, v in obj {
			this[k] := v
		}
	}
}

; ======================================================================== AXIS ===============================================================
class _Axis {
	DeviceID := 0
	Axis := 0
}

GuiClose(hwnd){
	UCR.GuiClose(hwnd)
}
UCR_OnMessageCreate(msg,hwnd,fnPtr){
	OnMessage(msg+0,hwnd+0,Object(fnPtr+0))
}