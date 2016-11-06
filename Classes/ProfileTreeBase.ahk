; =================================================================== BASE PROFILE TREE ==========================================================
; Creates a treeview that can parse UCR's profiles and display a treeview of them
class _ProfileTreeBase {
	__New(){
		Gui, New, HwndHwnd
		Gui +ToolWindow
		Gui +Resize
		this.hwnd := hwnd
		;Gui, Color, Red
		Gui, Add, TreeView, % "w" UCR.SIDE_PANEL_WIDTH " h100 aw ah hwndhTreeview AltSubmit"
		this.hTreeview := hTreeview
		
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
