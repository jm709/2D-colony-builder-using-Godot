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
		if value == null:
			$InfoPanel.visible = false
			return
		$InfoPanel.visible = true
		$BaseButtons/HBoxContainer/Bio.visible = false
		$InfoPanel/haulAmount.visible = false
		$InfoPanel/haulIcon.visible = false
		$InfoPanel/Durability.visible = false
		$InfoPanel/Stores.visible = false
		if value is Unit:
			_showUnit(value)
		elif value is CellData:
			_showCell(value)
			

var rclickedObject = null:
	get:
		return rclickedObject
	set(value):
		resetRClickPanel()
		if selectedObject:
			if selectedObject is Unit:
				rclickedObject = value
				if value != null:
					$RClickPanel.visible = true
					$RClickPanel.set_position(get_global_mouse_position())
					taskpos = grid.worldToGrid(grid.get_global_mouse_position())
					if (rclickedObject.building != null):
						if rclickedObject.building is ItemStack:
							$RClickPanel/VBoxContainer/Haul.visible = true
							$RClickPanel/VBoxContainer/Move.visible = true
						elif rclickedObject.building is PlantData:
							$RClickPanel/VBoxContainer/Chop.visible = true
						elif rclickedObject.building is BuildingData:
							$RClickPanel/VBoxContainer/Mine.visible = true
					else:
						if rclickedObject.floorData is FloorData:
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
	unit.setMoveTarget(taskpos)
	resetRClickPanel()

func _on_chop_pressed() -> void:
	unit.set_task("Chop", taskpos)
	resetRClickPanel()

func _on_mine_pressed() -> void:
	unit.set_task("Mine", taskpos)
	resetRClickPanel()

func _on_harvest_pressed() -> void:
	pass # Replace with function body.

func _on_haul_pressed() -> void:
	unit.set_task("Haul", taskpos)
	resetRClickPanel()

func _showDurability(building) -> void:
	$InfoPanel/Durability.visible = true
	$InfoPanel/Durability.text = "Durablity: %d / %d" % [building.durability, building.maxDurability]

func _showUnit(unit) -> void:
	$InfoPanel/Name.text = unit.data.name
	$BaseButtons/HBoxContainer/Bio.visible = true
	if unit.data.hauling != null:
		$InfoPanel/haulAmount.visible = true
		$InfoPanel/haulIcon.visible = true
		$InfoPanel/haulAmount.text = str(unit.data.hauling.CurrentAmount)
		$InfoPanel/haulIcon.texture = unit.data.hauling.item.texture

func _showCell(cell) -> void:
	if cell.building != null:
		_showCellBuilding(cell.building)
	else:
		_showCellFloor(cell.floorData)

func _showCellBuilding(building) -> void:
	if building is StorageBData:
		$InfoPanel/Name.text = building.name
		var lines := []
		for item in building.stores:
			lines.append("%s: %d / %d" % [item.item.name, item.CurrentAmount, item.TotalAmount])
		$InfoPanel/Stores.text = "\n".join(lines)
		$InfoPanel/Stores.visible = true
		_showDurability(building)
	elif building is ProductionBData:
		$InfoPanel/Name.text = building.name
		_showDurability(building)
	elif building is PlantData:
		$InfoPanel/Name.text = building.name
		_showDurability(building)
	elif building is BuildingData:
		$InfoPanel/Name.text = building.name
		$BaseButtons/HBoxContainer/Bio.visible = true

func _showCellFloor(floor_) -> void:
	if floor_ is FloorData:
		$InfoPanel/Name.text = floor_.name
		$BaseButtons/HBoxContainer/Bio.visible = true
