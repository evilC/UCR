#UCR - Universal Control Remapper

##About
The aim of UCR is to allow end-users to easily leverage the power of AHK without having to learn to code.  
At it's basest level, think of it as a way for an end-user to run a number of scripts written by various people, and manage when each script runs, what keys trigger it's functions, tweak each script's parameters, etc.
The primary target audience is gamers, UCR is intended to be able to replicate the functionality that comes with programmable keyboards / mice / joysticks etc.

##Profiles
UCR supports profiles. A number of plugins can be grouped together into a Profile.  
Profiles will be able to be linked to a specific application - when that application gets the focus, the profile becomes active.

##Plugins
At the core of the design of UCR is the idea of an AHK script as a "Plugin".  
A plugin is simply a text file containing AHK script (Even though the main UCR "app" may be running as an EXE).  
The plugin is an AHK class that derives from a base class that is part of the UCR source code.  
Each instance of each plugin gets it's own GUI inside the UCR app when added by a user. You can add anything you like to that Gui.  
Anything that you could normally put in an AHK class should work inside a plugin.  

##Persistent GuiControls
Plugins can call UCR methods to add a GuiControl to their Gui whose value will be remembered between runs of UCR.  
It can be used to allow the end user to tweak the behavior of the plugin that it is part of.

##Inputs and Outputs
Plugins may also contain special GuiControls that allow the end user to bind inputs and outputs.
Valid inputs are: Keyboard, Mouse, Joystick.
Valid outputs are: Keyboard, Mouse, vJoy Virtual Joystick

##Requirements
If you are a typical end-user of UCR, you just need to download the installer package. None is yet available.

In order to run UCR un-compiled, you will need to replace your AutoHotkey EXE with one from [AHK_H v1](https://github.com/HotKeyIt/ahkdll-v1-release/archive/master.zip).  

##Documentation
[UML Diagram](http://evilc.github.io/UCR/html-docs/)  
UML docs can also be viewd in StarUML format, please see the Docs folder
