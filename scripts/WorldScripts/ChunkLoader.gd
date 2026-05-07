class_name ChunkLoader
extends Node

const AUTOSAVE_INTERVAL := 60.0

signal chunk_loaded(coord: Vector2i, chunk: Chunk)
signal chunk_unloaded(coord: Vector2i, chunk: Chunk)

var world: World

var loaded: Dictionary = {}       # Vector2i -> Chunk
var _refcounts: Dictionary = {}   # Vector2i -> int
var _autosave_elapsed: float = 0.0

func _process(delta: float) -> void:
	_autosave_elapsed += delta
	if _autosave_elapsed >= AUTOSAVE_INTERVAL:
		_autosave_elapsed = 0.0
		save_dirty()

func mark_dirty(tile_pos: Vector2) -> void:
	if world == null:
		return
	var coord: Vector2i = world.chunk_of_tile(tile_pos)
	var chunk: Chunk = loaded.get(coord, null)
	if chunk != null:
		chunk.dirty = true

func pin(coord: Vector2i) -> void:
	if world == null:
		push_error("ChunkLoader.pin called before world set")
		return
	if not world.contains_chunk(coord):
		return
	var rc: int = _refcounts.get(coord, 0) + 1
	_refcounts[coord] = rc
	if rc == 1:
		_load(coord)

func unpin(coord: Vector2i) -> void:
	if not _refcounts.has(coord):
		return
	var rc: int = _refcounts[coord] - 1
	if rc <= 0:
		_refcounts.erase(coord)
		_unload(coord)
	else:
		_refcounts[coord] = rc

func is_loaded(coord: Vector2i) -> bool:
	return loaded.has(coord)

func get_chunk(coord: Vector2i) -> Chunk:
	return loaded.get(coord, null)

func save_dirty() -> void:
	for coord in loaded.keys():
		var chunk: Chunk = loaded[coord]
		if chunk.dirty:
			_save(chunk)

func save_all_loaded() -> void:
	for coord in loaded.keys():
		_save(loaded[coord])

func _load(coord: Vector2i) -> void:
	var path: String = world.chunk_path(coord)
	if not ResourceLoader.exists(path):
		push_error("ChunkLoader: missing chunk file %s" % path)
		_refcounts.erase(coord)
		return
	var chunk: Chunk = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Chunk
	if chunk == null:
		push_error("ChunkLoader: failed to load chunk %s" % path)
		_refcounts.erase(coord)
		return
	loaded[coord] = chunk
	chunk_loaded.emit(coord, chunk)

func _unload(coord: Vector2i) -> void:
	var chunk: Chunk = loaded.get(coord)
	if chunk == null:
		return
	if chunk.dirty:
		_save(chunk)
	chunk_unloaded.emit(coord, chunk)
	loaded.erase(coord)

func _save(chunk: Chunk) -> void:
	var path: String = world.chunk_path(chunk.coord)
	var dir_path: String = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var err: int = ResourceSaver.save(chunk, path)
	if err != OK:
		push_error("ChunkLoader: failed to save chunk %s: %d" % [str(chunk.coord), err])
		return
	chunk.dirty = false
