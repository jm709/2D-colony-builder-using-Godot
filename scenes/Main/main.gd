extends Node2D

const DEFAULT_WORLD_NAME := "default"
const DEFAULT_WORLD_SIZE := Vector2i(16, 16)
const DEFAULT_CHUNK_SIZE := 64

@onready var grid: Grid = $Grid
@onready var gui = get_node("CanvasLayer/GUI")
@onready var camera: GameCamera = $Camera

var world: World
var chunk_loader: ChunkLoader

func _ready():
	get_tree().set_auto_accept_quit(false)
	world = _load_or_create_world()
	chunk_loader = ChunkLoader.new()
	chunk_loader.name = "ChunkLoader"
	chunk_loader.world = world
	add_child(chunk_loader)
	grid.chunk_loader = chunk_loader

	# Pathfinder must add points before Grid inserts tiles + refreshes.
	chunk_loader.chunk_loaded.connect(grid.path._on_chunk_loaded)
	chunk_loader.chunk_loaded.connect(grid._on_chunk_loaded)
	chunk_loader.chunk_unloaded.connect(grid._on_chunk_unloaded)
	chunk_loader.chunk_unloaded.connect(grid.path._on_chunk_unloaded)

	_center_camera_on_spawn()
	camera.setup(chunk_loader, world, grid)

	var spawn_tile := world.spawn_tile()
	for unit in $Grid/Units.get_children():
		if unit is Unit:
			unit.setup(chunk_loader, world, spawn_tile)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if chunk_loader != null:
			chunk_loader.save_dirty()
		get_tree().quit()

func _load_or_create_world() -> World:
	var world_path := "user://saves/%s/world.res" % DEFAULT_WORLD_NAME
	if ResourceLoader.exists(world_path):
		return ResourceLoader.load(world_path) as World
	var w := World.new()
	w.world_name = DEFAULT_WORLD_NAME
	w.size = DEFAULT_WORLD_SIZE
	w.chunk_size = DEFAULT_CHUNK_SIZE
	w.world_seed = randi()
	WorldGenerator.generate_world(w)
	return w

func _center_camera_on_spawn() -> void:
	var spawn := world.spawn_chunk()
	var center_tile := Vector2(
		spawn.x * world.chunk_size + world.chunk_size / 2.0,
		spawn.y * world.chunk_size + world.chunk_size / 2.0
	)
	camera.position = grid.gridToWorld(center_tile)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			var clicked = grid.worldToGrid(grid.get_global_mouse_position())
			var tile = grid.getTileFromGrid(clicked)
			gui.setRClickedObject(tile)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var clicked = grid.worldToGrid(grid.get_global_mouse_position())
			var tile = grid.getTileFromGrid(clicked)
			if tile == gui.getSelectedObject():
				gui.setSelectedObject(null)
			else:
				gui.setSelectedObject(tile)
