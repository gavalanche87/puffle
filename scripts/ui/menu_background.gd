extends Control

@export var clouds_scroll_speed: float = 14.0

@onready var sky: Sprite2D = $Sky
@onready var clouds_a: Sprite2D = $CloudsA
@onready var clouds_b: Sprite2D = $CloudsB

var _cloud_width: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prepare_sprite(sky)
	_prepare_sprite(clouds_a)
	_prepare_sprite(clouds_b)
	_sync_cloud_pair_from_scene()

func _process(delta: float) -> void:
	if _cloud_width <= 0.0 or clouds_a == null or clouds_b == null:
		return
	var dx: float = clouds_scroll_speed * delta
	clouds_a.position.x -= dx
	clouds_b.position.x -= dx
	_wrap_clouds()

func _prepare_sprite(node: Sprite2D) -> void:
	if node == null:
		return
	node.centered = false

func _sync_cloud_pair_from_scene() -> void:
	if clouds_a == null or clouds_b == null or clouds_a.texture == null:
		return
	_cloud_width = clouds_a.texture.get_width() * absf(clouds_a.scale.x)
	if _cloud_width <= 0.0:
		return
	# Keep the editor-set transform on CloudsA; only place CloudsB adjacent if needed.
	if absf(clouds_b.position.x - clouds_a.position.x) < 1.0:
		clouds_b.position.x = clouds_a.position.x + _cloud_width
	if absf(clouds_b.position.y - clouds_a.position.y) > 0.1:
		clouds_b.position.y = clouds_a.position.y
	if clouds_b.scale != clouds_a.scale:
		clouds_b.scale = clouds_a.scale

func _wrap_clouds() -> void:
	if clouds_a.position.x + _cloud_width <= 0.0:
		clouds_a.position.x = clouds_b.position.x + _cloud_width
	if clouds_b.position.x + _cloud_width <= 0.0:
		clouds_b.position.x = clouds_a.position.x + _cloud_width
