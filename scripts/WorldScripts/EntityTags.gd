class_name EntityTags
extends Object

static func tags_for(thing: Variant) -> Array:
	if thing is ItemStack:
		return _tags_for_item(thing)
	if thing is StorageBData:
		return _tags_for_storage(thing)
	if thing is ProductionBData:
		return [&"building", &"production"]
	if thing is BuildingData:
		return [&"building"]
	if thing is PlantData:
		return _tags_for_plant(thing)
	return []

static func _tags_for_item(stack: ItemStack) -> Array:
	var name_tag: StringName = StringName("item:" + str(stack.item.name).to_lower())
	var id_tag: StringName = StringName("item_id:" + str(stack.item.id))
	return [&"item", name_tag, id_tag]

static func _tags_for_storage(s: StorageBData) -> Array:
	var tags: Array = [&"building", &"storage"]
	for stored in s.stores:
		if stored == null or stored.item == null:
			continue
		tags.append(StringName("accepts:" + str(stored.item.name).to_lower()))
		tags.append(StringName("accepts_id:" + str(stored.item.id)))
	return tags

static func _tags_for_plant(p: PlantData) -> Array:
	var tags: Array = [&"plant"]
	if p.choppable:
		tags.append(&"choppable")
	if p.minable:
		tags.append(&"minable")
	if p.cuttable:
		tags.append(&"cuttable")
	return tags
