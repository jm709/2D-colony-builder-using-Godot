class_name EntityTags
extends Object

static func tags_for(thing) -> Array:
	if thing is ItemStack:
		return _tags_for_item(thing)
	return []

static func _tags_for_item(stack: ItemStack) -> Array:
	var name_tag: StringName = StringName("item:" + str(stack.item.name).to_lower())
	var id_tag: StringName = StringName("item_id:" + str(stack.item.id))
	return [&"item", name_tag, id_tag]
