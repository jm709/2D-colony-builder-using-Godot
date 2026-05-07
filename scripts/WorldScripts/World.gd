class_name World
extends Resource

const VERSION := 1

@export var world_name: String = ""
@export var size: Vector2i = Vector2i(16, 16)  # in chunks
@export var chunk_size: int = 64
@export var world_seed: int = 0
@export var version: int = VERSION

func chunk_path(coord: Vector2i) -> String:
	return "user://saves/%s/chunks/%d_%d.res" % [world_name, coord.x, coord.y]

func world_dir() -> String:
	return "user://saves/%s" % world_name

func world_metadata_path() -> String:
	return "%s/world.res" % world_dir()

func units_path() -> String:
	return "%s/units.res" % world_dir()

func contains_chunk(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < size.x and coord.y >= 0 and coord.y < size.y

func chunk_of_tile(tile_pos: Vector2) -> Vector2i:
	return Vector2i(floori(tile_pos.x / float(chunk_size)), floori(tile_pos.y / float(chunk_size)))

func spawn_chunk() -> Vector2i:
	return Vector2i(size.x / 2, size.y / 2)

func spawn_tile() -> Vector2:
	return Vector2(spawn_chunk().x * chunk_size + chunk_size / 2.0, spawn_chunk().y * chunk_size + chunk_size / 2.0)
