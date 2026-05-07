extends RefCounted

const WoodItem = preload("res://data/resources/wood.tres")
const StorageRes = preload("res://data/building/production/littlestorage.tres")

func run() -> void:
	print("test_entity_tags:")
	_test_item_stack_tags()
	_test_storage_tags()
	_test_plain_building_tags()
	_test_plant_tags()
	_test_production_tags()

func _test_item_stack_tags() -> void:
	var stack := ItemStack.new(WoodItem, 5)
	var tags := EntityTags.tags_for(stack)
	TestHelpers.expect(&"item" in tags, "ItemStack has 'item' tag")
	TestHelpers.expect(&"item:wood" in tags, "ItemStack has 'item:wood' tag")
	TestHelpers.expect(&"item_id:6" in tags, "ItemStack has 'item_id:6' tag")
	TestHelpers.expect_eq(tags.size(), 3, "ItemStack tag count")

func _test_storage_tags() -> void:
	var storage: StorageBData = StorageRes.duplicate(true)
	var tags := EntityTags.tags_for(storage)
	TestHelpers.expect(&"building" in tags, "StorageBData has 'building' tag")
	TestHelpers.expect(&"storage" in tags, "StorageBData has 'storage' tag")
	TestHelpers.expect(&"accepts:wood" in tags, "StorageBData has 'accepts:wood' tag")
	TestHelpers.expect(&"accepts:stone" in tags, "StorageBData has 'accepts:stone' tag")
	TestHelpers.expect(&"accepts_id:6" in tags, "StorageBData has 'accepts_id:6' tag (wood)")
	TestHelpers.expect(&"accepts_id:7" in tags, "StorageBData has 'accepts_id:7' tag (stone)")

func _test_plain_building_tags() -> void:
	var building := BuildingData.new()
	var tags := EntityTags.tags_for(building)
	TestHelpers.expect_eq(tags, [&"building"], "BuildingData has only 'building' tag")

func _test_plant_tags() -> void:
	var plant := PlantData.new()
	plant.choppable = true
	var tags := EntityTags.tags_for(plant)
	TestHelpers.expect(&"plant" in tags, "PlantData has 'plant' tag")
	TestHelpers.expect(&"choppable" in tags, "Choppable PlantData has 'choppable' tag")
	TestHelpers.expect(not (&"minable" in tags), "Non-minable PlantData has no 'minable' tag")

func _test_production_tags() -> void:
	var prod := ProductionBData.new()
	var tags := EntityTags.tags_for(prod)
	TestHelpers.expect(&"building" in tags, "ProductionBData has 'building' tag")
	TestHelpers.expect(&"production" in tags, "ProductionBData has 'production' tag")
