extends Node2D

@onready var grid = $Grid

func _ready():
	grid.generateGrid()
	$Grid/Pathfinding.initialize()
