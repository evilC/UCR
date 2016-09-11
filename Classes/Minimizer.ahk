; Minimze to tray by SKAN http://www.autohotkey.com/board/topic/32487-simple-minimize-to-tray/
class _Minimizer {
	__New(hwnd, callback){
		this.hwnd := hwnd
		this.callback := callback
		this.Menu("Tray","Nostandard"), this.Menu("Tray","Add","Restore",this.GuiShow.Bind(this)), this.Menu("Tray","Add")
		this.Menu("Tray","Default","Restore"), this.Menu("Tray","Click",1), this.Menu("Tray","Standard")
		
		OnMessage(0x112, this.WM_SYSCOMMAND.Bind(this))
	}
	
	WM_SYSCOMMAND(wParam){
		If ( wParam = 61472 ) {
			fn := this.callback
			SetTimer, % fn, -1
			Return 0
		}
	}
	
	Menu( MenuName, Cmd, P3="", P4="", P5="" ) {
		Menu, %MenuName%, %Cmd%, %P3%, %P4%, %P5%
		Return errorLevel
	}

	MinimizeGuiToTray(){
		this._MinimizeGuiToTray()
		this.Menu("Tray","Icon")
	}
	
	_MinimizeGuiToTray( ) {
		WinGetPos, X0,Y0,W0,H0, % "ahk_id " (Tray:=WinExist("ahk_class Shell_TrayWnd"))
		ControlGetPos, X1,Y1,W1,H1, TrayNotifyWnd1,ahk_id %Tray%
		SW:=A_ScreenWidth,SH:=A_ScreenHeight,X:=SW-W1,Y:=SH-H1,P:=((Y0>(SH/3))?("B"):(X0>(SW/3))
		? ("R"):((X0<(SW/3))&&(H0<(SH/3)))?("T"):("L")),((P="L")?(X:=X1+W0):(P="T")?(Y:=Y1+H0):)
		VarSetCapacity(R,32,0), DllCall( "GetWindowRect",UInt,this.hwnd,UInt,&R)
		NumPut(X,R,16), NumPut(Y,R,20), DllCall("RtlMoveMemory",UInt,&R+24,UInt,&R+16,UInt,8 )
		DllCall("DrawAnimatedRects", UInt,this.hwnd, Int,3, UInt,&R, UInt,&R+16 )
		WinHide, % "ahk_id " this.hwnd
		this.R := R
	}
	
	GuiShow(){
		DllCall("DrawAnimatedRects", UInt,Gui1, Int,3, UInt,&R+16, UInt,&this.R )
		this.Menu("Tray","NoIcon")
		Gui, % this.hwnd ":Show"
	}
}