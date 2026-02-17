extends Button

var world_index: int = 1
var level_index: int = 1

signal level_pressed(world_index: int, level_index: int)

func setup(world: int, level: int, unlocked: bool, completed: bool) -> void:
	world_index = world
	level_index = level
	text = "%02d" % level
	disabled = not unlocked
	if completed:
		modulate = Color(0.37, 0.89, 0.68, 1.0)
		tooltip_text = "Completed"
	elif unlocked:
		modulate = Color(1, 1, 1, 1)
		tooltip_text = "Start Level %d" % level
	else:
		modulate = Color(0.56, 0.56, 0.56, 1)
		text = "LOCK"
		tooltip_text = "Locked: Complete previous levels first"

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	emit_signal("level_pressed", world_index, level_index)
