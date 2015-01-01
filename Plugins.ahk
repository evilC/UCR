/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Example plugin(s)
*/

UCR.AddPlugin("Test")

Class Test extends UCR.Plugin {
	__New(parent){
		base.__New(parent)
		this.h1 := new this.parent.Hotkey(this)
		this.h1.Add("~a",this.test)
	}

	Test(){
		soundbeep
	}

	DownEvent(){

	}
}
