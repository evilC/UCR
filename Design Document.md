#Design Document for UCR - Universal Control Remapper

##Goal
UCR is intended as a one-size-fits-all replacement for my ADHD library.   
It is intended to merge the functionality of UJR, Fire Control etc into one app.   
It could be thought of as similar to the remapping software that comes with gaming mice, but working with all devices.

##Overview
UCR from the user's perspective shall consist of two main components:

######Host Application ("Host")
The Host application is file (ideally an Executable, possibly an .ahk) that the user runs and is presented with a GUI.   

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
Input Via DirectInput calls?   
* 16 Sticks, accessed via same ID that AHK would use   
Use WinMM to enumerate IDs, match to GUIDs?   
* Dynamic include at run-time of Plugins
* Each plugin has own GUI, with settings + options.
* Profile support (Profile is a set of plugins configured in certain way)
* Per-application profiles?
* Global settings in Host App - global hotkeys eg to change profile.
* Useful built-in libraries such as accurate timers, math functions for axis manipulation (eg invert, deadzone etc).



##Roadmap
* Window Manager for Host Application?   
Test code written for AHK v2, maybe over-complicated?   
Just display one plugin at a time?   
C application as parent, handle windowing with C libs?
* Dynamic Includes (Plugin System)   
AutoHotkey.dll?   
DynaRun?   
* Full stick support   
sjc1000 taking a look at writing DirectInput wrapper.   
* vJoy interface   
New library written.   

