# EntityIndex Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `Grid.findX` (a string-keyed flat dictionary scanned linearly on every query) with an `EntityIndex` Node that stores findables per chunk under multiple tags and answers nearest-match queries with a Chebyshev-ring spiral.

**Architecture:** A new `EntityIndex` Node lives under `Main`, holds two per-chunk dictionaries (`_by_chunk`: chunk → tag → tile array; `_tags_by_chunk`: chunk → tile → tag array), and listens to `ChunkLoader.chunk_loaded` / `chunk_unloaded`. Bulk inserts happen on chunk load by walking each tile's building. Incremental updates from `Grid.updateTile` / `Grid.removeBuilding` call `entity_index.add(pos, tags)` / `remove(pos)`. Unload is O(1) — erase both per-chunk entries. Tag composition is centralized in a static `EntityTags` helper. Spiral query iterates ring-by-ring (Chebyshev distance) and returns the nearest hit in the first non-empty ring.

**Tech Stack:** GDScript (Godot 4.5), no new dependencies. Tests are headless `.gd` scripts run via `godot --headless --script <path>` using `assert()`-style helpers — no GUT, no third-party test framework.

**Spec reference:** GitHub issue #1 ("Replace findX with chunk-aware EntityIndex").

---

## File Structure

**Created:**
- `scripts/WorldScripts/EntityTags.gd` — static helper, pure functions composing tag arrays from buildings/items/plants.
- `scripts/WorldScripts/EntityIndex.gd` — Node holding the per-chunk index, chunk lifecycle handlers, spiral query, semantic wrappers.
- `tests/test_helpers.gd` — `_expect(condition, msg)` helper that prints PASS/FAIL and exits non-zero on first failure.
- `tests/test_entity_tags.gd` — unit tests for tag composition.
- `tests/test_entity_index.gd` — unit tests for add/remove, chunk lifecycle, spiral query, semantic wrappers.
- `tests/run_all.gd` — entry point that runs both test files; invoked via `godot --headless --script res://tests/run_all.gd`.

**Modified:**
- `scripts/Grid.gd` — delete `findX`/`addFindable`/`rmvFindable`; add `entity_index` field; replace findable calls in `updateTile`/`removeBuilding`/`_on_chunk_loaded`/`_on_chunk_unloaded`.
- `scenes/Unit/Unit.gd` — delete `gotoThing`; replace 2 call sites in `pickUp` with semantic wrappers; treat `Vector2.INF` (not `null`) as "no match".
- `scenes/Main/main.gd` — instantiate `EntityIndex`, set `world` reference, connect chunk signals before any chunks load, set `grid.entity_index`.

---

## Task 1: Add headless test runner scaffolding

**Files:**
- Create: `tests/test_helpers.gd`
- Create: `tests/run_all.gd`

- [ ] **Step 1: Create test helpers**

Create `tests/test_helpers.gd`:

```gdscript
class_name TestHelpers
extends Object

static var _failures: int = 0
static var _passes: int = 0

static func expect(condition: bool, msg: String) -> void:
	if condition:
		_passes += 1
		print("  PASS: " + msg)
	else:
		_failures += 1
		print("  FAIL: " + msg)

static func expect_eq(actual, expected, msg: String) -> void:
	expect(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

static func summary_and_exit() -> void:
	print("\n%d passed, %d failed" % [_passes, _failures])
	if _failures > 0:
		OS.exit(1)
	OS.exit(0)
```

- [ ] **Step 2: Create test runner entry point**

Create `tests/run_all.gd`:

```gdscript
extends SceneTree

func _init() -> void:
	var entity_tags_tests = load("res://tests/test_entity_tags.gd").new()
	entity_tags_tests.run()
	var entity_index_tests = load("res://tests/test_entity_index.gd").new()
	entity_index_tests.run()
	TestHelpers.summary_and_exit()
```

- [ ] **Step 3: Run the runner — should succeed with no test files yet**

Add stub `tests/test_entity_tags.gd` and `tests/test_entity_index.gd` with empty `run()` methods so the loader doesn't crash:

```gdscript
# tests/test_entity_tags.gd
extends RefCounted
func run() -> void:
	pass
```

