class_name Unit
extends Area2D

@onready var main = get_tree().root.get_node("Main")
@onready var grid: Grid = main.get_node("Grid")
@onready var pf: Pathfinder = grid.get_node("Pathfinding")
@onready var gui = main.get_node("CanvasLayer").get_node("GUI")

signal unitSelected(obj)

var data: UnitData = UnitData.new()

var currentTask = null
var taskPos

var path: Array[Vector2]
var pos: Vector2 : 
	get:
		return pos
	set(value):
		pos = value

func _ready():
	pos = grid.worldToGrid(position)
	unitSelected.connect(gui.setSelectedObject)
	
var task_interval := data.taskSpeed / 50
var time_elapsed := 0.0

func _process(delta):
	time_elapsed += delta
	move(delta)
	if time_elapsed >= task_interval:
		time_elapsed = 0.0
		doTask()
	
func doTask():
	if currentTask == null:
		getTask()
	else:
		print(currentTask)
		if currentTask == "Chop" || currentTask == "Mine":
			if nextTo(taskPos):
				breakbuilding()
		elif currentTask == "Haul":
			var distance = (abs(taskPos - pos))
			if distance == Vector2(0,0):
				pickUp(taskPos)
		elif currentTask == "Store":
			if nextTo(taskPos):
				storeinv()

func storeinv():
	var storage = grid.grid[taskPos].building.stores
	for itemcata in storage:
		if itemcata.item.id == data.hauling.item.id:
			if (itemcata.CurrentAmount - itemcata.TotalAmount) < data.hauling.amount:
				itemcata.CurrentAmount += data.hauling.amount
				data.hauling = null
				break
			else:
				var difference = (itemcata.TotalAmount - itemcata.CurrentAmount)
				itemcata.CurrentAmount = itemcata.TotalAmount
				data.hauling.amount -= difference
				break
	currentTask = null

func nextTo(thepos):
	var distance = (abs(thepos - pos))
	if distance == Vector2(0,1) || distance == Vector2(1,0):
		return true
	return false

func breakbuilding():
	grid.grid[taskPos].building.durability -= 20
	if (grid.grid[taskPos].building.durability <= 0):
		var data_ = grid.grid[taskPos].building.drops[0]
		var drop : DropData = DropData.new(data_.item, data_.amount)
		grid.updateTile(taskPos, drop)
		currentTask = null

func pickUp(_pos):
	if (data.hauling == null):
		var item = grid.grid[_pos].building
		data.hauling = item
		grid.itemOverlay.set_stack(_pos, 0, grid.gridToWorld(_pos))
		grid.grid[_pos].building = null
		grid.refreshTile(_pos)
		
	if (data.hauling != null):
		var item = grid.grid[_pos].building
		if data.hauling != item:
			gotoThing("Storage")
		else:
			var left = (data.hauling.item.maxStack - data.hauling.amount)
			if (item.amount <= left):
				data.hauling += item.amount
				grid.itemOverlay.set_stack(_pos, 0, grid.gridToWorld(_pos))
				grid.grid[_pos].building = null
			else:
				item.amount = data.hauling.item.maxStack
				item.amount -= left
				grid.itemOverlay.set_stack(_pos, item.amount, grid.gridToWorld(_pos))

		grid.refreshTile(_pos)

func gotoThing(thing: String):
	var closest = Vector2(99,99)
	if grid.findX.has(thing):
		for pos_ in grid.findX[thing]:
			print(abs(closest - pos_))
			print(abs(pos_ - taskPos))
			if abs(closest - pos_) > abs(pos_ - taskPos):
				closest = pos_
	if closest == Vector2(99,99):
		print("Ain't shit")
	else:
		set_task("Store", closest)
		
		
func getTask():
	pass
func move(delta):
	if path.size() > 0:
		if position.distance_to(grid.gridToWorld(path[0])) < 5:
			position = grid.gridToWorld(path[0])
			pos = path[0]
			path.pop_front()
		else:
			pos = grid.worldToGrid(position)
			position += (grid.gridToWorld(path[0]) - position).normalized() * data.speed * delta
			

@warning_ignore("native_method_override")
func get_class():
	return "Unit"
	
func set_task(task_, taskpos_):
	currentTask = task_
	taskPos = taskpos_
	for x in pf.getPartialPath(pos, taskPos):
		path.append(grid.worldToGrid(x))

func movin(thepos):
	currentTask = null
	taskPos = null
	for x in pf.getPath(pos, thepos):
		path.append(grid.worldToGrid(x))

func set_job():
	pass
	
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and gui.getSelectedObject() != self:
		emit_signal("unitSelected", self)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and gui.getSelectedObject() == self:
		emit_signal("unitSelected", null)
