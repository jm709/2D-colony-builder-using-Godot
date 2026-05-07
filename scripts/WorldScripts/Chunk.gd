class_name Chunk
extends Resource

@export var coord: Vector2i = Vector2i.ZERO
@export var chunk_size: int = 64
@export var tiles: Array[CellData] = []
@export var wildlife: Array = []  # Reserved; populated when UnitData becomes a Resource.

var dirty: bool = false

func _init(_coord: Vector2i = Vector2i.ZERO, _chunk_size: int = 64) -> void:
	coord = _coord
	chunk_size = _chunk_size

func tile_at(local: Vector2i) -> CellData:
	return tiles[local.y * chunk_size + local.x]

func global_pos_for(local: Vector2i) -> Vector2:
	return Vector2(coord.x * chunk_size + local.x, coord.y * chunk_size + local.y)

func mark_dirty() -> void:
	dirty = true
