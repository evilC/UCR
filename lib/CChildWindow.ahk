#include <CWindow>

Class CChildWindow extends CWindow
{
	__New(parent, title, options)
	{
		this.parent := parent
		base.__New(title, options . " +Parent" parent.__Handle)
	}
}
