class_name CellData
extends Object

var grid = Grid

signal buildingChanged(_pos: Vector2, building)
signal floorChanged(_pos: Vector2)
signal navChanged(_pos: Vector2)

func _ready():
	floorChanged.connect(grid.refreshTile)
	buildingChanged.connect(grid.updateTile)

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

var naviagable: bool = true :
	set(value):
		naviagable = value
		#emit_signal("navChanged", pos)
	get:
		return naviagable
		
@warning_ignore("native_method_override")
func get_class():
	return "Cell"
