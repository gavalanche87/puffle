extends Button

@export var action_id: String = ""

signal nav_pressed(action_id: String)

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	emit_signal("nav_pressed", action_id)
