#singleinstance force
#maxhotkeysperinterval 9999
;#include <CWindow>
#include <CScrollableWindow>
#include <CChildWindow>
#include <CCtrlButton>
#include <CCtrlLabel>

GUI_WIDTH := 300
;AFC_EntryPoint(MyMainWindow)
AFC_EntryPoint(UCRMainWindow)
GroupAdd, MyGui, % "ahk_id " . WinExist()
;AFC_EntryPoint(ModularUIPanel)

return

MenuHandler:
	return

!a::
AddPanel:
	AFC_AppObj.AddClicked()
	return

#IfWinActive ahk_group MyGui
~WheelUp::
~WheelDown::
~+WheelUp::
~+WheelDown::
    ; SB_LINEDOWN=1, SB_LINEUP=0, WM_HSCROLL=0x114, WM_VSCROLL=0x115
    OnScroll(InStr(A_ThisHotkey,"Down") ? 1 : 0, 0, GetKeyState("Shift") ? 0x114 : 0x115, WinExist())
return
#IfWinActive

class UCRMainWindow extends CWindow {
	__New()
	{
		global GUI_WIDTH
		this.handler := this

		base.__New("U C R", "+Resize")
		;base.__New("Hello World", "+Resize +0x300000")

		Menu, FileMenu, Add, E&xit, MenuHandler
		Menu, HelpMenu, Add, &About, MenuHandler
		Menu, PanelMenu, Add, &Add, AddPanel
		Menu, MyMenuBar, Add, &File, :FileMenu  ; Attach the two sub-menus that were created above.
		Menu, MyMenuBar, Add, &Panels, :PanelMenu  ; Attach the two sub-menus that were created above.
		Menu, MyMenuBar, Add, &Help, :HelpMenu
		Gui, Menu, MyMenuBar

		this.Show("w" GUI_WIDTH " h240 X0 Y0")

		;cw := new UCRRuleList(this, "", "-Border")
		cw := new UCRRuleList(this, "", "")
		hwnd := cw.__Handle
		;this.child_windows[hwnd] := cw
		;cw.Show()

		;y := this.AllocateSpace(cw)
		cw.Show("w300 X0 Y50")
		this.scroll_window  := cw

	}

	OnScroll(wParam, lParam, msg, hwnd){
		this.scroll_window.OnScroll(wParam, lParam, msg, hwnd)
	}

	OnClose(){
		ExitApp
	}

	AddClicked(){
		;cw := this.AddChild("MyChildWindow")
		this.scroll_window.AddChild("MyChildWindow")
	}

}

class UCRRuleList extends CScrollableWindow{
	__New(parent)
	{
		global GUI_WIDTH
		;this.handler := this

		;base.__New("Hello World", "+Resize")
		;base.__New("Hello World", "")
		base.__New("Hello World", "-Border +Parent" parent.__Handle)
		;base.__New("Hello World", "+Resize +0x300000")

		this.Show("w" GUI_WIDTH " h240 X0 Y0")
	}

	AddClicked(){
		cw := this.AddChild("MyChildWindow")
	}


}














class MyMainWindow extends CScrollableWindow
{
	__New()
	{
		global GUI_WIDTH
		this.handler := this

		base.__New("Hello World", "+Resize")
		;base.__New("Hello World", "+Resize +0x300000")

		Menu, FileMenu, Add, E&xit, MenuHandler
		Menu, HelpMenu, Add, &About, MenuHandler
		Menu, PanelMenu, Add, &Add, AddPanel
		Menu, MyMenuBar, Add, &File, :FileMenu  ; Attach the two sub-menus that were created above.
		Menu, MyMenuBar, Add, &Panels, :PanelMenu  ; Attach the two sub-menus that were created above.
		Menu, MyMenuBar, Add, &Help, :HelpMenu
		Gui, Menu, MyMenuBar

		this.Show("w" GUI_WIDTH " h240 X0 Y0")
	}

	OnClose(){
		ExitApp
	}

	AddClicked(){
		cw := this.AddChild("MyChildWindow")
	}

}

Class MyChildWindow extends CChildWindow
{
	__New(parent, title, options){
		base.__New(parent, title, options)
		this.deletebutton := new CCtrlButton(this, "Delete").OnEvent := this.DeleteClicked
		this.nametext := new CCtrlLabel(this, this.__Handle)
	}

	DeleteClicked(){
		this.parent.RemoveChild(this)
	}
}


