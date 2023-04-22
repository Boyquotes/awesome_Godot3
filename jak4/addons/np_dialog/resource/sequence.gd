extends Resource

export(Dictionary) var dialog
export(Dictionary) var labels

# Dumb hack to fix "otherwise" logic.
# I have to track when failed_next returns an ancestor
# Because that resets "otherwise"
var went_up := false

func _init():
	resource_name = "NPSequence"

func get(index) -> DialogItem:
	if index is String:
		if !(index in labels):
			return null
		index = labels[index]
	if !(index in dialog):
		return null
	return dialog[index]

func next(item) -> DialogItem:
	if !(item is DialogItem):
		item = get(item)
	if !(item.next in dialog):
		return null
	return dialog[item.next]

func child(item) -> DialogItem:
	if !(item is DialogItem):
		item = get(item)
	if !(item.child in dialog):
		return null
	return dialog[item.child]
	
func parent(item) -> DialogItem:
	if !(item is DialogItem):
		item = get(item)
	if !(item.parent in dialog):
		return null
	return dialog[item.parent]

func canonical_next(item) -> DialogItem:
	if !(item is DialogItem):
		item = get(item)
	if !item:
		return null
	var c := child(item)
	if c:
		return c
	return _next_at_or_up(item)

# Next item at the same level or higher
func _next_at_or_up(item) -> DialogItem:
	if !item:
		return null
	
	# A reply's next item is after any other replies on the same level
	if item.type == DialogItem.Type.REPLY:
		var nrep := next(item)
		while nrep:
			if nrep.type != DialogItem.Type.REPLY:
				return nrep
			nrep = next(nrep)
	else:
		var n := next(item)
		if n:
			return n
	went_up = true
	return _next_at_or_up(parent(item))

# When failing a check, the next item is at the same level or higher
func failed_next(item) -> DialogItem:
	went_up = false
	return _next_at_or_up(item)
