class_name EntityIndex
extends Node

var world: World

# chunk_coord -> { tag -> Array[Vector2] }
var _by_chunk: Dictionary = {}

# chunk_coord -> { tile_pos -> Array[StringName] }
var _tags_by_chunk: Dictionary = {}

func add(tile_pos: Vector2, tags: Array) -> void:
	if world == null:
		push_error("EntityIndex.add called before world set")
		return
	var chunk: Vector2i = world.chunk_of_tile(tile_pos)
	if not _by_chunk.has(chunk):
		_by_chunk[chunk] = {}
		_tags_by_chunk[chunk] = {}
	if _tags_by_chunk[chunk].has(tile_pos):
		remove(tile_pos)
	_tags_by_chunk[chunk][tile_pos] = tags.duplicate()
	for tag in tags:
		var tag_map: Dictionary = _by_chunk[chunk]
		if not tag_map.has(tag):
			tag_map[tag] = []
		tag_map[tag].append(tile_pos)

func remove(tile_pos: Vector2) -> void:
	if world == null:
		return
	var chunk: Vector2i = world.chunk_of_tile(tile_pos)
	if not _tags_by_chunk.has(chunk):
		return
	var tags: Array = _tags_by_chunk[chunk].get(tile_pos, [])
	for tag in tags:
		var arr: Array = _by_chunk[chunk].get(tag, [])
		arr.erase(tile_pos)
		if arr.is_empty():
			_by_chunk[chunk].erase(tag)
	_tags_by_chunk[chunk].erase(tile_pos)

func get_tiles_with_tag(tag: StringName) -> Array:
	var out: Array = []
	for chunk in _by_chunk:
		var hits: Array = _by_chunk[chunk].get(tag, [])
		out.append_array(hits)
	return out

func _on_chunk_loaded(_coord: Vector2i, chunk: Chunk) -> void:
	for local_y in range(chunk.chunk_size):
		for local_x in range(chunk.chunk_size):
			var local := Vector2i(local_x, local_y)
			var tile: CellData = chunk.tile_at(local)
			if tile.building == null:
				continue
			var global_pos := chunk.global_pos_for(local)
			add(global_pos, EntityTags.tags_for(tile.building))

func _on_chunk_unloaded(coord: Vector2i, _chunk: Chunk) -> void:
	_by_chunk.erase(coord)
	_tags_by_chunk.erase(coord)
