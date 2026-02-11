extends Node2D

@export var float_distance: float = 60.0
@export var duration: float = 0.7

@onready var icon: Sprite2D = $Icon
@onready var label: Label = $Label

func setup(text: String, color: Color, icon_tex: Texture2D, start_pos: Vector2) -> void:
	global_position = start_pos
	label.text = text
	label.modulate = color
	if icon_tex:
		icon.texture = icon_tex
		icon.visible = true
	else:
		icon.visible = false
	var t := create_tween()
	t.tween_property(self, "position", position + Vector2(0.0, -float_distance), duration)
	t.parallel().tween_property(self, "modulate:a", 0.0, duration)
	t.finished.connect(queue_free)
