@tool
extends StaticBody2D

@export_enum("ground", "platform", "wall") var body_type := "platform":
	set(value):
		body_type = value
		_apply()

@export_range(1, 512, 1) var length_tiles: int = 7:
	set(value):
		length_tiles = max(1, value)
		_apply()

@export var visual_offset: Vector2 = Vector2.ZERO:
	set(value):
		visual_offset = value
		_apply()

@export var collision_offset: Vector2 = Vector2.ZERO:
	set(value):
		collision_offset = value
		_apply()

@onready var _visual: Sprite2D = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_ensure_unique_collision_shape()
	_apply()

func _notification(what: int) -> void:
	if what == NOTIFICATION_POSTINITIALIZE:
		_apply()

func _ensure_unique_collision_shape() -> void:
	if _collision == null or _collision.shape == null:
		return
	# Prevent one instance edit from mutating every instance in the editor.
	if not _collision.shape.resource_local_to_scene:
		var shape_copy := _collision.shape.duplicate(true)
		shape_copy.resource_local_to_scene = true
		_collision.shape = shape_copy

func _apply() -> void:
	if _visual == null or _collision == null:
		return

	_ensure_unique_collision_shape()
	var tiles_px := float(length_tiles * 32)

	_visual.position = visual_offset
	_visual.scale = Vector2(1.0, 1.0)
	_visual.region_enabled = true
	_visual.region_rect = Rect2(0.0, 0.0, tiles_px, 32.0)
	_visual.rotation = 1.5708 if body_type == "wall" else 0.0

	_collision.position = collision_offset
	if _collision.shape is RectangleShape2D:
		var rect := _collision.shape as RectangleShape2D
		rect.size = Vector2(32.0, tiles_px) if body_type == "wall" else Vector2(tiles_px, 32.0)
