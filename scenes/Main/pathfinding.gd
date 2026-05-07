class_name Pathfinder
extends Node

var aStar = AStar2D.new()
var _point_ids: Dictionary = {}             # Vector2 (tile) -> int (AStar id)
var _chunk_points: Dictionary = {}          # Vector2i (chunk) -> Array[int]
var _next_id: int = 0
@onready var main = get_tree().root.get_node("Main")
@onready var grid : Grid = main.get_node("Grid")

const DIRECTIONS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

func getPath(_pointA: Vector2, _pointB: Vector2):
	var aID = getPointID(_pointA)
	var bID = getPointID(_pointB)
	return aStar.get_point_path(aID, bID)

func getPartialPath(_pointA: Vector2, _pointB: Vector2):
	var aID = getPointID(_pointA)
	var bID = getPointID(_pointB)
	return aStar.get_point_path(aID, bID, true)

func connectPoint(_point: Vector2):
	var _pointID = getPointID(_point)
	if _pointID == -1:
		return
	for direction in DIRECTIONS:
		var neighbour = _point + direction
		if not _point_ids.has(neighbour):
			continue
		var neighbourID = getPointID(neighbour)
		if grid.grid.has(neighbour) and grid.grid[neighbour].navigable == true:
			aStar.connect_points(_pointID, neighbourID)

func disconnectPoint(_point: Vector2):
	var _pointID = getPointID(_point)
	if _pointID == -1:
		return
	for direction in DIRECTIONS:
		var neighbour = _point + direction
		if not _point_ids.has(neighbour):
			continue
		var neighbourID = getPointID(neighbour)
		if aStar.are_points_connected(_pointID, neighbourID):
			aStar.disconnect_points(_pointID, neighbourID)

func getPointID(gridPoint: Vector2) -> int:
	return _point_ids.get(gridPoint, -1)

func getWorldID(worldPoint: Vector2) -> int:
	return aStar.get_closest_point(worldPoint)

func getIDWorldPos(_id: int) -> Vector2:
	return aStar.get_point_position(_id)

func getIDGridPos(_id: int) -> Vector2:
	var worldPos = getIDWorldPos(_id)
	return grid.worldToGrid(worldPos)

func _on_chunk_loaded(_coord: Vector2i, chunk: Chunk) -> void:
	var ids: Array[int] = []
	for i in chunk.tiles.size():
		var local_x: int = i % chunk.chunk_size
		var local_y: int = i / chunk.chunk_size
		var global_pos := Vector2(
			chunk.coord.x * chunk.chunk_size + local_x,
			chunk.coord.y * chunk.chunk_size + local_y
		)
		var id := _next_id
		_next_id += 1
		aStar.add_point(id, grid.gridToWorld(global_pos))
		_point_ids[global_pos] = id
		ids.append(id)
	_chunk_points[chunk.coord] = ids
	# Connection happens after Grid inserts tiles + refreshTile; refreshTile calls connectPoint.

func _on_chunk_unloaded(coord: Vector2i, _chunk: Chunk) -> void:
	var ids: Array = _chunk_points.get(coord, [])
	for id in ids:
		if aStar.has_point(id):
			aStar.remove_point(id)
	_chunk_points.erase(coord)
	# Prune _point_ids entries for this chunk by id match.
	# (Iterate keys; small per-chunk.)
	var to_erase: Array = []
	for tile_pos in _point_ids.keys():
		if not aStar.has_point(_point_ids[tile_pos]):
			to_erase.append(tile_pos)
	for tile_pos in to_erase:
		_point_ids.erase(tile_pos)
