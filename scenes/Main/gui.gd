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
					if (value.data.hauling != null):
						$InfoPanel/haulAmount.text = str(value.data.hauling.CurrentAmount)
						$InfoPanel/haulIcon.texture = value.data.hauling.item.texture
				"Cell":
					if value.building != null:
						match value.building.get_class():
							"Building":
								$InfoPanel/Name.text = value.building.name
								$BaseButtons/HBoxContainer/Bio.visible = true
							"Plant":
								$InfoPanel/Name.text = value.building.name
								var dline = ("Durablity: %d / %d" % [value.building.durability, value.building.maxDurability])
								$InfoPanel/Durability.text = dline
							"Production":
								$InfoPanel/Name.text = value.building.name
								var dline = ("Durablity: %d / %d" % [value.building.durability, value.building.maxDurability])
								$InfoPanel/Durability.text = dline
							"Storage":
								$InfoPanel/Name.text = value.building.name
								var lines := []
								for item in value.building.stores:
									var item_name = item.item.name
									lines.append("%s: %d / %d" % [item_name, item.CurrentAmount, item.TotalAmount])
								$InfoPanel/Stores.text = "\n".join(lines)
								var dline = ("Durablity: %d / %d" % [value.building.durability, value.building.maxDurability])
								$InfoPanel/Durability.text = dline
					else:
						match value.floorData.get_class():
							"Floor":
								$InfoPanel/Name.text = value.floorData.name
								$InfoPanel/haulAmount.text = ""
								$InfoPanel/haulIcon.texture = null
								$BaseButtons/HBoxContainer/Bio.visible = true
							
		else:
			$InfoPanel.visible = false
			$BaseButtons/HBoxContainer/Bio.visible = false

var rclickedObject = null:
	get:
		return rclickedObject
	set(value):
		resetRClickPanel()
		if selectedObject:
			if selectedObject.get_class() == "Unit":
				rclickedObject = value
				if value != null:
					$RClickPanel.visible = true
					$RClickPanel.set_position(get_global_mouse_position())
					taskpos = grid.worldToGrid(grid.get_global_mouse_position())
					if (rclickedObject.building != null):
						print(rclickedObject.building.get_class())
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
	$ConstructButtons/ConstructBase.visible = true
	
func _on_tasks_pressed() -> void:
	selectedObject = null
	$BaseButtons.visible = false
	$TaskButtons.visible = true
	
func _on_back_pressed():
	selectedObject = null
	$ConstructButtons/ConstructBase.visible = false
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
	print("haulin")
	unit.set_task("Haul", taskpos)
	resetRClickPanel()
