#Persistent
#SingleInstance, force
OnExit, Unhook

WH_KEYBOARD_LL := 13
WH_MOUSE_LL := 14

hHookKeybd := SetWindowsHookEx(WH_KEYBOARD_LL, RegisterCallback("Keyboard", "Fast"))
hHookMouse := SetWindowsHookEx(WH_MOUSE_LL, RegisterCallback("MouseMove", "Fast"))
Return

Unhook:
UnhookWindowsHookEx(hHookKeybd)
UnhookWindowsHookEx(hHookMouse)
ExitApp


Keyboard(nCode, wParam, lParam)
{
	Critical
	SetFormat, Integer, H
	If ((wParam = 0x100) || (wParam = 0x101))  ;   ; WM_KEYDOWN || WM_KEYUP
	{
		KeyName := GetKeyName("vk" NumGet(lParam+0, 0))
		Tooltip, % (wParam = 0x100) ? KeyName " Down" :	KeyName " Up"
	}
	Return CallNextHookEx(nCode, wParam, lParam)
	;Return 1
}

MouseMove(nCode, wParam, lParam)
{
	Critical
	if (wParam != 512){
		; filter out mouse movement
		tooltip % nCode ", " wParam
		SetFormat, Integer, D
		;If (!nCode && (wParam = 0x200)){
			;Tooltip, %  "X " NumGet(lParam+0, 0, int) " Y " NumGet(lParam+0, 4, int)
		;}
	}
	Return CallNextHookEx(nCode, wParam, lParam)
}

SetWindowsHookEx(idHook, pfn)
{
	Return DllCall("SetWindowsHookEx", "int", idHook, "Uint", pfn, "Uint", DllCall("GetModuleHandle", "Uint", 0), "Uint", 0)
}

UnhookWindowsHookEx(hHook)
{
	Return DllCall("UnhookWindowsHookEx", "Uint", hHook)
}

CallNextHookEx(nCode, wParam, lParam, hHook = 0)
{
	Return DllCall("CallNextHookEx", "Uint", hHook, "int", nCode, "Uint", wParam, "Uint", lParam)
}

Esc::ExitApp