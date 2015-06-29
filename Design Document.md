#Design Document for UCR - Universal Control Remapper

##Goal
The basic aim of UCR is to allow end-users to configure hotkeys and control remappings via a GUI, without needing to know how to code.  
It does this by allowing coders to write plugins that perform one simple function (eg remap one key to another) and allowing the end-user to load one or more copies of that plugin and choose their inputs and outputs.  
For example, a user may load two Key>App plugins and configure one to open a browser window when they hit F1, and the other to open a notepad window when they hit F2.
The user can then group these plugins together into profiles, and switch between them at will.

##Overview
UCR from a technical perspective shall consist of two main components:

######Host Application ("Host")
The Host application is a file (ideally an Executable, possibly an .ahk) that the user runs and is presented with a GUI, through which they can add one or more plugins.  
The Host can handle various common tasks for a plugin such as injecting a GUI item that allows the end user to select a hotkey, remembering a setting's value between runs (eg which hotkey is currently selected), or firing a subroutine in the plugin when the selected hotkey is pressed.  
Plugins would appear in a pane inside the host application, most likely in a scrollable list of some form.

######Plugins
A Plugin is a piece of AHK code that the user loads into the Host Application in order to perform some specific function - eg convert a key from normal momentary operation to a toggle, or launch a certain application when you hit a certain key.   
Each Plugin presents it's own GUI within the Host GUI, from where the user can configure settings for the plugin and inputs / outputs (eg which keys it is triggered by and which keys it sends)  
Users may run any number of plugins at one time.   
Plugins are designed to be easily writable by users, and easily shared between them.   

##Planned Features
* Inputs: Joystick, Mouse, Keyboard, maybe other devices (TrackIR etc).
* Outputs: Joystick (virtual only), Mouse, Keyboard
* Joystick input / output caps:   
8 Axes, 4 POVs, 32+ Buttons per stick, 16 Sticks   
Input Via RawInput / DirectInput calls.   
* 16 Sticks, accessed via same ID that AHK would use   
Use WinMM to enumerate IDs, match to GUIDs?   
* Dynamic include at run-time of Plugins
* Each plugin has own GUI, with settings + options.
* Profile support (Profile is a set of plugins configured in certain way)
* Per-application profiles?
* Global settings in Host App - global hotkeys eg to change profile.
* Useful built-in libraries such as accurate timers, math functions for axis manipulation (eg invert, deadzone etc).

##Roadmap / Hurdles to overcome
* Overcome AHK limitation: No scroll bar support.  
Test code written for AHK v2, maybe over-complicated (CGui).  
* Dynamic Includes (Plugin System)   
Proof of concept code written for EXE dynamically including source (.ahk file).  
HotkeyIt has this one covered.  
* Full joystick support  
(Overcome AHK limitation: 6 axis / 32 button / 1 POV / No up event on buttons)  
AHK-CHID proof of concept code written (AHK v1 only, needs porting to v2)  
POC code yields pre-calibration values, some work maybe needed to apply calibration.  
* Input Binding system (With GUI item)  
Allow end-users to specify any combination of keyboard / mouse / joystick input as a "binding".  
Some POC code written (CHID, HotClass).  
* vJoy interface   
New CvJoyInterface library written (AHK v1 + v2).   

