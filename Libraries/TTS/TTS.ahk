; Based on code by Learning one. For AHK_L. Thanks: jballi, Sean, Frankie.
; AHK forum location:	www.autohotkey.com/forum/topic57773.html
; Read more:			msdn.microsoft.com/en-us/library/ms723602(v=VS.85).aspx, www.autohotkey.com/forum/topic45471.html, www.autohotkey.com/forum/topic83162.html
Class TTS {
	VoiceList := []		; An indexed array of the available voice names
	VoiceAssoc := {}	; An Associative array of voice names, key = voice name, value = voice index (VoiceList lookup)
	VoiceCount := 0		; The number of voices available
	VoiceNumber := 0	; The number of the current voice
	VoiceName := ""		; The name of the current voice
	
	__New(){
		this.oVoice := ComObjCreate("SAPI.SpVoice")
		this._GetVoices()
		this.SetVoice(this.VoiceList.1)
	}

	; speak or stop speaking
	ToggleSpeak(text){
		Status := this.oVoice.Status.RunningState
		if Status = 1	; finished
		this.oVoice.Speak(text,0x1)	; speak asynchronously
		Else if Status = 0	; paused
		{
			this.oVoice.Resume
			this.oVoice.Speak("",0x1|0x2)	; stop
			this.oVoice.Speak(text,0x1)	; speak asynchronously
		}
		Else if Status = 2	; reading
		this.oVoice.Speak("",0x1|0x2)	; stop
	}

	; speak asynchronously
	Speak(text){
		Status := this.oVoice.Status.RunningState
		if Status = 0	; paused
		this.oVoice.Resume
		this.oVoice.Speak("",0x1|0x2)	; stop
		this.oVoice.Speak(text,0x1)	; speak asynchronously
	}
	
	; speak synchronously
	SpeakWait(text){
		Status := this.oVoice.Status.RunningState
		if Status = 0	; paused
		this.oVoice.Resume
		this.oVoice.Speak("",0x1|0x2)	; stop
		this.oVoice.Speak(text,0x0)	; speak synchronously
	}
	
	; Pause toggle
	Pause(){
		Status := this.oVoice.Status.RunningState
		if Status = 0	; paused
		this.oVoice.Resume
		else if Status = 2	; reading
		this.oVoice.Pause
	}
	
	Stop(){
		Status := this.oVoice.Status.RunningState
		if Status = 0	; paused
		this.oVoice.Resume
		this.oVoice.Speak("",0x1|0x2)	; stop
	}
	
	; rate (reading speed): rate from -10 to 10. 0 is default.
	SetRate(rate){
		this.oVoice.Rate := rate
	}
	
	; volume (reading loudness): vol from 0 to 100. 100 is default
	SetVolume(vol){
		this.oVoice.Volume := vol
	}
	
	; pitch : From -10 to 10. 0 is default.
	; http://msdn.microsoft.com/en-us/library/ms717077(v=vs.85).aspx
	SetPitch(pitch){
		this.oVoice.Speak("<pitch absmiddle = '" pitch "'/>",0x20)
	}

	; Set voice by name
	SetVoice(VoiceName){
		if (!ObjHasKey(this.VoiceAssoc, VoiceName))
			return 0
		While !(this.oVoice.Status.RunningState = 1)
		Sleep, 20
		this.oVoice.Voice := this.oVoice.GetVoices("Name=" VoiceName).Item(0) ; set voice to param1
		this.VoiceName := VoiceName
		this.VoiceNumber := this.VoiceAssoc[VoiceName]
		return 1
	}

	; Set voice by index
	SetVoiceByIndex(VoiceIndex){
		return this.SetVoice(this.VoiceList[VoiceIndex])
	}

	; Use the next voice. Loops around at end
	NextVoice(){
		v := this.VoiceNumber + 1
		if (v > this.VoiceCount)
			v := 1
		return this.SetVoiceByIndex(v)
	}
	
	; Returns an array of voice names
	GetVoices(){
		return this.VoiceList
	}

	GetStatus(){
		Status := this.oVoice.Status.RunningState
		if Status = 0 ; paused
		Return "paused"
		Else if Status = 1 ; finished
		Return "finished"
		Else if Status = 2 ; reading
		Return "reading"
	}
	
	GetCount(){
		return this.VoiceCount
	}
	
	SpeakToFile(param1, param2){
		oldAOS := this.oVoice.AudioOutputStream
		oldAAOFCONS := this.oVoice.AllowAudioOutputFormatChangesOnNextSet
		this.oVoice.AllowAudioOutputFormatChangesOnNextSet := 1	
		
		SpStream := ComObjCreate("SAPI.SpFileStream")
		FileDelete, % param2	; OutputFilePath
		SpStream.Open(param2, 3)
		this.oVoice.AudioOutputStream := SpStream
		this.TTS("SpeakWait", param1)
		SpStream.Close()
		this.oVoice.AudioOutputStream := oldAOS
		this.oVoice.AllowAudioOutputFormatChangesOnNextSet := oldAAOFCONS
	}

	; ====== Private funcs, not intended to be called by user =======
	_GetVoices(){
		this.VoiceList := []
		this.VoiceAssoc := {}
		this.VoiceCount := this.oVoice.GetVoices.Count
		Loop, % this.VoiceCount
		{
			Name := this.oVoice.GetVoices.Item(A_Index-1).GetAttribute("Name")	; 0 based
			this.VoiceList.push(Name)
			this.VoiceAssoc[Name] := A_Index
		}
	}
	
	_UCR_LoadLibrary(){
		return 1
	}
}