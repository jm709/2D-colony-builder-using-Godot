class_name Grid
extends TileMap

@export var cell_size: int = 128

var grid: Dictionary = {}
@onready var path : Pathfinder = get_node("Pathfinding")
@onready var main = get_tree().root.get_node("Main")
@onready var gui = main.get_node("CanvasLayer/GUI")
@onready var itemOverlay = get_node("ItemOverlay")

@onready var findX : Dictionary = {}

var chunk_loader: ChunkLoader = null

@export var show_debug: bool = false

signal unitSelected(obj)

func _ready():
	unitSelected.connect(gui.setSelectedObject)

func gridToWorld(_pos: Vector2) -> Vector2:
	return _pos * cell_size
	
func worldToGrid(_pos: Vector2) -> Vector2:
	return floor(_pos / cell_size)
	
func getTileFromGrid(_pos: Vector2):
	return grid.get(Vector2(_pos.x, _pos.y), null)
	
func updateTile(_pos: Vector2, _object) -> void:
	var is_item = _object is ItemStack
	if is_item:
		grid[_pos].building = _object
		grid[_pos].navigable = _object.item.navigable
		itemOverlay.set_stack(_pos, _object.CurrentAmount, gridToWorld(_pos))
		addFindable(_pos, str(_object.id))
	else:
		grid[_pos].building = _object
		grid[_pos].navigable = _object.navigable
		addFindable(_pos, _object.get_class())
	refreshTile(_pos)
	if chunk_loader != null:
		chunk_loader.mark_dirty(_pos)

func removeBuilding(_pos):
	var building = grid[_pos].building
	var key
	if building is ItemStack:
		itemOverlay.set_stack(_pos, 0, gridToWorld(_pos))
		key = building.id
	else:
		key = building.get_class()
	rmvFindable(_pos, str(key))
	grid[_pos].building = null
	if chunk_loader != null:
		chunk_loader.mark_dirty(_pos)

func refreshTile(_pos: Vector2) -> void:
	var data = grid[_pos]
	set_cell(0, _pos, data.floorData.id, data.floorData.coords)
	if data.building == null:
		set_cell(1, _pos)
		data.navigable = true
		path.connectPoint(_pos)
	else:
		set_cell(1, _pos, data.building.id, data.building.coords)
		if data.navigable:
			path.connectPoint(_pos)
		else:
			path.disconnectPoint(_pos)
		
func addFindable(_pos: Vector2, thing):
	if (str(thing) in findX):
		findX[str(thing)].append(_pos)
	else:
		findX[str(thing)] = [_pos]

func rmvFindable(_pos: Vector2, thing):
	findX[str(thing)].erase(_pos)

func _on_chunk_loaded(_coord: Vector2i, chunk: Chunk) -> void:
	for local_y in range(chunk.chunk_size):
		for local_x in range(chunk.chunk_size):
			var local := Vector2i(local_x, local_y)
			var global_pos := chunk.global_pos_for(local)
			var tile: CellData = chunk.tile_at(local)
			grid[global_pos] = tile
			refreshTile(global_pos)
			var building = tile.building
			if building == null:
				continue
			if building is ItemStack:
				addFindable(global_pos, str(building.id))
				itemOverlay.set_stack(global_pos, building.CurrentAmount, gridToWorld(global_pos))
			else:
				addFindable(global_pos, building.get_class())

func _on_chunk_unloaded(_coord: Vector2i, chunk: Chunk) -> void:
	for local_y in range(chunk.chunk_size):
		for local_x in range(chunk.chunk_size):
			var local := Vector2i(local_x, local_y)
			var global_pos := chunk.global_pos_for(local)
			var tile: CellData = chunk.tile_at(local)
			set_cell(0, global_pos)
			set_cell(1, global_pos)
			var building = tile.building
			if building != null:
				if building is ItemStack:
					rmvFindable(global_pos, str(building.id))
					itemOverlay.set_stack(global_pos, 0, gridToWorld(global_pos))
				else:
					rmvFindable(global_pos, building.get_class())
			grid.erase(global_pos)
