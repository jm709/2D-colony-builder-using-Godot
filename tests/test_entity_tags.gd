extends RefCounted

const WoodItem = preload("res://data/resources/wood.tres")

func run() -> void:
	print("test_entity_tags:")
	_test_item_stack_tags()

func _test_item_stack_tags() -> void:
	var stack := ItemStack.new(WoodItem, 5)
	var tags := EntityTags.tags_for(stack)
	TestHelpers.expect(&"item" in tags, "ItemStack has 'item' tag")
	TestHelpers.expect(&"item:wood" in tags, "ItemStack has 'item:wood' tag")
	TestHelpers.expect(&"item_id:6" in tags, "ItemStack has 'item_id:6' tag")
	TestHelpers.expect_eq(tags.size(), 3, "ItemStack tag count")