```gdscript
# tests/test_entity_index.gd
extends RefCounted
func run() -> void:
	pass
```

Run: `godot --headless --script res://tests/run_all.gd`
Expected: prints "0 passed, 0 failed", exit 0.

- [ ] **Step 4: Commit**

```bash
git add tests/
git commit -m "Add headless test runner scaffolding"
```

---

## Task 2: EntityTags — tag composition for items

**Files:**
- Create: `scripts/WorldScripts/EntityTags.gd`
- Modify: `tests/test_entity_tags.gd`

- [ ] **Step 1: Write failing test for ItemStack tag composition**

Replace `tests/test_entity_tags.gd` with:

```gdscript
extends RefCounted

const WoodItem = preload("res://data/resources/wood.tres")

func run() -> void:
	print("test_entity_tags:")
	_test_item_stack_tags()

func _test_item_stack_tags() -> void:
	var stack := ItemStack.new(WoodItem, 5)
	var tags := EntityTags.tags_for(stack)
	TestHelpers.expect(&"item" in tags, "ItemStack has 'item' tag")
	TestHelpers.expect(&"item:wood" in tags, "ItemStack has 'item:wood' tag")
	TestHelpers.expect(&"item_id:6" in tags, "ItemStack has 'item_id:6' tag")
	TestHelpers.expect_eq(tags.size(), 3, "ItemStack tag count")
```

