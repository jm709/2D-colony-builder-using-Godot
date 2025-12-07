extends BuildingData
class_name ProductionBData

@export var maxWorkers: int = 1
@export var currWorkers: int = 0
@export var production: Array[DropData] = []
@export var prodTime: float = 1
@export var skilledWorkerBonus: float = 0

@warning_ignore("native_method_override")
func get_class():
	return "Production"
