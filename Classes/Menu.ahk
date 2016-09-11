; An OOP wrapper for AHK's menu system
; Uses GUIDs to anonymize menus and ensure uniqueness of names
class _Menu extends _UCRBase {
	Parent := 0
	Enabled := 1
	ItemsByID := {}
	ItemsByName := {}
	MenusByID := {}
	MenusByName := {}
	
	__New(text := ""){
		this.id := this.CreateGUID()
		this.text := text
		Menu, % this.id, Add
	}
	
	; text = What text will appear as in the parent menu
	AddMenuItem(text := "", callback := ""){
		return this._AddItem(text, callback)
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
	_AddItem(text, callback){
		if (text != "" && this.CheckForDuplicateItemName(text)){
			return 0
		}
		item := new this.MenuItem(this, text, callback)
		this.ItemsByID[item.id] := item
		if (text != "")
			this.ItemsByName[text] := item
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
	
	
	ChangeItemName(item, NewName){
		if (this.CheckForDuplicateItemName(NewName)){
			return 0
		}
		this.ItemsByName.Delete(name)
		this.ItemsByName[NewName] := item
		Menu, % this.id, Rename, % item.name, % NewName
		item.name := NewName
		return 1
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
			Menu, % this.parent.id, Disable, % this.text
		return this
	}
	
	_KillReferences(){
		for id, menu in this.MenusByID {
			menu._KillReferences()
		}
		for id, item in this.ItemsByID {
			item._KillReferences()
		}
		Menu, % this.id, Delete
		this.ItemsByID := {}
		this.ItemsByName := {}
		this.MenusByID := {}
		this.MenusByName := {}
	}
	
	__Delete(){
		;OutputDebug % "UCR| Menu " this.text " fired destructor"
	}

	class MenuItem extends _UCRBase {
		Checked := 0
		__New(parent, name, callback){
			this.parent := parent, this.name := name, this.callback := callback
			this.id := Menu.CreateGUID()
			this.name := name
			Menu, % parent.id, Add, % name, % callback
		}
		
		Icon(FileName, IconNumber := "", IconWidth := ""){
			Menu, % this.parent.id, Icon, % this.name, % FileName, % IconNumber, % IconWidth
			return this
		}
		
		Check(){
			this.Checked := 1
			Menu, % this.parent.id, Check, % this.name
			return this
		}
		
		UnCheck(){
			this.Checked := 0
			Menu, % this.parent.id, UnCheck, % this.name
			return this
		}
		
		ToggleCheck(){
			this.Checked := !this.Checked
			Menu, % this.parent.id, ToggleCheck, % this.name
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
			Menu, % this.parent.id, Enable, % this.name
			return this
		}
		
		Disable(){
			this.Enabled := 0
			Menu, % this.parent.id, Disable, % this.name
			return this
		}
		
		ToggleEnable(){
			this.Enabled := !this.Enabled
			Menu, % this.parent.id, ToggleEnable, % this.name
			return this
		}
		
		Rename(NewName := ""){
			if (this.parent.ChangeItemName(this, NewName)){
				return this
			}
			return 0
		}
		
		Add(aParams*){
			; Route to parent
			return this.parent.Add(aParams*)
		}
		
		AddSubMenu(aParams*){
			; Route to parent
			return this.parent.AddSubMenu(aParams*)
		}
		
		_KillReferences(){
			
		}
	}
}
