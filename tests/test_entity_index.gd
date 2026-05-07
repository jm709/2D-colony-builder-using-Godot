extends RefCounted

func run() -> void:
	print("test_entity_index:")
	_test_add_lookup()
	_test_remove()
	_test_add_dedup()

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
