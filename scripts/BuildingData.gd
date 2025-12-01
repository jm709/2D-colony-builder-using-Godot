class_name BuildingData
extends Resource

@export var id: int = 0
@export var name: String
@export var durability : int = 100
@export var texture: Texture
@export var unbuiltTexture: Texture
@export var width : int = 1
@export var height : int = 1
@export var workRequired: int
@export var resourcesRequired: Dictionary
@export var isRestingSpot: bool
@export var recipes: Array[RecipeData]
@export var coords: Vector2 = Vector2(0,0)
@export var naviagable: bool = false

@warning_ignore("native_method_override")
func get_class():
	return "Building"
