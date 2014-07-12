#singleinstance force
#maxhotkeysperinterval 9999
;#include <CWindow>
#include <UCRWindow>
#include <UCRScrollableWindow>
#include <UCRChildWindow>
#include <CCtrlButton>
#include <CCtrlLabel>

GUI_WIDTH := 300
AFC_EntryPoint(UCRMainWindow)
;GroupAdd, MyGui, % "ahk_id " . WinExist()
GroupAdd, MyGui, % "ahk_id " . AFC_AppObj.__Handle

return


#IfWinActive ahk_group MyGui
~WheelUp::
~WheelDown::
~+WheelUp::
~+WheelDown::
    ; SB_LINEDOWN=1, SB_LINEUP=0, WM_HSCROLL=0x114, WM_VSCROLL=0x115
    ;AFC_AppObj.OnScroll(InStr(A_ThisHotkey,"Down") ? 1 : 0, 0, GetKeyState("Shift") ? 0x114 : 0x115, WinExist())
    AFC_AppObj.OnScroll(InStr(A_ThisHotkey,"Down") ? 1 : 0, 0, GetKeyState("Shift") ? 0x114 : 0x115, AFC_AppObj.scroll_window.__Handle)
return
#IfWinActive

class UCRMainWindow extends UCRWindow {
	__New()
	{
		global GUI_WIDTH
		this.handler := this

		base.__New("U C R", "+Resize")

		new CCtrlButton(this, "Add Panel").OnEvent := this.AddClicked

		this.Show("w" GUI_WIDTH " h240 X0 Y0")

		this.scroll_window := new UCRRuleList(this, "", "")
		hwnd := this.scroll_window.__Handle

		this.scroll_window.Show("w300 X0 Y50")
		this.scroll_window.OnSize()

		this.OnSize()
		;this.AddClicked()
		;this.AddClicked()
		;this.AddClicked()
		;this.AddClicked()
		;this.AddClicked()
		;this.AddClicked()
		;this.AddClicked()

	}

	OnScroll(wParam, lParam, msg, hwnd){
		this.scroll_window.OnScroll(wParam, lParam, msg, hwnd)
	}

	OnClose(){
		ExitApp
	}

	AddClicked(){
		this.scroll_window.AddChild("UCRRule")
		this.OnSize()
	}

	OnSize(){
		Critical
		r := this.GetClientRect(this.__Handle)
		r.t += 50
		r.b -= r.t + 6
		r.r -= r.l + 6

		ws := this.GetScrollBarVisibility(this.scroll_window.__Handle)

		if (ws.x){
			r.r -= 16
		}

		if (ws.y){
			r.b -= 16
		}

		this.scroll_window.Show("X0 Y50 W" r.r " H" r.b)
	}

}

class UCRRuleList extends UCRScrollableWindow{
	__New(parent)
	{
		global GUI_WIDTH

		base.__New("Hello World", "-Border +Parent" parent.__Handle)

		this.Show("w" GUI_WIDTH " h240 X0 Y0")
	}

	AddClicked(){
		cw := this.AddChild("UCRRule")
	}


}

Class UCRRule extends UCRChildWindow
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


