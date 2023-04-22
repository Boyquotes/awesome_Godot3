tool
extends EditorScript

const group := "hard"

func _run():
	var c:Chunk = get_scene()
	if !c:
		return
	var changed = recursive_apply(c)
	print("Changed ", changed, " nodes")

func recursive_apply(n:Node) -> int:
	var running_count := 0
	
	if n is PhysicsBody:
		n.add_to_group(group)
		running_count += 1
		
	for c in n.get_children():
		running_count += recursive_apply(c)
		
	return running_count
