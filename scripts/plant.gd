class_name Plant
extends Resource

@export var name: String = ""
@export var texture: Texture
@export var id: int = 0
@export var coords: Vector2 = Vector2(0,0)
@export var durability: int = 100
@export var drops: Array[DropData] = []
@export var growth: int = 100
@export var growsOn: Array[FloorData] = []
@export var minable: bool = false
@export var choppable: bool = false
@export var cuttable: bool = false
