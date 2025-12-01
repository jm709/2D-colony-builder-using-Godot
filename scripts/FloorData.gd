class_name FloorData
extends Resource

@export var name: String = ""
@export var id: int = 0
@export var coords: Vector2 = Vector2(0,0)

@warning_ignore("native_method_override")
func get_class():
	return "Floor"
