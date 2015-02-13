#SingleInstance force
#NoEnv

#include <AhkDllThread>

Loop 3
dll%A_Index%:=AhkDllThread(A_ScriptDir "\autohotkey.dll"),dll%A_Index%.ahkdll()

dll1.ahkExec("CriticalObject:=CriticalObject()`nhObj:=CriticalObject(CriticalObject,1)`nhCriticalSection:=CriticalObject(CriticalObject,2)")
dll2.ahkExec("CriticalObject:=CriticalObject(" (dll1.ahkgetvar.hObj+0) "," dll1.ahkgetvar.hCriticalSection ")")
dll3.ahkExec("CriticalObject:=CriticalObject(" (dll1.ahkgetvar.hObj+0) "," dll1.ahkgetvar.hCriticalSection ")")

dll1.addScript("Label:`nLoop 10000`nCriticalObject[A_Index]:=A_Index`nExitApp",1)
dll2.addScript("Label:`nLoop 10000`nToolTip % CriticalObject[A_Index],50`nExitapp")
dll3.addScript("Label:`nLoop 10000`nToolTip % CriticalObject[A_Index],100`nExitapp")

dll1.ahkLabel("Label",1)
Sleep 100
dll2.ahkLabel("Label",1)
dll3.ahkLabel("Label",1)

While % dll2.ahkReady() || dll3.ahkReady()
Sleep 100
ExitApp
Esc:=ExitApp