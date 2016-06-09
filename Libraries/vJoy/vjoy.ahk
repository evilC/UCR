#include Libraries\vjoy\CvJoyInterface.ahk

class vJoy extends CvJoyInterface {
	_UCR_LoadLibrary(){
		if (this.vJoyEnabled()){
			this.SingleStickMode := 0
			return 1
		} else {
			return this.LoadLibraryLog
		}
	}
}
