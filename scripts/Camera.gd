extends Camera2D
class_name GameCamera

const CHUNK_RADIUS := 1

var zoomSpeed: float = 0.05
var zoomMin: float = 0.005
var zoomMax: float = 2.0
var dragSensitivity: float = 1.0

var chunk_loader: ChunkLoader
var world: World
var grid: Grid
var _pinned: Dictionary = {}  # Vector2i -> true; chunks the camera is currently pinning
var _last_center: Vector2i = Vector2i(-99999, -99999)

func setup(loader: ChunkLoader, w: World, grid_ref: Grid) -> void:
	chunk_loader = loader
	world = w
	grid = grid_ref
	_last_center = Vector2i(-99999, -99999)
	_update_pins()

func _process(_delta: float) -> void:
	_update_pins()

func _update_pins() -> void:
	if chunk_loader == null or world == null or grid == null:
		return
	var tile := grid.worldToGrid(position)
	var center := world.chunk_of_tile(tile)
	if center == _last_center:
		return
	var new_set: Dictionary = {}
	for dy in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
		for dx in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
			var c := center + Vector2i(dx, dy)
			if world.contains_chunk(c):
				new_set[c] = true
	for c in new_set.keys():
		if not _pinned.has(c):
			chunk_loader.pin(c)
			_pinned[c] = true
	for c in _pinned.keys():
		if not new_set.has(c):
			chunk_loader.unpin(c)
			_pinned.erase(c)
	_last_center = center

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		position -= event.relative * dragSensitivity / zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoomSpeed, zoomSpeed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoomSpeed, zoomSpeed)
		zoom = clamp(zoom, Vector2(zoomMin, zoomMin), Vector2(zoomMax, zoomMax))
