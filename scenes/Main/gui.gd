class_name GUI
extends Control

@onready var main = get_tree().root.get_node("Main")
@onready var grid : Grid = main.get_node("Grid")
@onready var unit : Unit = grid.get_node("Units").get_node("Unit")
	
var taskpos = null

var selectedObject = null:
	get:
		return selectedObject
	set(value):
		resetRClickPanel()
		selectedObject = value
		if value != null:
			$InfoPanel.visible = true
			match value.get_class():
				"Unit":
					$InfoPanel/Name.text = value.data.name
					$BaseButtons/HBoxContainer/Bio.visible = true
		else:
			$InfoPanel.visible = false
			$BaseButtons/HBoxContainer/Bio.visible = false

var rclickedObject = null:
	get:
		return rclickedObject
	set(value):
		resetRClickPanel()
		if selectedObject != null:
			rclickedObject = value
			if value != null:
				$RClickPanel.visible = true
				$RClickPanel.set_position(get_global_mouse_position())
				taskpos = grid.worldToGrid(grid.get_global_mouse_position())
				print(taskpos)
				if (rclickedObject.building != null):
					match rclickedObject.building.get_class():
						"Building":
							$RClickPanel/VBoxContainer/Mine.visible = true
						"Plant":
							$RClickPanel/VBoxContainer/Chop.visible = true
						"Item":
							$RClickPanel/VBoxContainer/Haul.visible = true
							$RClickPanel/VBoxContainer/Move.visible = true

				else:
					match rclickedObject.floorData.get_class():
						"Floor":
							$RClickPanel/VBoxContainer/Move.visible = true
						
func resetRClickPanel():
	taskpos = null
	$RClickPanel/VBoxContainer/Mine.visible = false
	$RClickPanel/VBoxContainer/Chop.visible = false
	$RClickPanel/VBoxContainer/Move.visible = false
	$RClickPanel/VBoxContainer/Harvest.visible = false
	$RClickPanel/VBoxContainer/Haul.visible = false
						
func setRClickedObject(obj):
	rclickedObject = obj

func setSelectedObject(obj):
	selectedObject = obj

func getSelectedObject():
	return selectedObject

func _on_construct_pressed():
	selectedObject = null
	$BaseButtons.visible = false
	$ConstructButtons.visible = true
	
func _on_tasks_pressed() -> void:
	selectedObject = null
	$BaseButtons.visible = false
	$TaskButtons.visible = true
	
func _on_back_pressed():
	selectedObject = null
	$ConstructButtons.visible = false
	$TaskButtons.visible = false
	$BaseButtons.visible = true 
	
func _on_move_pressed() -> void:
	print("movin")
	unit.movin(taskpos)
	resetRClickPanel()

func _on_chop_pressed() -> void:
	print("chopin")
	unit.set_task("Chop", taskpos)
	resetRClickPanel()

func _on_mine_pressed() -> void:
	print("minin")
	unit.set_task("Mine", taskpos)
	resetRClickPanel()

func _on_harvest_pressed() -> void:
	pass # Replace with function body.

func _on_haul_pressed() -> void:
	pass # Replace with function body.
