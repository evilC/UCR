#include <CWindow>

Class UCRWindow extends CWindow {
	__New(title := "", options := ""){
		base.__New(title, options)
	}

	GetClientRect(hwnd){
		Gui, %hwnd%: +LastFound
		VarSetCapacity(rect, 16, 0)
        DllCall("GetClientRect", "Ptr", hwnd, "Ptr", &rect)
        ;return {w: NumGet(rect, 8, "Int"), h: NumGet(rect, 12, "Int")}
        return {l: NumGet(rect, 0, "Int"), t: NumGet(rect, 4, "Int") , r: NumGet(rect, 8, "Int"), b: NumGet(rect, 12, "Int")}
	}

	GetScrollInfo(){
		; ToDo: For OnScroll
	}

	GetPos(hwnd){
		;hwnd := this.__Handle
		Gui, %hwnd%: +LastFound
		WinGetPos x, y, w, h
		return {Top: y, Left: x, Right: x + w, Bottom: y + h}
	}

	GetSize(hwnd){
		;hwnd := this.__Handle
		Gui, %hwnd%: +LastFound
		WinGetPos x, y, w, h
		;msgbox % h
		return {w: w, h: h}
	}

	ScreenToClient(hwnd, x, y){
		VarSetCapacity(pt, 16)
		NumPut(x,pt,0)
		NumPut(y,pt,4)
		DllCall("ScreenToClient", "uint", hwnd, "Ptr", &pt)
		x := NumGet(pt, 0, "long")
		y := NumGet(pt, 4, "long")
		
		return {x: x, y: y}
	}

	AdjustToClientCoords(hwnd, obj){
		tmp := this.ScreenToClient(hwnd, 0, 0)
    	obj.Left += tmp.x
    	obj.Right += tmp.x
    	obj.Top += tmp.y
    	obj.Bottom += tmp.y
    	return obj
	}

}