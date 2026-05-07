class_name TestHelpers
extends Object

static var _failures: int = 0
static var _passes: int = 0

static func expect(condition: bool, msg: String) -> void:
	if condition:
		_passes += 1
		print("  PASS: " + msg)
	else:
		_failures += 1
		print("  FAIL: " + msg)

static func expect_eq(actual, expected, msg: String) -> void:
	expect(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

static func summary_and_exit(tree: SceneTree) -> void:
	print("\n%d passed, %d failed" % [_passes, _failures])
	tree.quit(1 if _failures > 0 else 0)
