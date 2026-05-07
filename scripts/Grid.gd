class_name Grid
extends TileMap

@export var cell_size: int = 128

var grid: Dictionary = {}
@onready var path : Pathfinder = get_node("Pathfinding")
@onready var main = get_tree().root.get_node("Main")
@onready var gui = main.get_node("CanvasLayer/GUI")
@onready var itemOverlay = get_node("ItemOverlay")

@onready var findX : Dictionary = {}

var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude =  FastNoiseLite.new()

# chunk dimensions in number of tiles
var chunk_x = 128 
var chunk_y = 128

signal unitSelected(obj)

func _ready():
	unitSelected.connect(gui.setSelectedObject)

func _initializeNoise():
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()

@export var show_debug: bool = false

func generateChunk():
	var tile_pos = worldToGrid(Vector2(0,0))
	for x in range(chunk_x):
		for y in range(chunk_y):
			grid[Vector2(x,y)] = CellData.new(Vector2(x,y))
			
			var world_x = tile_pos.x - chunk_x / 2 + x
			var world_y = tile_pos.y - chunk_y / 2 + y
			
			var moist = moisture.get_noise_2d(world_x, world_y) * 10
			var temp = temperature.get_noise_2d(world_x, world_y) * 10
			var alt = altitude.get_noise_2d(world_x, world_y) * 10
			
			if alt < 1:
				grid[Vector2(x,y)].floorData = preload("res://data/floor/deepwater.tres")
			elif alt < 2:
				grid[Vector2(x,y)].floorData = preload("res://data/floor/shallowwater.tres")
			elif alt >= 2 and moist > 5:
				grid[Vector2(x,y)].floorData = preload("res://data/floor/stonefloor_s.tres")
			else:
				if moist < 2:
					grid[Vector2(x,y)].floorData = preload("res://data/floor/dirt.tres")
				else:
					grid[Vector2(x,y)].floorData = preload("res://data/floor/grass.tres")
			grid[Vector2(x,y)].building = null
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
	
func getTileFromGrid(_pos: Vector2):
	return grid[Vector2(_pos.x,_pos.y)]
	
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
