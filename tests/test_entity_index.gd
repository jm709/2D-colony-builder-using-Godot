extends RefCounted

const WoodItem = preload("res://data/resources/wood.tres")

func run() -> void:
	print("test_entity_index:")
	_test_add_lookup()
	_test_remove()
	_test_add_dedup()
	_test_chunk_loaded_indexes_buildings()
	_test_chunk_unloaded_clears_chunk()

func _make_world(chunk_size: int = 4) -> World:
	var w := World.new()
	w.world_name = "test"
	w.size = Vector2i(8, 8)
	w.chunk_size = chunk_size
	return w

func _make_index(w: World) -> EntityIndex:
	var idx := EntityIndex.new()
	idx.world = w
	return idx

func _make_chunk(coord: Vector2i, chunk_size: int) -> Chunk:
	var chunk := Chunk.new(coord, chunk_size)
	var tiles: Array[CellData] = []
	tiles.resize(chunk_size * chunk_size)
	for y in chunk_size:
		for x in chunk_size:
			var global_pos := Vector2(coord.x * chunk_size + x, coord.y * chunk_size + y)
			tiles[y * chunk_size + x] = CellData.new(global_pos)
	chunk.tiles = tiles
	return chunk

func _set_tile_building(chunk: Chunk, local_x: int, local_y: int, building) -> void:
	chunk.tiles[local_y * chunk.chunk_size + local_x].building = building

func _test_add_lookup() -> void:
	var w := _make_world()
	var idx := _make_index(w)
	idx.add(Vector2(2, 2), [&"item", &"item_id:6"])
	var hits := idx.get_tiles_with_tag(&"item")
	TestHelpers.expect(Vector2(2, 2) in hits, "add: tile shows up under 'item' tag")
	idx.free()

func _test_remove() -> void:
	var w := _make_world()
	var idx := _make_index(w)
	idx.add(Vector2(2, 2), [&"item", &"item_id:6"])
	idx.remove(Vector2(2, 2))
	TestHelpers.expect(idx.get_tiles_with_tag(&"item").is_empty(), "remove: 'item' tag empty")
	TestHelpers.expect(idx.get_tiles_with_tag(&"item_id:6").is_empty(), "remove: 'item_id:6' tag empty")
	idx.free()

func _test_add_dedup() -> void:
	var w := _make_world()
	var idx := _make_index(w)
	idx.add(Vector2(2, 2), [&"item"])
	idx.add(Vector2(2, 2), [&"item"])
	var hits := idx.get_tiles_with_tag(&"item")
	TestHelpers.expect_eq(hits.size(), 1, "add: same tile twice does not duplicate")
	idx.free()

func _test_chunk_loaded_indexes_buildings() -> void:
	var w := _make_world()
	var idx := _make_index(w)
	var chunk := _make_chunk(Vector2i(0, 0), 4)
	_set_tile_building(chunk, 1, 2, ItemStack.new(WoodItem, 3))
	idx._on_chunk_loaded(Vector2i(0, 0), chunk)
	var hits := idx.get_tiles_with_tag(&"item_id:6")
	TestHelpers.expect(Vector2(1, 2) in hits, "chunk_loaded: ItemStack indexed")
	idx.free()

func _test_chunk_unloaded_clears_chunk() -> void:
	var w := _make_world()
	var idx := _make_index(w)
	var chunk := _make_chunk(Vector2i(0, 0), 4)
	_set_tile_building(chunk, 1, 2, ItemStack.new(WoodItem, 3))
	idx._on_chunk_loaded(Vector2i(0, 0), chunk)
	idx._on_chunk_unloaded(Vector2i(0, 0), chunk)
	TestHelpers.expect(idx.get_tiles_with_tag(&"item_id:6").is_empty(), "chunk_unloaded: tag cleared")
	TestHelpers.expect(not idx._by_chunk.has(Vector2i(0, 0)), "chunk_unloaded: _by_chunk entry erased")
	TestHelpers.expect(not idx._tags_by_chunk.has(Vector2i(0, 0)), "chunk_unloaded: _tags_by_chunk entry erased")
	idx.free()
