#UCR - Universal Control Remapper

![ScreenShot](http://i.imgur.com/pSBxCbc.png)
#[MAIN UCR DOWNLOAD LINK](http://evilc.com/files/ahk/ucr/UCR.zip)
#[Forum thread for news and discussion](https://autohotkey.com/boards/viewtopic.php?f=19&t=12249)
##[Historical releases](https://github.com/evilC/UCR/releases)

##About
The aim of UCR is to allow end-users to easily leverage the power of AHK without having to learn to code.  
At it's basest level, think of it as a way for an end-user to run a number of scripts written by various people, and manage when each script runs, what keys trigger it's functions, tweak each script's parameters, etc - solely by using a GUI application.
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
If you are a typical end-user of UCR, you just need to download the installer package, unzip it and double-click UCR.exe. No installation is required, and you do not need to install AutoHotkey.  


In order to run UCR un-compiled:
Install AutoHotkey, then take a copy of UCR.exe from the download zip, rename it AutoHotkey.exe and place it in your AutoHotkey install folder. Optionally back up the old AutoHotkey.exe, but the files named like AutoHotkeyA32.exe in your AHK folder are already backups of the normal AHK executables.  

##Debugging UCR
A major design goal of UCR is to make it (and plugins) debuggable. 
Development is currently done using Scite4AutoHotkey, so if you wish to debug UCR or a plugin, that is the advised solution.  
UCR's code avoids the use of SetTimer, OnMessage etc in the main thread wherever possible, so that "stepping in" in the debugger does not end up dropping you into some random timer pseudo-thread. In general, it works around these situations by offloading any code that might interfere with the debugging process to a worker thread.

##Debugging Plugins
If you wish to be able to set breakpoints within a plugin, then you must do the following:  
Place the plugin file in the same folder as UCR.ahk.  
Add the following code to the start of the plugin:  
```
UCRDebugPlugin := "MyPlugin"
#include UCR.ahk
```
Where "MyPlugin" is the class name of your plugin.  
Then you can simply run or debug the plugin from Scite4AHK and it will start up UCR - any breakpoints that you set will trigger, and you can step into the UCR code if you desire.  
When UCR runs in this way, it will use a settings file named for the plugin, eg `MyPlugin.ini', it will not alter the main UCR.ini settings file while you are debuggging a plugin.  
You can only debug one plugin at a time.  

##Documentation
Documentation is forthcoming.
