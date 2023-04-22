class_name FrameData

class FunctionProfile:
	var name: String
	var runtime: int
	var start: int
	var end: int
	var parent: FunctionProfile = null
	var children: Array = []
	
	func _init(p_name, p_runtime, p_start, p_end):
		name = str(p_name)
		runtime = int(p_runtime)
		start = int(p_start)
		end = int(p_end)

var frame_time := 0
var top_level_functions : Array

const r_special_data := "([^\\[]+)"
var regex := RegEx.new()

func _init():
	top_level_functions = []
	var _x = regex.compile(r_special_data)

func parse(data: String) -> bool:
	var split := data.split("\n", false, 1)
	if split.size() != 2:
		print_debug("FAILED TO PARSE: ", data)
		return false
	frame_time = int(split[0])

	for line in split[1].split("\n", false):
		var d1:PoolStringArray = line.split(" : ")
		var name_runtime := d1[0].split(" [")
		var name = name_runtime[0]
		var runtime = name_runtime[1].rstrip("] ")
		var start_end = d1[1].split(", ")
		var start = start_end[0]
		var end = start_end[1]
		
		var fp := FunctionProfile.new(name, runtime, start, end)
		var s = top_level_functions.size()
		var remove_after = s
		for i in range(1, s + 1):
			var prev : FunctionProfile = top_level_functions[s - i]
			if (fp.start < prev.start) or (
				fp.start == prev.start and fp.end > prev.end
			):
				prev.parent = fp
				fp.children.push_front(prev)
				remove_after = s - i
			else:
				break
		if remove_after < s:
			top_level_functions.resize(remove_after)
		top_level_functions.push_back(fp)
	return true
