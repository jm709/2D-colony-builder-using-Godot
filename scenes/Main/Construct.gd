class_name construct 
extends Control

@onready var main = get_tree().root.get_node("Main")
@onready var grid : Grid = main.get_node("Grid")
@onready var gui : GUI = main.get_node("GUI")

signal unitSelected(obj)

var pos: Vector2 : 
	get:
		return pos
	set(value):
		pos = value
	
var selectedConstruct = null:
	get:
		return selectedConstruct
	set(value):
		selectedConstruct = value
		#if value != null:
			#$InfoPanel.visible = true
			#match value.get_class():
				#"Unit":
					#$InfoPanel/Name.text = value.data.name
					#$BaseButtons/HBoxContainer/Bio.visible = true
		#else:
			#$InfoPanel.visible = false
			#$BaseButtons/HBoxContainer/Bio.visible = false

func _on_wood_wall_pressed() -> void:
	selectedConstruct = load("res://data/building/woodenwall.tres")


func _on_stone_wall_pressed() -> void:
	selectedConstruct = load("res://data/building/stonewall.tres")


func _on_dirt_floor_pressed() -> void:
	selectedConstruct = load("res://data/growables/tree.tres") 

func _on_back_pressed() -> void:
	selectedConstruct = null

func _on_construct_input(event):
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("unitSelected", null)

func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		selectedConstruct = null
		for button in $HBoxContainer.get_children():
			if button is BaseButton and button.is_pressed():
				button.set_pressed(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and selectedConstruct != null:
		if event.pressed:
			var clicked = grid.worldToGrid(grid.get_global_mouse_position())
			grid.updateTile(clicked, selectedConstruct)
			
