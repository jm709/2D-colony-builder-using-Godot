class_name Unit
extends Area2D

@onready var main = get_tree().root.get_node("Main")
@onready var grid: Grid = main.get_node("Grid")
@onready var pf: Pathfinder = grid.get_node("Pathfinding")
@onready var gui = main.get_node("CanvasLayer").get_node("GUI")

signal unitSelected(obj)

var data: UnitData = UnitData.new()

var path: Array[Vector2]
var pos: Vector2 : 
	get:
		return pos
	set(value):
		pos = value

func _ready():
	pos = grid.worldToGrid(position)
	unitSelected.connect(gui.setSelectedObject)

func _process(delta):
	move(delta)
	
func move(delta):
	if path.size() > 0:
		if position.distance_to(grid.gridToWorld(path[0])) < 5:
			position = grid.gridToWorld(path[0])
			pos = path[0]
			path.pop_front()
		else:
			pos = grid.worldToGrid(position)
			position += (grid.gridToWorld(path[0]) - position).normalized() * data.speed * delta
			
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and gui.getSelectedObject() == self:
		if event.pressed:
			var clicked = grid.worldToGrid(get_global_mouse_position())
			for x in pf.getPath(pos, clicked):
				path.append(grid.worldToGrid(x))

@warning_ignore("native_method_override")
func get_class():
	return "Unit"
	
func set_job():
	pass
	

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and gui.getSelectedObject() != self:
		emit_signal("unitSelected", self)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and gui.getSelectedObject() == self:
		emit_signal("unitSelected", null)
