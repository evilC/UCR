Class _InputThread {
	__New(){
		;msgbox new
	}
	
	UpdateBindings(id, bindobj){
		;msgbox % "Adding object of class:" IOBoj.__value.IOClass
		OutputDebug % "UCR| _InputThread.UpdateBindings"
		bindobj.AddBinding()
		/*
		Loop % bindobj.Binding.length() {
			btn := bindobj.Binding[A_Index]
			OutputDebug % "UCR| Adding Button code " btn
			
		}
		*/
	}
}