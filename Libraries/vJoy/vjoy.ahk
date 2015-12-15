#include Libraries\vjoy\CvJoyInterface.ahk

class vJoy extends CvJoyInterface {
	_UCR_LoadLibrary(){
		if (this.vJoyEnabled()){
			return 1
		} else {
			return this.LoadLibraryLog
		}
	}
}
