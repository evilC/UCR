		/*
		menu := this.ParentControl.AddSubMenu("Titan Axis", "TitanAxis")
		offset := 100
		Loop 6 {
			str := ""
			TitanAxes := UCR.Libraries.Titan.GetAxisNames()
			axis := A_Index
			str := " ( ", i := 0
			for console, axes in TitanAxes {
				if (!axes[axis])
					continue
				if (i){
					str .= " / "
				}
				str .= console " " axes[axis]
				i++
			}
			str .= ")"

			;names := GetAxisNames
			menu.AddMenuItem(A_Index str, A_Index, this._ChangedValue.Bind(this, offset + A_Index))
		}
		
		
		
				state := Round(state/327.67)
				UCR.Libraries.Titan.SetAxisByIndex(this.__value.Axis, state)
		
		*/