extends "res://scripts/tiled_body.gd"

signal broken(platform: Node2D)

@onready var _break_area: Area2D = $BreakArea
@onready var _break_shape: CollisionShape2D = $BreakArea/CollisionShape2D
@onready var _visual_node: Sprite2D = $Visual

var _broken: bool = false
const SMOKE_TEXTURE: Texture2D = preload("res://assets/particles/smoke_particle.png")

func _ready() -> void:
	super._ready()
	if _break_area:
		_break_area.add_to_group("destroyable_platforms")
		_break_area.monitoring = true
		_break_area.monitorable = true
	_sync_break_shape()

func _apply() -> void:
	super._apply()
	_sync_break_shape()

func _sync_break_shape() -> void:
	if _collision == null or _break_shape == null or _collision.shape == null:
		return
	_break_shape.position = _collision.position
	_break_shape.shape = _collision.shape

func break_platform() -> void:
	if _broken:
		return
	_broken = true
	emit_signal("broken", self)
	_spawn_break_fx()
	if _collision:
		_collision.set_deferred("disabled", true)
	if _break_shape:
		_break_shape.set_deferred("disabled", true)
	visible = false
	queue_free()

func _spawn_break_fx() -> void:
	if _visual_node == null or _visual_node.texture == null:
		return

	var fx: Node2D = Node2D.new()
	fx.global_position = global_position
	fx.z_index = 20
	get_tree().current_scene.add_child(fx)

	var region: Rect2 = _visual_node.region_rect
	var chunk_count: int = 4
	var chunk_w: float = floorf(region.size.x / float(chunk_count))
	if chunk_w < 8.0:
		chunk_w = 8.0
	var color_tint: Color = modulate * _visual_node.modulate

	for i in range(chunk_count):
		var chunk: Sprite2D = Sprite2D.new()
		chunk.texture = _visual_node.texture
		chunk.texture_filter = 1
		chunk.texture_repeat = 2
		chunk.region_enabled = true
		chunk.region_rect = Rect2(region.position.x + chunk_w * i, region.position.y, chunk_w, region.size.y)
		chunk.centered = true
		chunk.modulate = color_tint
		chunk.position = Vector2(-region.size.x * 0.5 + chunk_w * (i + 0.5), 0.0)
		fx.add_child(chunk)

		var vx: float = randf_range(-120.0, 120.0) + (float(i) - 1.5) * 30.0
		var vy: float = randf_range(-180.0, -110.0)
		var rot: float = randf_range(-1.2, 1.2)
		var drift: float = randf_range(0.35, 0.55)

		var t: Tween = chunk.create_tween()
		t.set_parallel(true)
		t.tween_property(chunk, "position", chunk.position + Vector2(vx * drift, vy * drift), drift * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(chunk, "position", chunk.position + Vector2(vx, 80.0), drift).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(drift * 0.5)
		t.tween_property(chunk, "rotation", rot, drift)
		t.tween_property(chunk, "modulate:a", 0.0, drift * 0.9).set_delay(drift * 0.1)

	var smoke: CPUParticles2D = CPUParticles2D.new()
	smoke.texture = SMOKE_TEXTURE
	smoke.amount = 10
	smoke.lifetime = 0.45
	smoke.one_shot = true
	smoke.explosiveness = 0.9
	smoke.randomness = 0.6
	smoke.initial_velocity_min = 40.0
	smoke.initial_velocity_max = 90.0
	smoke.spread = 90.0
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.2
	smoke.color = Color(1, 1, 1, 0.85)
	fx.add_child(smoke)
	smoke.emitting = true

	var cleanup: Tween = fx.create_tween()
	cleanup.tween_interval(0.8)
	cleanup.tween_callback(fx.queue_free)
