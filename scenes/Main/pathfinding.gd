class_name Pathfinder
extends Node

var aStar = AStar2D.new()
var _point_ids: Dictionary = {}
@onready var main = get_tree().root.get_node("Main")
@onready var grid : Grid = main.get_node("Grid")

const DIRECTIONS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

func initialize():
	addPoints()
	connectAllPoints()

func getPath(_pointA: Vector2, _pointB: Vector2):
	var aID = getPointID(_pointA)
	var bID = getPointID(_pointB)
	return aStar.get_point_path(aID, bID)
	
func getPartialPath(_pointA: Vector2, _pointB: Vector2):
	var aID = getPointID(_pointA)
	var bID = getPointID(_pointB)
	return aStar.get_point_path(aID, bID, true)

func addPoints():
	var curID = 0
	for point in grid.grid:
		aStar.add_point(curID, grid.gridToWorld(point))
		_point_ids[point] = curID
		curID += 1

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

func connectAllPoints():
	for point in grid.grid:
		connectPoint(point)

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
