/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Uses xHotkey instead of the normal AHK Hotkey command.
https://github.com/Lexikos/xHotkey.ahk

Master Application
*/

#SingleInstance, force

Class UCR {
	Plugins := []	; Array containing plugin objects

	__New(){
		global _UCR_Plugins	; Array of plugin class names

		; Load plugins
		Loop % _UCR_Plugins.MaxIndex() {
			cls := _UCR_Plugins[A_Index]
			this.Plugins.Insert(new %cls%(this))
		}
	}

	; Adds a plugin - likely called before class instantiated, so beware "this"!
	AddPlugin(name){
		global _UCR_Plugins
		if (!_UCR_Plugins.MaxIndex()){
			_UCR_Plugins := []
		}
		_UCR_Plugins.Insert(name)
	}

	; Handle hotkey binding etc
	Class Hotkey {
		__New(parent){
			this.parent := parent
		}

		Add(key,callback)){
			xHotkey(key,this.Bind(callback,this.parent),1)
		}

		Bind(fn, args*) {
		    return new this.BoundFunc(fn, args*)
		}

		class BoundFunc {
		    __New(fn, args*) {
		        this.fn := IsObject(fn) ? fn : Func(fn)
		        this.args := args
		    }
		    __Call(callee) {
		        if (callee = "") {
		            fn := this.fn
		            return %fn%(this.args*)
		        }
		    }
		}


	}

	; Base class to derive from for Plugins
	Class Plugin {
		__New(parent){
			this.parent := parent
		}
	}

}

#include Plugins.ahk
UCR := new UCR()

