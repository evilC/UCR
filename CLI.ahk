/*
	UCR Command line tool
	
	The recommended editor for UCR is AHK Studio
	https://autohotkey.com/boards/viewtopic.php?t=300
*/

; GUID used to control remote instance of UCR
UCRguid := "{E97F3D9C-47D5-47EA-92FB-2974647DB131}"

; Get an existing running instance of UCR
try remoteUCR := ComObjActive(UCRguid)
try parentProfileName = %1% ; First passed parameters defines a root profile name, this can alternatively be a GUID
try childProfileName = %2% ; The second parameter is the name of a child profile under the system profile

if remoteUCR 
{
	; Change profile if script is already running
	remoteUCR.ChangeProfileByName(parentProfileName, childProfileName, 0)
} else {
	Run UCR.exe UCR.ahk "%parentProfileName%" "%childProfileName%"
}

ExitApp