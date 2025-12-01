extends Node2D

@onready var grid = $Grid
@onready var gui = get_node("CanvasLayer/GUI")

func _ready():
	grid.generateGrid()
	$Grid/Pathfinding.initialize()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			var clicked = grid.worldToGrid(grid.get_global_mouse_position())
			var tile = grid.getTileFromGrid(clicked)
			gui.setRClickedObject(tile)
