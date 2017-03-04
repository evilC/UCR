; =================================================================== MAIN PROFILE SELECT / ADD ==========================================================
; The main tool that the user uses to change profile, add / remove / rename / re-order profiles etc
class _ProfileToolbox extends _ProfileTreeBase {
	ProfileColors := {}
	__New(){
		base.__New()
		half_width := round(UCR.SIDE_PANEL_WIDTH / 2) - 5
		Gui, Add, CheckBox, xm y110 aya w150 hwndhInherits Center, Profile Inherits Plugins`nfrom parent
		this.hInheritsFromParent := hInherits
		fn := this.InheritToggled.Bind(this)
		GuiControl +g, % hInherits, % fn
		
		Gui, Add, Button, % "xm w" half_width " hwndhAdd y140 aya aw1/2", Add
		fn := this.AddProfile.Bind(this,0)
		GuiControl +g, % hAdd, % fn

		Gui, Add, Button, % "x+5 w" half_width " hwndhAdd y140 aya axa aw1/2", Add Child
		fn := this.AddProfile.Bind(this,1)
		GuiControl +g, % hAdd, % fn

		Gui, Add, Button, % "xm w" half_width " hwndhRename y+5 aya axr aw1/2", Rename
		fn := this.RenameProfile.Bind(this)
		GuiControl +g, % hRename, % fn
		
		Gui, Add, Button, % "x+5 w" half_width " hwndhDelete yp aya axa aw1/2", Delete
		fn := this.DeleteProfile.Bind(this)
		GuiControl +g, % hDelete, % fn

		Gui, Add, Button, % "xm w" half_width " hwndhCopy y+5 aya axr aw1/2", Copy
		fn := this.CopyProfile.Bind(this)
		GuiControl +g, % hCopy, % fn

		this.DragMidFn := this.Treeview_Dragging.Bind(this)
		this.DragEndFn := this.Treeview_EndDrag.Bind(this)
		this.MsgFn := this.WM_NOTIFY.Bind(this)
		
		Gui, % this.hwnd ":-Caption -Resize"
		;Gui, % this.hwnd ":Show", % "x" x - 110 " y" y - 5, Profile Toolbox
		Gui, % this.hwnd ":Show", Hide
		
		OnMessage(0x4e,this.MsgFn)
	}
	
	InheritToggled(){
		GuiControlGet, state, , % this.hInheritsFromParent
		id := this.ProfileIDOfSelection()
		UCR.SetProfileInheritsState(id, state)
	}
	
	AddProfile(childmode){
		if (childmode)
			parent := this.ProfileIDOfSelection()
		else
			parent := 0
		UCR._AddProfile(parent)
	}

	CopyProfile(){
		id := this.ProfileIDOfSelection()
		UCR._CopyProfile(id)
	}
	
	DeleteProfile(){
		id := this.ProfileIDOfSelection()
		UCR._DeleteProfile(id)
	}
	
	RenameProfile(){
		id := this.ProfileIDOfSelection()
		UCR.RenameProfile(id)
	}
	
	SetProfileInherit(state){
		GuiControl, , % this.hInheritsFromParent, % state
	}
	
	SetProfileColor(id, cols){
		this.ProfileColors[this.ProfileIdToLvHandle[id]] := cols
	}

	UnSetProfileColor(id){
		this.ProfileColors.Delete(this.ProfileIdToLvHandle[id])
	}
	
	ResetProfileColors(){
		this.ProfileColors := {}
	}
	
	; Sets colors for treeview items.
	; ToDo: Move to separate thread
	; Thanks to Maestrith for working out this technique - https://autohotkey.com/boards/viewtopic.php?f=6&t=2632
	WM_NOTIFY(Param*){
		static o_hwndFrom := 0, o_code := 2*A_PtrSize, o_dwDrawStage := 3*A_PtrSize, o_dwItemSpec := 16+(5*A_PtrSize), o_fg := 16+(8*A_PtrSize), o_bg := o_fg+4
		if (NumGet(Param.2, o_hwndFrom) != this.hTreeview )	; filter messages not for this TreeView
			return
		stage := NumGet(Param.2, o_dwDrawStage, "uint")
		if (stage == 1 && NumGet(Param.2, o_code, "int") == -12)
			return 0x20 ;sets CDRF_NOTIFYITEMDRAW
		node := numget(Param.2, o_dwItemSpec, "uint")
		if (stage == 0x10001 && ObjHasKey(this.ProfileColors, node)){
			if (this.ProfileColors[node].back)
				NumPut(this.ProfileColors[node].back,Param.2, o_bg,"int") ;sets the background
			if (this.ProfileColors[node].fore)
				NumPut(this.ProfileColors[node].fore,Param.2, o_fg,"int") ;sets the foreground
		}
	}
	
	; G-label for treeview
	TV_Event(){
		if (A_GuiEvent == "Normal"){
			newprofile := this.LvHandleToProfileId[A_EventInfo]
			; ToDo: This seems to trigger twice when changing profile to the last child.
			; Not a big issue as changing to current profile is ignored by ChangeProfile()
			;OutputDebug % "UCR| TV Change profile: " newprofile
			UCR.ChangeProfile(newprofile)
		} else if (A_GuiEvent == "D"){
			this.hDragitem := A_EventInfo
			this.Treeview_BeginDrag()
		}
	}
	
	;~ ShowButtonClicked(){
		;~ CoordMode, Mouse, Screen
		;~ MouseGetPos, x, y
		;~ Gui, % this.hwnd ":Show", % "x" x - 110 " y" y - 5, Profile Toolbox
	;~ }
	
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
				;OutputDebug % "UCR| Treeview_Dragging: this.BeforeAfter: " this.BeforeAfter
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
							;OutputDebug % "UCR| Treeview_EndDrag: this.BeforeAfter: " this.BeforeAfter
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
