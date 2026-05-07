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
