#SingleInstance force
MsgBox % A_AhkPath
Gui, new, HwndMainHWnd +Resize
Gui, % MainHWnd ":Font", S8
Gui, % MainHWnd ":Add", ListView, w325 r20 -Grid -Hdr vLVMain HwndLVHwnd, Test
Gui, Add, Text,
; Set row height - http://www.autohotkey.com/board/topic/74758-tip-how-to-set-row-height-for-listview/
LV_SetImageList( DllCall( "ImageList_Create", "Int",2, "Int", 35, "Int", 0x18, "Int",1, "Int",1 ), 1 )
Loop, 10 {
    LV_Add("",A_Index)
}
Gui, % MainHWnd ":Show",, Scrolling Sub-Gui Test

Loop, 10 {
    y := (A_Index - 1) * 35
    ch := CreateChild(LVHWnd, y)
    WinSet, Top, , % "ahk_id " ch
}

Loop {
    DllCall("RedrawWindow", "uint", A_ScriptHwnd, "uint", 0, "uint", 0, "uint", 0)
    ToolTip % ErrorLevel
    sleep 100
}
return

CreateChild(hwnd, y){
    Gui, new, % "HwndChildHwnd -Border +Parent" hwnd
    Gui, % ChildHwnd ":Add", Edit, w100, % "Gui At y " y
    Gui % ChildHwnd ":Show", x1 y%y% w200 h30
    return ChildHwnd
}

GuiSize:
    AutoXYWH(LVHWnd, "wh")
    return
    
Esc::
    ExitApp

; =================================================================================
; Function:     AutoXYWH
;   Move and resize control automatically when GUI resized.
; Parameters:
;   ctrl_list  - ControlID list separated by "|".
;                ControlID can be a control HWND, associated variable name or ClassNN.
;   Attributes - Can be one or more of x/y/w/h
;   Redraw     - True to redraw controls
; Examples:
;   AutoXYWH("Btn1|Btn2", "xy")
;   AutoXYWH(hEdit      , "wh")
; ---------------------------------------------------------------------------------
; AHK version : 1.1.13.01
; Tested On   : Windows XP SP3 (x86)
; Release date: 2014-1-2
; Author      : tmplinshi
; =================================================================================
AutoXYWH(ctrl_list, Attributes, Redraw = False)
{
    static cInfo := {}, New := []

    Loop, Parse, ctrl_list, |
    {
        ctrl := A_LoopField

        if ( cInfo[ctrl]._x = "" )
        {
            GuiControlGet, i, Pos, %ctrl%
            _x := A_GuiWidth  - iX
            _y := A_GuiHeight - iY
            _w := A_GuiWidth  - iW
            _h := A_GuiHeight - iH
            _a := RegExReplace(Attributes, "i)[^xywh]")
            cInfo[ctrl] := { _x:_x, _y:_y, _w:_w, _h:_h, _a:StrSplit(_a) }
        }
        else
        {
            if ( cInfo[ctrl]._a.1 = "" )
                Return

            New.x := A_GuiWidth  - cInfo[ctrl]._x
            New.y := A_GuiHeight - cInfo[ctrl]._y
            New.w := A_GuiWidth  - cInfo[ctrl]._w
            New.h := A_GuiHeight - cInfo[ctrl]._h

            for i, a in cInfo[ctrl]["_a"]
                Options .= a New[a] A_Space
            
            GuiControl, % Redraw ? "MoveDraw" : "Move", % ctrl, % Options
        }
    }
}

