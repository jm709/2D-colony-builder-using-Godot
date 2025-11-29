class_name GUI
extends Control

var selectedObject = null:
	get:
		return selectedObject
	set(value):
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

func setSelectedObject(obj):
	selectedObject = obj

func getSelectedObject():
	return selectedObject

func _on_construct_pressed():
	$BaseButtons.visible = false
	$ConstructButtons.visible = true
	
func _on_tasks_pressed() -> void:
	$BaseButtons.visible = false
	$TaskButtons.visible = true
	
func _on_back_pressed():
	$ConstructButtons.visible = false
	$TaskButtons.visible = false
	$BaseButtons.visible = true 

func _gui_input(event) -> void:
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		selectedObject = null
		
