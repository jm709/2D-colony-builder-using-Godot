class_name Grid
extends TileMap

@export var width: int = 12
@export var height: int = 12
@export var cell_size: int = 128

var grid: Dictionary = {}
@onready var path : Pathfinder = get_node("Pathfinding")

@export var show_debug: bool = false
func generateGrid():
	for x in width:
		for y in height:
			grid[Vector2(x,y)] = CellData.new(Vector2(x,y))
			grid[Vector2(x,y)].floorData = preload("res://data/floor/grass.tres")
			grid[Vector2(x,y)].buildingData = null
			#grid[Vector2(x,y)].buildingData = preload("res://data/building/tree.tres")
			refreshTile(Vector2(x,y))
			if show_debug:
				var rect = ReferenceRect.new()
				rect.position = gridToWorld(Vector2(x,y))
				rect.size = Vector2(cell_size, cell_size)
				rect.editor_only = false
				$Debug.add_child(rect)
				var label = Label.new()
				label.position = gridToWorld(Vector2(x,y))
				label.text = str(Vector2(x,y))
				$Debug.add_child(label)
			
func gridToWorld(_pos: Vector2) -> Vector2:
	return _pos * cell_size
	
func worldToGrid(_pos: Vector2) -> Vector2:
	return floor(_pos / cell_size)

func updateTile(_pos: Vector2, _object) -> void:
	grid[Vector2(_pos.x,_pos.y)].buildingData = _object
	grid[Vector2(_pos.x,_pos.y)].naviagable = false
	refreshTile(_pos)

func refreshTile(_pos: Vector2) -> void:
	var data = grid[_pos]
	set_cell(0, _pos, data.floorData.id, data.floorData.coords)
	if data.buildingData == null:
		set_cell(1, _pos)
	else:
		set_cell(1, _pos, data.buildingData.id, data.buildingData.coords)
	if data.naviagable == false:
		path.disconnectPoint(_pos)
