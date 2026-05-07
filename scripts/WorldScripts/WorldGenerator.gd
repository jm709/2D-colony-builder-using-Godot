class_name WorldGenerator
extends Object

const FLOOR_DEEP_WATER := preload("res://data/floor/deepwater.tres")
const FLOOR_SHALLOW_WATER := preload("res://data/floor/shallowwater.tres")
const FLOOR_STONE := preload("res://data/floor/stonefloor_s.tres")
const FLOOR_DIRT := preload("res://data/floor/dirt.tres")
const FLOOR_GRASS := preload("res://data/floor/grass.tres")

static func generate_world(world: World) -> int:
	var dir_err := DirAccess.make_dir_recursive_absolute("%s/chunks" % world.world_dir())
	if dir_err != OK:
		push_error("WorldGenerator: failed to create chunk dir: %d" % dir_err)
		return dir_err

	var meta_err := ResourceSaver.save(world, world.world_metadata_path())
	if meta_err != OK:
		push_error("WorldGenerator: failed to save world.res: %d" % meta_err)
		return meta_err

	var moisture := FastNoiseLite.new()
	moisture.seed = world.world_seed
	var altitude := FastNoiseLite.new()
	altitude.seed = world.world_seed + 1

	for cy in world.size.y:
		for cx in world.size.x:
			var coord := Vector2i(cx, cy)
			var chunk := _generate_chunk(world, coord, moisture, altitude)
			var save_err := ResourceSaver.save(chunk, world.chunk_path(coord))
			if save_err != OK:
				push_error("WorldGenerator: failed to save chunk %s: %d" % [str(coord), save_err])
				return save_err
	return OK

static func _generate_chunk(world: World, coord: Vector2i, moisture: FastNoiseLite, altitude: FastNoiseLite) -> Chunk:
	var chunk := Chunk.new(coord, world.chunk_size)
	var tiles: Array[CellData] = []
	tiles.resize(world.chunk_size * world.chunk_size)
	for local_y in world.chunk_size:
		for local_x in world.chunk_size:
			var global_x: int = coord.x * world.chunk_size + local_x
			var global_y: int = coord.y * world.chunk_size + local_y
			var moist: float = moisture.get_noise_2d(global_x, global_y) * 10.0
			var alt: float = altitude.get_noise_2d(global_x, global_y) * 10.0
			var tile := CellData.new(Vector2(global_x, global_y))
			tile.floorData = _pick_floor(alt, moist)
			tiles[local_y * world.chunk_size + local_x] = tile
	chunk.tiles = tiles
	return chunk

static func _pick_floor(alt: float, moist: float) -> FloorData:
	if alt < 1:
		return FLOOR_DEEP_WATER
	if alt < 2:
		return FLOOR_SHALLOW_WATER
	if alt >= 2 and moist > 5:
		return FLOOR_STONE
	if moist < 2:
		return FLOOR_DIRT
	return FLOOR_GRASS
