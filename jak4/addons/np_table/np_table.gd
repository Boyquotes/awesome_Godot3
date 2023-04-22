extends Resource
class_name DataTable

export(Dictionary) var header: Dictionary
export(Array) var data: Array

func _init(p_header := {}):
	resource_name = "DataTable"
	header = p_header
	data = []
	
	for c in header.keys():
		var type = header[c]
		if !(type is int):
			print_debug(
				"Bad table! Header value '%s' should be an integer, got '%s'"
				 % [c, str(type)])
		elif type < TYPE_NIL || type > TYPE_MAX:
			print_debug("Type value '%s' expected to be a valid type enum value, got %d" 
				% [c, type])

func insert(record: Array):
	var failed_types := 0
	var header_keys := header.keys()
	var i := 0
	
	for field in record:
		var expected = header[header_keys[i]]
		if typeof(field) != expected:
			print_debug("'%s' expected type %d, got type %d (value '%s')"
				% [header_keys[i], expected, typeof(field), str(field)])
			failed_types += 1
		i += 1
	
	if failed_types > 0:
		return
	else:
		_insert(record)

func _insert(record: Array):
	data.append(record)

func to_objects() -> Array:
	var result := []
	for record in data:
		var d := {}
		var i := 0
		for f in record:
			d[header.keys()[i]] = f
			i += 1
		result.append(d)
	return result

func get_by_key(key: String, value) -> DataTable:
	var results := DataTable.new(header)
	var record_index = header.keys().find(key)
	if record_index < 0:
		print_debug("Key does not exist in table: ", key)
		return results
	for d in data:
		if d[record_index] == value:
			results._insert(d)
	return results

func get_where_match(pairs: Dictionary) -> DataTable:
	var results := DataTable.new(header)
	var m := {}
	for k in pairs.keys():
		var idx = header.keys().find(pairs)
		if idx < 0:
			print_debug("key '%s' does not exist", k)
			continue
		m[idx] = pairs[k]
	for record in data:
		var i := 0
		var matches := true
		for f in record:
			if i in m:
				if m[i] != f:
					matches = false
					break
			i += 1
		if matches:
			results._insert(record)
	return results
