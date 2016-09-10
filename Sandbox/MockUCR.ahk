/*
Mock UCR for testing and development of Input / Output GuiControls
*/
;UCR._ProfilePicker.PickProfile(this.ProfileChanged.Bind(this), this.__value)
class UCR extends _UCRBase {		
	__New(){
		UCR := this	; Set super-global at START of Ctor!
		this._ProfilePicker := new this._MockProfilePicker()
	}
	
	; Pass this an indexed array of GuiControl names
	; It creates an entry in this.Mappings with each name as the index.
	; Place JSON serialized BindObjects into the .mappings property
	AddTestMappings(mappings){
		this.Mappings := {}
		for k, v in mappings {
			this.Mappings[k] := {current: 0, mappings: v}
		}
	}
	
	; The user selected the "Bind" option from an Input/OutputButton GuiControl,
	;  or changed an option such as "Wild" in an InputButton
	_RequestBinding(hk, delta := 0){
		if (delta = 0){
			if (!m := this.Mappings[hk.name])
				return
			if (!max := this.Mappings[hk.name].mappings.length())
				return
			m.current++
			if (m.current > max){
				m.current := 1
			}
			bo := new _BindObject()
			bo._Deserialize(this.Mappings[hk.name].mappings[m.current])
			hk.value := bo
		} else {
			; Change option (eg wild, passthrough) requested
			bo := hk.value.clone()
			for k, v in delta {
				bo[k] := v
			}
			;~ if (this._InputHandler.IsBindable(hk, bo)){
				hk.value := bo	; Triggers setter on guicontrol, which causes settings save
				;~ this._InputHandler.SetButtonBinding(hk)
			;~ }
		}
	}
	
	BuildProfilePathName(id){
		return "Global"
	}
	
	Class _MockProfilePicker {
		__New(){
			
		}
		
		PickProfile(callback, current){
			callback.Call(1)
		}
	}
}

Class _UCRBase {
	; By jNizM - https://autohotkey.com/boards/viewtopic.php?f=6&t=4732&p=87497#p87497
	CreateGUID(){
		VarSetCapacity(foo_guid, 16, 0)
		if !(DllCall("ole32.dll\CoCreateGuid", "Ptr", &foo_guid))
		{
			VarSetCapacity(tmp_guid, 38 * 2 + 1)
			DllCall("ole32.dll\StringFromGUID2", "Ptr", &foo_guid, "Ptr", &tmp_guid, "Int", 38 + 1)
			fin_guid := StrGet(&tmp_guid, "UTF-16")
		}
		return SubStr(fin_guid, 2, 36)
	}
}