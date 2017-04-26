# UCR - Universal Control Remapper

![ScreenShot](http://i.imgur.com/pSBxCbc.png)
#[MAIN UCR DOWNLOAD LINK](http://evilc.com/files/ahk/ucr/UCR.zip)
#[Forum thread for news and discussion](https://autohotkey.com/boards/viewtopic.php?t=12249)
##[Historical releases](https://github.com/evilC/UCR/releases)

## About
The aim of UCR is to allow end-users to easily leverage the power of AHK without having to learn to code.  
At it's basest level, think of it as a way for an end-user to run a number of scripts written by various people, and manage when each script runs, what keys trigger it's functions, tweak each script's parameters, etc - solely by using a GUI application.
The primary target audience is gamers, UCR is intended to be able to replicate the functionality that comes with programmable keyboards / mice / joysticks etc.

## Profiles
UCR supports profiles. A number of plugins can be grouped together into a Profile.  
Profiles can also have child profiles, and child profiles can "inherit" the plugins of a parent profile.  
This can be used to create "Shift states" to switch the functionality of inputs.  
In the future, it is also planned to allow profiles to be linked to a specific application - when that application gets the focus, the profile becomes active.

### Command line profile switching
Profiles can be changed through command line parameters when launching UCR through the CLI tool and subsequently to change the profile of the running instance. The syntax for profile switching is `UCR.exe CLI.ahk <ParentProfile> <ChildProfile>`. There are three different methods for changing profiles using the syntax. Passing a valid profile GUID as the `<ParentProfile>` will find and activate the profile. Passing a string, quoted or unquoted, as `<ParentProfile>` will select the first profile matching `<ParentProfile>` (all matches are case insensitive). Passing both `<ParentProfile>` and `<ChildProfile>` will find and select a profile matching the `<ChildProfile>` name with a parent profile matching the `<ParentProfile>` name. The `<ParentProfile>` will be selected as fallback if no `<ChildProfile>` is found.
Example: `UCR.exe CLI.ahk "MAME" "megaman"`

## Plugins
At the core of the design of UCR is the idea of an AHK script as a "Plugin".  
From an end-user's perspective, a plugin is a widget which can perform a small task - eg remap one key to another.  
From a plugin author's point of view, a plugin is simply a text file containing AHK script.
The script contains an AHK class that derives from a base class which is part of the UCR source code.  
Each instance of each plugin gets it's own GUI inside the UCR app when added by a user.
The GuiControls in the Gui can easily be made persistent across runs and you can add special GuiControls that allow the end-user to select the inputs (eg hotkeys) and outputs to configure your script.
There are varios provided methods and mechanisms to get notification of events (eg the profile containing the plugin went active or inactive)  
Pretty much anything that you could normally put in an AHK class should work inside a plugin.  

## Persistent GuiControls
Plugins can call UCR methods to add a GuiControl to their Gui whose value will be remembered between runs of UCR.  
It can be used to allow the end user to tweak the behavior of the plugin that it is part of.

## Inputs and Outputs
Plugins may also contain special GuiControls that allow the end user to bind inputs and outputs.  
Valid inputs are: Keyboard, Mouse, Joystick.  
Valid outputs are: Keyboard, Mouse, vJoy Virtual Joystick (Inc virtual XBox), Titan One hardware  
More inputs and output types can be added through the "IOClass" system - Each IOClass can add items to the UCR Main menu, handles adding of menu items to the Input/Output GuiControls, and handles processing of input and output (eg Calling DLLs).  


## Requirements
If you are a typical end-user of UCR, you just need to download the zip from the releases page, unzip it and double-click UCR.exe. No installation is required, and you do not need to install AutoHotkey.  


In order to run UCR un-compiled:
Install AutoHotkey, then take a copy of UCR.exe from the download zip, rename it AutoHotkey.exe and place it in your AutoHotkey install folder. Optionally back up the old AutoHotkey.exe, but the files named like AutoHotkeyA32.exe in your AHK folder are already backups of the normal AHK executables.  

## Debugging UCR
A major design goal of UCR is to make it (and plugins) debuggable.  
Development is currently done using [SciTE4AutoHotkey](https://autohotkey.com/boards/viewtopic.php?f=6&t=62), so if you wish to debug UCR or a plugin, that is the advised solution.  
Currently the relased version of SciTE4AutoHotkey does not support breakpoints in plugins etc properly, but Lexikos has a fix for this, and I posted instructions [here](https://autohotkey.com/boards/viewtopic.php?p=111383# p111383) on how to apply the fix.  
UCR's code avoids the use of SetTimer, OnMessage etc in the main thread wherever possible, so that "stepping in" in the debugger does not end up dropping you into some random timer pseudo-thread. In general, it works around these situations by offloading any code that might interfere with the debugging process to a worker thread.

## Debugging Plugins
If you wish to be able to set breakpoints within a plugin, then you must do the following:  
Edit `UCRDebug.ahk` and place a line like `# include Plugins\User\MyPlugin.ahk` at the end.  
Also, make sure the line `# Include *iUCRDebug.ahk` in `UCR.ahk` is not commented out.  
This makes the debugger aware of the plugin, and allows you to place breakpoints within it.  
You may debug any number of plugins in this way.  

## Documentation
Please see the [Wiki](https://github.com/evilC/UCR/wiki).
