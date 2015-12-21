/*
Library for performing various Joystick-related operations
eg Invert, Deadzone etc.
*/
class StickOps {
	_UCR_LoadLibrary(){
		return 1
	}
	
	; Number Scale conversion
	AHKToInternal(value){
		return value - 50
	}
	
	InternalToAHK(value){
		return value + 50
	}
	
	AHKToVjoy(value){
		return value * 327.67
	}
	
	InternalToVjoy(value){
		value += 50
		return value * 327.67
	}
	
	; Helper funcs
	; Detects the sign (+ or -) of a number and returns a multiplier for that sign
	sign(input){
		if (input < 0){
			return -1
		} else {
			return 1
		}
	}
	
	; Axis operations. All work on internal scale! (-50 to +50)
	Invert(value){
		return value * -1
	}
	
	; Adjust axis for deadzone
	; dzp: Deadzone percent. 0% is "normal"
	Deadzone(value, dzp){
		dzp := dzp/2
		if (abs(value) <= dzp){
			return 0
		} else {
			return this.sign(value)*50*(abs(value)-dzp)/(50-dzp)
		}
	}
	
	; Adjust axis for sensitivity
	; sp: Sensitivity, in percent. 100% is "normal".
	Sensitivity(value, sp){
		if (sp == 100){
			return value
		} else {
			sens := sp/100 ; Shift sensitivity to 0 -> 1 scale
			value := value/50	; Shift input value to -1 -> +1 scale
			value := (sens*value)+((1-sens)*value**3)	; Perform sensitivity calc
			value := value*50	; Shift back to -50 -> 50 scale
		}
		return value
	}
	
	
}