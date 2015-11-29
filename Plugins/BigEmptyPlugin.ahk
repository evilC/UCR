/*
Used for debugging of Profile scrollbars. A big, empty plugin
*/
class BigEmptyPlugin extends _Plugin {
	Init(){
		Gui, Add, Text, xm ym w500 h500, % "Big Empty Plugin"
	}
}