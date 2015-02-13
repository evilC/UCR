/*
Message Handler.ahk - classify OnMessage

instantiate once, then register messages using RegisterMessage

Pass parent class in constructor!
eg myMessageHandler := new _UCR_C_MessageHandler(this)
*/

Class _UCR_C_MessageHandler extends _UCR_C_Common {
	MessageTable := {}
	
	ProcessMessage(wParam, lParam, msg, hwnd){
		obj := this.MessageTable[msg].object
		obj[this.MessageTable[msg].method](wParam, lParam, msg, hwnd)
	}
	
	; Register a message to a class method.
	; Defaults to method of parent class, but can be overridden by specifying object param
	RegisterMessage(msg, method, object := ""){
		if (!object){
			object := this.parent
		}
		this.MessageTable[msg] := {object: object, method: method}
		OnMessage(msg, "_UCR_MessageHandler")
	}
}

; OnMessage only supports global funcs for now, so route messages back into class.
_UCR_MessageHandler(wParam, lParam, msg, hwnd){
	; Bit of a dirty hack; - var names hard-coded.
	global UCR
	; Dirtier hack - Message handler instance hard-coded
	UCR.MessageHandler.ProcessMessage(wParam, lParam, msg, hwnd)
}
