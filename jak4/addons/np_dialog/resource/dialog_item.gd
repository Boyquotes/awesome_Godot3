extends Resource
class_name DialogItem

enum Type {
	MESSAGE,
	REPLY,
	NARRATION
}

export(int) var next: int = -1
export(int) var child : int = -1 
export(int) var parent : int = -1
export(Type) var type = Type.MESSAGE
export(String) var text
export(String) var speaker
export(Array) var conditions
