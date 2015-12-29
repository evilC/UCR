/*
Used for debugging of Profile scrollbars. A big, empty plugin
*/
class BigEmptyPlugin extends _Plugin {
	Type := "Big, Empty Plugin"
	Description := "Doesn't do anything, just takes up space and helps test scrollable GUIs"
	Init(){
		Gui, Add, Text, xm ym w500 h500, % "Big Empty Plugin"
	}
}