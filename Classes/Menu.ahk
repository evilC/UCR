; An OOP wrapper for AHK's menu system
; Uses GUIDs to anonymize menus and ensure uniqueness of names

class _Menu {
	id := 0
	Parent := 0
	Enabled := 1
	ItemsByID := {}
	ItemsByName := {}
	MenusByID := {}
	MenusByName := {}
	
	__New(text := ""){
		this.id := CreateGUID()
		this.text := text
		Menu, % this.id, Add
	}

	; text = What text will appear as in the parent menu
	AddMenuItem(text, ItemName, callback := 0){
		return this._AddItem(text, ItemName, callback)
	}
	
	; text = What text will appear as in the parent menu 
	; MenuName = the name that code uses to refer to the menu
	AddSubMenu(text, MenuName){
		if (this.CheckForDuplicateMenuName(MenuName)){
			return 0
		}
		child := new _Menu(text)
		child.parent := this
		this.MenusByID[child.id] := child
		if (text != "")
			this.MenusByName[MenuName] := child
		Menu, % this.id, Add, % text, % ":" child.id
		return child
	}
	
	; 
	_AddItem(text, ItemName, callback := 0){
		; ToDo: Something seems to have changed ?when lazy loading menus got implemented?...
		; ... I now need to pass 0 to CheckForDuplicateItemName to suppress dupe message warning
		; Else the ProfileSwitcher plugin throws a warning the first time you try to select a profile.
		if (text != "" && this.CheckForDuplicateItemName(text, 0)){
			return 0
		}

		item := new this.MenuItem(this, text, ItemName, callback)
		this.ItemsByID[item.id] := item
		if (text != "")
			this.ItemsByName[ItemName] := item
		return item
	}
	
	CheckForDuplicateItemName(name, warn := 1){
		if (ObjHasKey(this.ItemsByName, name)){
			if (warn)
				Msgbox % "Error. An item with the name " name " already exists in this menu"
			return 1
		}
		return 0
	}
	
	CheckForDuplicateMenuName(name, warn := 1){
		if (ObjHasKey(this.MenusByName, name)){
			if (warn)
				Msgbox % "Error. A SubMenu with the name " name " already exists in this menu"
			return 1
		}
		return 0
	}

	DestroyMenu(){
		for id, item in this.ItemsByID {
			item.OnClose()
		}
		for id, menu in this.MenusByID {
			menu.DestroyMenu()
		}
		
		this.ItemsByID := {}
		this.ItemsByName := {}
		this.MenusByID := {}
		this.MenusByName := {}
		this.Enabled := 0
		try Menu, % this.id, Delete
	}
	
	SetEnableState(state){
		if (state)
			this.Enable()
		else
			this.Disable()
		return this
	}
	
	Enable(){
		this.Enabled := 1
		if (this.Parent != 0)
			Menu, % this.parent.id, Enable, % this.text
		return this
	}
	
	Disable(){
		this.Enabled := 0
		if (this.Parent != 0)
			try Menu, % this.parent.id, Disable, % this.text
		return this
	}
	
	OnClose(){
		for id, item in this.ItemsByID {
			item.OnClose()
		}
		for id, menu in this.MenusByID {
			menu.OnClose()
		}
		try Menu, % this.id, Delete
		this.ItemsByID := {}
		this.ItemsByName := {}
		this.MenusByID := {}
		this.MenusByName := {}
	}
	
	__Delete(){
		;OutputDebug % "UCR| Menu " this.text " fired destructor"
	}

	class MenuItem {
		parent := 0		; Pointer to parent menu
		name := ""		; Name that this item is referred to by
		text := ""		; The text of the menu entry
		callback := 0		; The BoundFunc to call when the item is selected
		Checked := 0
		
		__New(parent, text, name, callback := 0){
			this.parent := parent, this.text := text, this.callback := callback, this.name := name
			this.id := CreateGUID()
			if (callback == 0){
				
				callback := this.DoNothing.Bind(this)
			}
			Menu, % parent.id, Add, % text, % callback
		}
		
		DoNothing(aParams*){
		}
		
		Icon(FileName, IconNumber := "", IconWidth := ""){
			Menu, % this.parent.id, Icon, % this.text, % FileName, % IconNumber, % IconWidth
			return this
		}
		
		Check(){
			this.Checked := 1
			try Menu, % this.parent.id, Check, % this.text
			return this
		}
		
		UnCheck(){
			this.Checked := 0
			try Menu, % this.parent.id, UnCheck, % this.text
			return this
		}
		
		ToggleCheck(){
			this.Checked := !this.Checked
			try Menu, % this.parent.id, ToggleCheck, % this.text
			return this
		}
		
		SetCheckState(state){
			if (state)
				this.Check()
			else
				this.UnCheck()
			return this
		}
		
		SetEnableState(state){
			if (state)
				this.Enable()
			else
				this.Disable()
			return this
		}
		
		Enable(){
			this.Enabled := 1
			try Menu, % this.parent.id, Enable, % this.text
			return this
		}
		
		Disable(){
			this.Enabled := 0
			try Menu, % this.parent.id, Disable, % this.text
			return this
		}
		
		ToggleEnable(){
			this.Enabled := !this.Enabled
			try Menu, % this.parent.id, ToggleEnable, % this.text
			return this
		}
		
		Add(aParams*){
			; Route to parent
			return this.parent.Add(aParams*)
		}
		
		AddSubMenu(aParams*){
			; Route to parent
			return this.parent.AddSubMenu(aParams*)
		}
		
		OnClose(){
			try Menu, % parent.id, Delete, % this.id
		}
	}
}


