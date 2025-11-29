class_name CellData
extends Object

signal cellChanged(_pos: Vector2)
signal navChanged(_pos: Vector2)

var pos: Vector2

func _init(_pos: Vector2):
	pos = _pos

var floorData: FloorData :
	set(value):
		floorData = value
		emit_signal("cellChanged", pos)
	get:
		return floorData

var buildingData : BuildingData :
	set(value):
		buildingData = value
		emit_signal("cellChanged", pos)
	get:
		return buildingData

var occupier = null :
	set(value):
		occupier = value
		emit_signal("cellChanged", pos)
	get:
		return occupier

var naviagable: bool = true :
	set(value):
		naviagable = value
		emit_signal("navChanged", pos)
	get:
		return naviagable
