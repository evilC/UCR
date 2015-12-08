/*
MessageFilter Thread

Provides a message monitoring service to another thread.
Can perform basic filtering of incoming messages, thus making the master thread easier to debug
example syntax from calling thread:

this.ahkdll:=AhkThread(A_ScriptDir "\somefile.ahk",,1)
[...]
Callback := this.somefunc.Bind(this)
MatchObj := {hwnd: hwnd, msg: 123}
FilterObj := {lParam: hwnd}
this.ahkdll.ahkExec("Filter1 := new MessageFilter(" &Callback "," &MatchObj "," &FilterObj ")")

Constructor parameters:
CallbackPtr:	A *pointer* to a BoundFunc object (number)
	If the filter passes, this boundfunc object will be executed in the main thread...
	... and passed the wParam,lParam,msg,hwnd params that were passed to the Message Handler.
matchobj:		A pointer to an object that defines the parameters used for the OnMessage command
	Valid properties: msg, hwnd
filterobj: 		A pointer to an object that defines the parameters to match in the OnMessage call
	Valid properties: wParam,lParam,msg,hwnd
*/
#Persistent
SetBatchLines,-1
autoexecute_done := 1
return
Class MessageFilter {
	__New(CallbackPtr, matchobj, filterobj){
		; Copy passed parameter objects before they go out of scope
		this.MatchObj := Object(matchobj)
		this.MatchObj := this.MatchObj.Clone()
		
		this.FilterObj := Object(filterobj)
		this.FilterObj := this.FilterObj.Clone()
		
		this.MasterThread := AhkExported()		; Get link back to calling thread
		this.CallbackPtr := CallbackPtr
		
		; Execute an OnMessage command in the master thread, but pass it a boundfunc in this thread
		this.MessageHandlerFn := this.MessageHandler.Bind(this)
		this.MasterThread.AhkExec("OnMessage(" this.MatchObj.msg "," this.MatchObj.hwnd ",Object(" &this.MessageHandlerFn "))")
	}
	
	MessageHandler(wParam,lParam,msg,hwnd){
		; Filter out unwanted messages
		for key, value in this.FilterObj {
			if (%key% != value){
				return
			}
		}
		; Filters passed - execute boundfunc callback in main thread and pass it the message
		this.MasterThread.AhkExec("fn := Object(" this.CallbackPtr ")`nfn.Call(" wParam "," lParam "," msg "," hwnd ")")
	}
}
