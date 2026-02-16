extends Node2D

@export var float_distance: float = 60.0
@export var duration: float = 2.0
@export var override_font: Font
@export var outline_color: Color
@export var outline_size: int = 0

@onready var icon: Sprite2D = $Icon
@onready var label: Label = $Label

func setup(text: String, color: Color, icon_tex: Texture2D, start_pos: Vector2) -> void:
	global_position = start_pos
	label.text = text
	label.modulate = color
	if override_font:
		label.add_theme_font_override("font", override_font)
	if outline_size > 0:
		label.add_theme_color_override("font_outline_color", outline_color)
		label.add_theme_constant_override("outline_size", outline_size)
	if icon_tex:
		icon.texture = icon_tex
		icon.visible = true
	else:
		icon.visible = false
	scale = Vector2(0.85, 0.85)
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2.ONE, 0.14)
	t.parallel().tween_property(self, "position", position + Vector2(0.0, -float_distance), duration)
	t.parallel().tween_property(self, "modulate:a", 0.0, duration)
	t.finished.connect(queue_free)

func setup_with_item_scene(
	text: String,
	color: Color,
	item_scene: PackedScene,
	start_pos: Vector2,
	icon_scale: float = 1.0,
	hide_backings: bool = true
) -> void:
	setup(text, color, null, start_pos)
	if not item_scene:
		return
	var icon_node := item_scene.instantiate() as Node2D
	if not icon_node:
		return
	add_child(icon_node)
	icon_node.position = icon.position
	icon_node.scale *= icon_scale
	if hide_backings:
		for node_name in ["HealthIconBacking", "EnergyIconBacking", "XpIconBacking", "CoinIconBacking"]:
			var backing := icon_node.get_node_or_null(node_name) as CanvasItem
			if backing:
				backing.visible = false
