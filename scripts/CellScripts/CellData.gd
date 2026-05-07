class_name CellData
extends Object

signal buildingChanged(_pos: Vector2, building)
signal floorChanged(_pos: Vector2)

var pos: Vector2

func _init(_pos: Vector2):
	pos = _pos

var floorData: FloorData :
	set(value):
		floorData = value
		emit_signal("floorChanged", pos)
	get:
		return floorData

var building :
	set(value):
		building = value
		emit_signal("buildingChanged", pos)
	get:
		return building

var occupier = null :
	set(value):
		occupier = value
		#emit_signal("cellChanged", pos)
	get:
		return occupier

var navigable: bool = true

@warning_ignore("native_method_override")
func get_class():
	return "Cell"