- [ ] **Step 2: Run — expect failure (EntityTags doesn't exist)**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: parser error / "Identifier 'EntityTags' not declared" → exit non-zero.

- [ ] **Step 3: Create EntityTags with item support**

Create `scripts/WorldScripts/EntityTags.gd`:

```gdscript
class_name EntityTags
extends Object

static func tags_for(thing) -> Array:
	if thing is ItemStack:
		return _tags_for_item(thing)
	return []

static func _tags_for_item(stack: ItemStack) -> Array:
	var name_tag: StringName = StringName("item:" + str(stack.item.name).to_lower())
	var id_tag: StringName = StringName("item_id:" + str(stack.item.id))
	return [&"item", name_tag, id_tag]
```

- [ ] **Step 4: Run — expect 4 PASS**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: "4 passed, 0 failed", exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/WorldScripts/EntityTags.gd tests/test_entity_tags.gd
git commit -m "Add EntityTags helper with ItemStack tag composition"
```

---

## Task 3: EntityTags — buildings, storages, productions, plants

**Files:**
- Modify: `scripts/WorldScripts/EntityTags.gd`
- Modify: `tests/test_entity_tags.gd`

- [ ] **Step 1: Write failing tests for the remaining types**

Append to `tests/test_entity_tags.gd`:

```gdscript
const StorageRes = preload("res://data/building/production/littlestorage.tres")

func run() -> void:
	print("test_entity_tags:")
	_test_item_stack_tags()
	_test_storage_tags()
	_test_plain_building_tags()
	_test_plant_tags()
	_test_production_tags()

func _test_storage_tags() -> void:
	var storage: StorageBData = StorageRes.duplicate(true)
	var tags := EntityTags.tags_for(storage)
	TestHelpers.expect(&"building" in tags, "StorageBData has 'building' tag")
	TestHelpers.expect(&"storage" in tags, "StorageBData has 'storage' tag")
	TestHelpers.expect(&"accepts:wood" in tags, "StorageBData has 'accepts:wood' tag")
	TestHelpers.expect(&"accepts:stone" in tags, "StorageBData has 'accepts:stone' tag")
	TestHelpers.expect(&"accepts_id:6" in tags, "StorageBData has 'accepts_id:6' tag (wood)")
	TestHelpers.expect(&"accepts_id:7" in tags, "StorageBData has 'accepts_id:7' tag (stone)")

func _test_plain_building_tags() -> void:
	var building := BuildingData.new()
	var tags := EntityTags.tags_for(building)
	TestHelpers.expect_eq(tags, [&"building"], "BuildingData has only 'building' tag")

func _test_plant_tags() -> void:
	var plant := PlantData.new()
	plant.choppable = true
	var tags := EntityTags.tags_for(plant)
	TestHelpers.expect(&"plant" in tags, "PlantData has 'plant' tag")
	TestHelpers.expect(&"choppable" in tags, "Choppable PlantData has 'choppable' tag")
	TestHelpers.expect(not (&"minable" in tags), "Non-minable PlantData has no 'minable' tag")

func _test_production_tags() -> void:
	var prod := ProductionBData.new()
	var tags := EntityTags.tags_for(prod)
	TestHelpers.expect(&"building" in tags, "ProductionBData has 'building' tag")
	TestHelpers.expect(&"production" in tags, "ProductionBData has 'production' tag")
```

- [ ] **Step 2: Run — expect failures**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: 4 PASS from item, 8+ FAIL from new tests.

- [ ] **Step 3: Extend EntityTags**

Replace `scripts/WorldScripts/EntityTags.gd` with:

```gdscript
class_name EntityTags
extends Object

static func tags_for(thing) -> Array:
	if thing is ItemStack:
		return _tags_for_item(thing)
	if thing is StorageBData:
		return _tags_for_storage(thing)
	if thing is ProductionBData:
		return [&"building", &"production"]
	if thing is BuildingData:
		return [&"building"]
	if thing is PlantData:
		return _tags_for_plant(thing)
	return []

static func _tags_for_item(stack: ItemStack) -> Array:
	var name_tag: StringName = StringName("item:" + str(stack.item.name).to_lower())
	var id_tag: StringName = StringName("item_id:" + str(stack.item.id))
	return [&"item", name_tag, id_tag]

static func _tags_for_storage(s: StorageBData) -> Array:
	var tags: Array = [&"building", &"storage"]
	for stored in s.stores:
		if stored == null or stored.item == null:
			continue
		tags.append(StringName("accepts:" + str(stored.item.name).to_lower()))
		tags.append(StringName("accepts_id:" + str(stored.item.id)))
	return tags

static func _tags_for_plant(p: PlantData) -> Array:
	var tags: Array = [&"plant"]
	if p.choppable:
		tags.append(&"choppable")
	if p.minable:
		tags.append(&"minable")
	if p.cuttable:
		tags.append(&"cuttable")
	return tags
```

Order matters: `StorageBData`/`ProductionBData` must be checked before `BuildingData` (they extend it).

- [ ] **Step 4: Run — expect all PASS**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: all PASS, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/WorldScripts/EntityTags.gd tests/test_entity_tags.gd
git commit -m "Add EntityTags support for buildings, storages, productions, plants"
```

---

## Task 4: EntityIndex skeleton — add/remove with chunk grouping

**Files:**
- Create: `scripts/WorldScripts/EntityIndex.gd`
- Modify: `tests/test_entity_index.gd`

- [ ] **Step 1: Write failing test for add/remove**

Replace `tests/test_entity_index.gd` with:

```gdscript
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
```

- [ ] **Step 2: Run — expect failure (EntityIndex doesn't exist)**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: parser error referencing `EntityIndex`.

- [ ] **Step 3: Create EntityIndex with add/remove + lookup**

Create `scripts/WorldScripts/EntityIndex.gd`:

```gdscript
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
```

`get_tiles_with_tag` is a test/diagnostic helper — not used by gameplay code, kept public so tests can introspect.

- [ ] **Step 4: Run — expect all PASS**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: all PASS, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/WorldScripts/EntityIndex.gd tests/test_entity_index.gd
git commit -m "Add EntityIndex with per-chunk add/remove"
```

---

## Task 5: EntityIndex chunk lifecycle handlers

**Files:**
- Modify: `scripts/WorldScripts/EntityIndex.gd`
- Modify: `tests/test_entity_index.gd`

- [ ] **Step 1: Write failing tests for chunk_loaded / chunk_unloaded**

Append to `tests/test_entity_index.gd`:

```gdscript
const WoodItem = preload("res://data/resources/wood.tres")

func run() -> void:
	print("test_entity_index:")
	_test_add_lookup()
	_test_remove()
	_test_add_dedup()
	_test_chunk_loaded_indexes_buildings()
	_test_chunk_unloaded_clears_chunk()

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
```

- [ ] **Step 2: Run — expect failure (handlers not defined)**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: errors / FAIL on `_on_chunk_loaded` / `_on_chunk_unloaded`.

- [ ] **Step 3: Add handlers to EntityIndex**

Append to `scripts/WorldScripts/EntityIndex.gd`:

```gdscript
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
```

- [ ] **Step 4: Run — expect all PASS**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: all PASS, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/WorldScripts/EntityIndex.gd tests/test_entity_index.gd
git commit -m "Add chunk_loaded/chunk_unloaded handlers to EntityIndex"
```

---

## Task 6: EntityIndex spiral query (Chebyshev rings)

**Files:**
- Modify: `scripts/WorldScripts/EntityIndex.gd`
- Modify: `tests/test_entity_index.gd`

- [ ] **Step 1: Write failing tests for find_nearest**

Append to `tests/test_entity_index.gd`:

```gdscript
func run() -> void:
	print("test_entity_index:")
	_test_add_lookup()
	_test_remove()
	_test_add_dedup()
	_test_chunk_loaded_indexes_buildings()
	_test_chunk_unloaded_clears_chunk()
	_test_chunks_at_ring()
	_test_find_nearest_same_chunk()
	_test_find_nearest_spiral_outward()
	_test_find_nearest_no_match()

func _test_chunks_at_ring() -> void:
	var ring0 := EntityIndex.chunks_at_ring(Vector2i(5, 5), 0)
	TestHelpers.expect_eq(ring0, [Vector2i(5, 5)], "ring 0 = [center]")
	var ring1 := EntityIndex.chunks_at_ring(Vector2i(5, 5), 1)
	TestHelpers.expect_eq(ring1.size(), 8, "ring 1 has 8 chunks")
	TestHelpers.expect(Vector2i(4, 4) in ring1, "ring 1 contains corner (4,4)")
	TestHelpers.expect(Vector2i(6, 6) in ring1, "ring 1 contains corner (6,6)")
	TestHelpers.expect(not (Vector2i(5, 5) in ring1), "ring 1 excludes center")

func _test_find_nearest_same_chunk() -> void:
	var w := _make_world()
	var idx := _make_index(w)
	idx.add(Vector2(1, 1), [&"item"])
	idx.add(Vector2(3, 3), [&"item"])
	var nearest := idx.find_nearest(Vector2(0, 0), &"item")
	TestHelpers.expect_eq(nearest, Vector2(1, 1), "find_nearest picks closest in same chunk")
	idx.free()

func _test_find_nearest_spiral_outward() -> void:
	# chunk_size=4, so chunks (0,0) covers (0..3, 0..3); (1,0) covers (4..7, 0..3).
	var w := _make_world()
	var idx := _make_index(w)
	# nothing in chunk (0,0); something in chunk (1,0).
	idx.add(Vector2(5, 0), [&"item"])
	var nearest := idx.find_nearest(Vector2(0, 0), &"item")
	TestHelpers.expect_eq(nearest, Vector2(5, 0), "find_nearest spirals to neighbor chunk")
	idx.free()

func _test_find_nearest_no_match() -> void:
	var w := _make_world()
	var idx := _make_index(w)
	var nearest := idx.find_nearest(Vector2(0, 0), &"item")
	TestHelpers.expect_eq(nearest, Vector2.INF, "find_nearest returns Vector2.INF when no match")
	idx.free()
```

- [ ] **Step 2: Run — expect failures**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: errors on `chunks_at_ring` / `find_nearest`.

- [ ] **Step 3: Implement spiral query**

Append to `scripts/WorldScripts/EntityIndex.gd`:

```gdscript
const DEFAULT_SEARCH_CHUNKS := 3

func find_nearest(start_pos: Vector2, tag: StringName, search_chunks: int = DEFAULT_SEARCH_CHUNKS) -> Vector2:
	if world == null:
		return Vector2.INF
	var start_chunk: Vector2i = world.chunk_of_tile(start_pos)
	for ring in range(search_chunks):
		for chunk_coord in chunks_at_ring(start_chunk, ring):
			if not _by_chunk.has(chunk_coord):
				continue
			var hits: Array = _by_chunk[chunk_coord].get(tag, [])
			if hits.is_empty():
				continue
			return _nearest_in(hits, start_pos)
	return Vector2.INF

static func chunks_at_ring(center: Vector2i, ring: int) -> Array:
	if ring == 0:
		return [center]
	var result: Array = []
	for dy in range(-ring, ring + 1):
		for dx in range(-ring, ring + 1):
			if max(abs(dx), abs(dy)) == ring:
				result.append(center + Vector2i(dx, dy))
	return result

static func _nearest_in(positions: Array, start_pos: Vector2) -> Vector2:
	var best: Vector2 = positions[0]
	var best_dist: float = start_pos.distance_squared_to(best)
	for i in range(1, positions.size()):
		var d: float = start_pos.distance_squared_to(positions[i])
		if d < best_dist:
			best_dist = d
			best = positions[i]
	return best
```

Limitation, intentional: returning the first non-empty ring can occasionally miss a closer match in a more distant ring (a far corner of ring 1 vs a near corner of ring 2). Acceptable for v1 — matches the issue spec.

- [ ] **Step 4: Run — expect all PASS**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: all PASS, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/WorldScripts/EntityIndex.gd tests/test_entity_index.gd
git commit -m "Add spiral find_nearest query to EntityIndex"
```

---

## Task 7: EntityIndex semantic wrappers

**Files:**
- Modify: `scripts/WorldScripts/EntityIndex.gd`
- Modify: `tests/test_entity_index.gd`

- [ ] **Step 1: Write failing tests for the two wrappers**

Append to `tests/test_entity_index.gd`:

```gdscript
const StorageRes = preload("res://data/building/production/littlestorage.tres")

func run() -> void:
	print("test_entity_index:")
	_test_add_lookup()
	_test_remove()
	_test_add_dedup()
	_test_chunk_loaded_indexes_buildings()
	_test_chunk_unloaded_clears_chunk()
	_test_chunks_at_ring()
	_test_find_nearest_same_chunk()
	_test_find_nearest_spiral_outward()
	_test_find_nearest_no_match()
	_test_find_nearest_haulable()
	_test_find_nearest_storage_accepting()

func _test_find_nearest_haulable() -> void:
	var w := _make_world()
	var idx := _make_index(w)
	var stack := ItemStack.new(WoodItem, 1)
	idx.add(Vector2(2, 2), EntityTags.tags_for(stack))
	var nearest := idx.find_nearest_haulable(Vector2(0, 0), 6)  # wood id is 6
	TestHelpers.expect_eq(nearest, Vector2(2, 2), "find_nearest_haulable picks tile by item_id")
	idx.free()

func _test_find_nearest_storage_accepting() -> void:
	var w := _make_world()
	var idx := _make_index(w)
	var storage: StorageBData = StorageRes.duplicate(true)
	idx.add(Vector2(2, 2), EntityTags.tags_for(storage))
	var nearest := idx.find_nearest_storage_accepting(Vector2(0, 0), 6)  # wood
	TestHelpers.expect_eq(nearest, Vector2(2, 2), "find_nearest_storage_accepting matches accepts:wood")
	# Storage that doesn't accept the item should not match.
	var no_match := idx.find_nearest_storage_accepting(Vector2(0, 0), 999)
	TestHelpers.expect_eq(no_match, Vector2.INF, "find_nearest_storage_accepting returns INF for non-accepted")
	idx.free()
```

- [ ] **Step 2: Run — expect failures**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: errors on `find_nearest_haulable` / `find_nearest_storage_accepting`.

- [ ] **Step 3: Implement semantic wrappers**

Append to `scripts/WorldScripts/EntityIndex.gd`:

```gdscript
func find_nearest_haulable(start_pos: Vector2, item_id: int) -> Vector2:
	return find_nearest(start_pos, StringName("item_id:" + str(item_id)))

func find_nearest_storage_accepting(start_pos: Vector2, item_id: int) -> Vector2:
	return find_nearest(start_pos, StringName("accepts_id:" + str(item_id)))
```

Note: `find_nearest_storage_accepting` looks up `accepts_id:<id>` directly — the id-based tag was added in Task 3 alongside the human-readable `accepts:<name>` for symmetry with `item:<name>` / `item_id:<id>`. Looking up by id avoids needing an id↔name registry inside `EntityIndex` and works even when no items of that id are currently on the map.

- [ ] **Step 4: Run — expect all PASS**

Run: `godot --headless --script res://tests/run_all.gd`
Expected: all PASS, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/WorldScripts/EntityIndex.gd tests/test_entity_index.gd
git commit -m "Add EntityIndex semantic wrappers"
```

---

## Task 8: Wire EntityIndex into main.gd

**Files:**
- Modify: `scenes/Main/main.gd:14-36`
- Modify: `scripts/Grid.gd:1-15` (add `entity_index` field only — no behavior change yet)

- [ ] **Step 1: Add `entity_index` field to Grid**

In `scripts/Grid.gd`, after the `chunk_loader` field (around line 14), add:

```gdscript
var entity_index: EntityIndex = null
```

No other Grid changes in this task.

- [ ] **Step 2: Instantiate and wire EntityIndex in Main**

In `scenes/Main/main.gd`, modify `_ready` to add EntityIndex setup. Replace lines 14-36 with:

```gdscript
func _ready():
	get_tree().set_auto_accept_quit(false)
	world = _load_or_create_world()
	chunk_loader = ChunkLoader.new()
	chunk_loader.name = "ChunkLoader"
	chunk_loader.world = world
	add_child(chunk_loader)
	grid.chunk_loader = chunk_loader

	var entity_index := EntityIndex.new()
	entity_index.name = "EntityIndex"
	entity_index.world = world
	add_child(entity_index)
	grid.entity_index = entity_index

	# Pathfinder must add points before Grid inserts tiles + refreshes.
	chunk_loader.chunk_loaded.connect(grid.path._on_chunk_loaded)
	chunk_loader.chunk_loaded.connect(grid._on_chunk_loaded)
	chunk_loader.chunk_loaded.connect(entity_index._on_chunk_loaded)
	chunk_loader.chunk_unloaded.connect(grid._on_chunk_unloaded)
	chunk_loader.chunk_unloaded.connect(grid.path._on_chunk_unloaded)
	chunk_loader.chunk_unloaded.connect(entity_index._on_chunk_unloaded)

	_center_camera_on_spawn()
	camera.setup(chunk_loader, world, grid)

	var spawn_tile := world.spawn_tile()
	for unit in $Grid/Units.get_children():
		if unit is Unit:
			unit.setup(chunk_loader, world, spawn_tile)
```

`add_child(entity_index)` and the signal connections must happen BEFORE `camera.setup()` and `unit.setup()` (those calls pin chunks, which triggers `chunk_loaded`).

- [ ] **Step 3: Open the project in editor, ensure it boots**

Run: `godot --headless --quit --path /home/macph/projects/city-godot`
Expected: no parser errors, exit 0.

- [ ] **Step 4: Commit**

```bash
git add scenes/Main/main.gd scripts/Grid.gd
git commit -m "Wire EntityIndex Node into Main and Grid"
```

---

## Task 9: Migrate Grid call sites — delete findX, use EntityIndex

**Files:**
- Modify: `scripts/Grid.gd` (multiple sections)

- [ ] **Step 1: Remove findX field and addFindable/rmvFindable functions**

Delete line 12: `@onready var findX : Dictionary = {}`

Delete lines 74-81 (the `addFindable` and `rmvFindable` function bodies):

```gdscript
func addFindable(_pos: Vector2, thing):
	if (str(thing) in findX):
		findX[str(thing)].append(_pos)
	else:
		findX[str(thing)] = [_pos]

func rmvFindable(_pos: Vector2, thing):
	findX[str(thing)].erase(_pos)
```

- [ ] **Step 2: Replace addFindable in updateTile**

Lines 32-46 currently are:

```gdscript
func updateTile(_pos: Vector2, _object) -> void:
	var is_item = _object is ItemStack
	if is_item:
		grid[_pos].building = _object
		grid[_pos].navigable = _object.item.navigable
		itemOverlay.set_stack(_pos, _object.CurrentAmount, gridToWorld(_pos))
		addFindable(_pos, str(_object.id))
	else:
		grid[_pos].building = _object
		grid[_pos].navigable = _object.navigable
		addFindable(_pos, _object.get_class())
	refreshTile(_pos)
	if chunk_loader != null:
		chunk_loader.mark_dirty(_pos)
```

Replace with:

```gdscript
func updateTile(_pos: Vector2, _object) -> void:
	var is_item = _object is ItemStack
	if is_item:
		grid[_pos].building = _object
		grid[_pos].navigable = _object.item.navigable
		itemOverlay.set_stack(_pos, _object.CurrentAmount, gridToWorld(_pos))
	else:
		grid[_pos].building = _object
		grid[_pos].navigable = _object.navigable
	if entity_index != null:
		entity_index.add(_pos, EntityTags.tags_for(_object))
	refreshTile(_pos)
	if chunk_loader != null:
		chunk_loader.mark_dirty(_pos)
```

- [ ] **Step 3: Replace rmvFindable in removeBuilding**

Lines 47-58 currently are:

```gdscript
func removeBuilding(_pos):
	var building = grid[_pos].building
	var key
	if building is ItemStack:
		itemOverlay.set_stack(_pos, 0, gridToWorld(_pos))
		key = building.id
	else:
		key = building.get_class()
	rmvFindable(_pos, str(key))
	grid[_pos].building = null
	if chunk_loader != null:
		chunk_loader.mark_dirty(_pos)
```

Replace with:

```gdscript
func removeBuilding(_pos):
	var building = grid[_pos].building
	if building is ItemStack:
		itemOverlay.set_stack(_pos, 0, gridToWorld(_pos))
	if entity_index != null:
		entity_index.remove(_pos)
	grid[_pos].building = null
	if chunk_loader != null:
		chunk_loader.mark_dirty(_pos)
```

- [ ] **Step 4: Strip findable code from Grid._on_chunk_loaded / _on_chunk_unloaded**

Lines 83-115 currently bundle findable bookkeeping with tile rendering. Replace the whole block with:

```gdscript
func _on_chunk_loaded(_coord: Vector2i, chunk: Chunk) -> void:
	for local_y in range(chunk.chunk_size):
		for local_x in range(chunk.chunk_size):
			var local := Vector2i(local_x, local_y)
			var global_pos := chunk.global_pos_for(local)
			var tile: CellData = chunk.tile_at(local)
			grid[global_pos] = tile
			refreshTile(global_pos)
			var building = tile.building
			if building is ItemStack:
				itemOverlay.set_stack(global_pos, building.CurrentAmount, gridToWorld(global_pos))

func _on_chunk_unloaded(_coord: Vector2i, chunk: Chunk) -> void:
	for local_y in range(chunk.chunk_size):
		for local_x in range(chunk.chunk_size):
			var local := Vector2i(local_x, local_y)
			var global_pos := chunk.global_pos_for(local)
			var tile: CellData = chunk.tile_at(local)
			set_cell(0, global_pos)
			set_cell(1, global_pos)
			if tile.building is ItemStack:
				itemOverlay.set_stack(global_pos, 0, gridToWorld(global_pos))
			grid.erase(global_pos)
```

`EntityIndex._on_chunk_loaded` and `_on_chunk_unloaded` are now responsible for findable bookkeeping — connected separately in `main.gd`.

- [ ] **Step 5: Open the project in headless mode to confirm it parses**

Run: `godot --headless --quit --path /home/macph/projects/city-godot`
Expected: no parser errors, exit 0.

The existing tests still pass (they don't exercise Grid):

Run: `godot --headless --script res://tests/run_all.gd`
Expected: all PASS, exit 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/Grid.gd
git commit -m "Migrate Grid from findX to EntityIndex"
```

---

## Task 10: Migrate Unit call sites — replace gotoThing

**Files:**
- Modify: `scenes/Unit/Unit.gd:133-172`

- [ ] **Step 1: Replace pickUp call sites and delete gotoThing**

Lines 133-172 currently include `pickUp` (which calls `gotoThing` twice) and `gotoThing` itself. Replace lines 133-172 with:

```gdscript
func pickUp(_pos):
	if (data.hauling == null or data.hauling.id == grid.grid[_pos].building.id):
		var item = grid.grid[_pos].building
		if data.hauling == null:
			data.hauling = item
			grid.removeBuilding(_pos)
		else:
			var left = (data.hauling.item.maxStack - data.hauling.CurrentAmount)
			if (item.CurrentAmount <= left):
				data.hauling.CurrentAmount += item.CurrentAmount
				grid.removeBuilding(_pos)

			else:
				data.hauling.CurrentAmount = data.hauling.item.maxStack
				item.CurrentAmount -= left
				grid.itemOverlay.set_stack(_pos, item.CurrentAmount, grid.gridToWorld(_pos))

		grid.refreshTile(_pos)
		## check if there's more
		var next_pos: Vector2 = grid.entity_index.find_nearest_haulable(pos, data.hauling.id)
		if data.hauling.CurrentAmount == data.hauling.item.maxStack or next_pos == Vector2.INF:
			var storage_pos: Vector2 = grid.entity_index.find_nearest_storage_accepting(pos, data.hauling.id)
			if storage_pos != Vector2.INF:
				set_task("Store", storage_pos)
		else:
			set_task("Haul", next_pos)
```

`gotoThing` (lines 162-172) is deleted — no replacement.

Note the behavior change: `find_nearest_storage_accepting` only returns storages that actually accept the hauled item. Previously `gotoThing("Storage")` returned any storage, even ones that wouldn't accept the item, so a unit could walk to a storage and silently fail to deposit. This is a fix, not a regression.

- [ ] **Step 2: Open the project to confirm it parses**

Run: `godot --headless --quit --path /home/macph/projects/city-godot`
Expected: no parser errors, exit 0.

Run: `godot --headless --script res://tests/run_all.gd`
Expected: all PASS, exit 0.

- [ ] **Step 3: Commit**

```bash
git add scenes/Unit/Unit.gd
git commit -m "Replace Unit.gotoThing with EntityIndex semantic wrappers"
```

---

## Task 11: Smoke test in editor + final commit

**Files:** none (manual test).

- [ ] **Step 1: Delete any old saves so the world regenerates clean**

Run: `rm -rf ~/.local/share/godot/app_userdata/2D\ City-Civ/saves` (Linux user data path).

If the path is different on your system, run the game once, exit, then locate the save dir via Godot output.

- [ ] **Step 2: Open in editor and play**

Run: `godot --path /home/macph/projects/city-godot`

In the running game:
1. Spawn / move a unit.
2. Place items via whatever UI exists (or use `WorldGenerator` modifications if you've been seeding test items).
3. Place a storage building that accepts the item.
4. Watch the unit pick up the item, attempt to haul more, then route to the storage.

What to verify:
- No errors in the Godot output panel.
- Unit picks up items (haul behavior unchanged).
- Unit routes to a storage that accepts the item (and no longer routes to a storage that doesn't, fixing the latent bug).
- Crossing chunk boundaries still works — moving the unit far enough triggers chunk load/unload, and findables in newly loaded chunks become reachable; findables in unloaded chunks are no longer queried.

- [ ] **Step 3: If anything misbehaves, return to the relevant task**

Common pitfalls:
- If items in newly loaded chunks aren't found: check signal connection order in `main.gd` — `entity_index._on_chunk_loaded` must be connected before any chunk loads.
- If `find_nearest_storage_accepting` returns INF: confirm the storage's `stores` array contains an `ItemStack` with the right `item.id` — the wrapper looks up `accepts_id:<id>`.
- If duplicate findables accumulate: `EntityIndex.add` calls `remove` first when the tile already has tags; verify that's working in `_test_add_dedup`.

- [ ] **Step 4: Final cleanup commit (only if any fixes were needed)**

```bash
git add -A
git commit -m "Smoke test fixes for EntityIndex migration"
```
