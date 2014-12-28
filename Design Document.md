#Design Document for UCR - Universal Control Remapper

##Overview
UCR from the user's perspective shall consist of two main components:

######Host Application ("Host")
The Host application is file (ideally an Executable, possibly an .ahk) that the user runs and is presented with a GUI.   

######Plugins
A Plugin is a piece of AHK code that the user loads into the Host Application in order to perform some specific function - eg convert a key from normal momentary operation to a toggle.   
Each Plugin presents it's own GUI within the Host GUI, from where the user can configure settings for the plugin and inputs / outputs (eg which keys it is triggered by and which keys it sends)   
Plugins are designed to be easily writable by users, and easily shared between them.   

##Architecture


##Roadmap
Hurdles that need to be crossed.
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

