#Component design document for binding system

##Goal
To provide a replacement for the AHK `Hotkey` GUI control.  

##Requirements
* The control should be able to detect keyboard, mouse or joystick input (Or any combination thereof).  
* The author should be able to define a callback which is called whenever the state of the selected input changes (ie button up / down event, axis value changes)  
and pass the new state.  
* The control should have options for pass-through (`~`) and wild (`*`) mode (Keyboard / Mouse).
* The end-user should be able to clear bindings (Click Bind button and hold ESCape).
* The current binding should be able to be set programatically (eg when script loads, settings pulled from an INI file and control state initialized to existing binding).
* A callback should be able to be specified that gets called when the end-user changes binding.
* The control may need to be application aware - ie only fire callback if the input occurs while a specified application is active.

##Hurdles
* Joystick state reading POC written (Using RawInput), but axis values are pre-calibration. Possible info on extracting calibration info [here](https://msdn.microsoft.com/en-us/library/windows/hardware/ff543344(v=vs.85).aspx) ?
* Keyboard / mouse detection will probably need to make use of `SetWindowsHookEx` calls (POC written).
