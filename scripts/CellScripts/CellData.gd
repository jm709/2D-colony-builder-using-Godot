class_name CellData
extends Resource

signal buildingChanged(_pos: Vector2, building)
signal floorChanged(_pos: Vector2)

@export var pos: Vector2
@export var floorData: FloorData :
	set(value):
		floorData = value
		emit_signal("floorChanged", pos)
	get:
		return floorData

@export var building: Resource :
	set(value):
		building = value
		emit_signal("buildingChanged", pos)
	get:
		return building

@export var navigable: bool = true

var occupier = null

func _init(_pos: Vector2 = Vector2.ZERO):
	pos = _pos

@warning_ignore("native_method_override")
func get_class():
	return "Cell"
