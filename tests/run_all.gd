extends SceneTree

func _init() -> void:
	var entity_tags_tests = load("res://tests/test_entity_tags.gd").new()
	entity_tags_tests.run()
	var entity_index_tests = load("res://tests/test_entity_index.gd").new()
	entity_index_tests.run()
	TestHelpers.summary_and_exit()
