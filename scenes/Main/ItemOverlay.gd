extends Node2D

var labels := {}

func set_stack(tile : Vector2i, amount : int, world_pos: Vector2):
	if amount <= 1:
		if labels.has(tile):
			labels[tile].queue_free()
			labels.erase(tile)
		return
	
	var label: Label
	if not labels.has(tile):
		label = Label.new()
		add_child(label)
		labels[tile] = label
		label.add_theme_font_size_override("font_size", 24)
	else:
		label = labels[tile]
	
	label.text = str(amount)
	label.position = world_pos + Vector2(100,100)
