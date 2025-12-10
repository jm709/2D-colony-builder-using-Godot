class_name itemCATA
extends Resource

@export var item: ItemData
@export var TotalAmount: int = 1
@export var CurrentAmount: int = 0

var id : int
var coords : Vector2

func _init(_item: ItemData = null, _amount: int = 1):
	if _item:
		item = _item
		CurrentAmount = _amount
		id = _item.id
		coords = _item.coords

@warning_ignore("native_method_override")
func get_class():
	return "Item"
