class_name ItemData
extends Resource

@export var name : String
@export var id: int
@export var coords: Vector2 = Vector2(0,0)
@export var texture: Texture
@export var edible: bool = false
@export var equipable: bool = false
@export var maxStack: int
@export var naviagable: bool = true

@warning_ignore("native_method_override")
func get_class():
	return "Item"
