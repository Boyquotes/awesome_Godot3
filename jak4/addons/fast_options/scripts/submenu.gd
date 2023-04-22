extends Panel

func grab_focus():
	for child in $scroll/list.get_children():
		if child is Control:
			child.grab_focus()
			return
