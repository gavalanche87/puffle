extends Area2D

@export var value: int = 1
@export var pickup_enabled: bool = true
@export var pickup_lock_time: float = 0.12
@export var fly_to_hud_time: float = 0.5

@onready var backing_sprite: Sprite2D = $CoinIconBacking
@onready var icon_sprite: Sprite2D = $CoinIcon
@onready var glow_sprite: Sprite2D = $Glow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pickup_sfx: AudioStreamPlayer2D = get_node_or_null("PickupSfx") as AudioStreamPlayer2D

var collected: bool = false
var _lock_timer: float = 0.0
var _pulse_tween: Tween
var _icon_base_scale: Vector2 = Vector2.ONE
var _backing_base_scale: Vector2 = Vector2.ONE
var _glow_base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	_lock_timer = maxf(0.0, pickup_lock_time)
	_icon_base_scale = icon_sprite.scale if icon_sprite else Vector2.ONE
	_backing_base_scale = backing_sprite.scale if backing_sprite else Vector2.ONE
	_glow_base_scale = glow_sprite.scale if glow_sprite else Vector2.ONE

	if not pickup_enabled or _is_non_world_pickup_context():
		_disable_pickup()
		return

	add_to_group("items")
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	monitorable = true
	if collision_shape:
		collision_shape.disabled = false
	_start_pulse()

func _physics_process(delta: float) -> void:
	if _lock_timer > 0.0:
		_lock_timer = max(0.0, _lock_timer - delta)

func set_pickup_enabled(enabled: bool) -> void:
	pickup_enabled = enabled
	if not enabled:
		_disable_pickup()

func collect(player: Node2D) -> void:
	if collected or not pickup_enabled or _lock_timer > 0.0:
		return
	if player and player.has_method("can_collect_item"):
		if not bool(player.call("can_collect_item", 2)):
			return
	collected = true
	_disable_pickup()
	if pickup_sfx and pickup_sfx.stream:
		pickup_sfx.play()
	_fly_to_coin_hud(player)

func _fly_to_coin_hud(player: Node2D) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null and get_tree().current_scene:
		hud = get_tree().current_scene.get_node_or_null("HUD")

	var target_node: Node = null
	if hud:
		target_node = hud.get_node_or_null("CoinItem/CoinIcon")
		if target_node == null:
			target_node = hud.find_child("CoinIcon", true, false)

	var start_screen_pos := get_viewport().get_canvas_transform() * global_position
	var target_screen_pos := Vector2(454.0, 58.0)
	if target_node:
		if target_node is Control:
			var ctrl := target_node as Control
			target_screen_pos = ctrl.global_position + (ctrl.size * 0.5)
		elif target_node is Node2D:
			target_screen_pos = (target_node as Node2D).global_position

	var target_parent: Node = hud if hud else get_tree().current_scene
	if target_parent:
		reparent(target_parent, false)
	position = start_screen_pos

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", target_screen_pos, fly_to_hud_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if icon_sprite:
		tween.tween_property(icon_sprite, "scale", _icon_base_scale * 0.42, fly_to_hud_time)
		tween.tween_property(icon_sprite, "rotation", icon_sprite.rotation + (PI * 2.6), fly_to_hud_time)
	if backing_sprite:
		tween.tween_property(backing_sprite, "scale", _backing_base_scale * 0.6, fly_to_hud_time)
	if glow_sprite:
		tween.tween_property(glow_sprite, "modulate:a", 0.0, fly_to_hud_time * 0.8)
	await tween.finished

	if player and player.has_method("on_coin_item_landed"):
		player.call("on_coin_item_landed", value)
	queue_free()

func _start_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_running():
		_pulse_tween.kill()
	if glow_sprite:
		glow_sprite.visible = true
		glow_sprite.modulate = Color(1.0, 0.9, 0.4, 0.7)
		glow_sprite.scale = _glow_base_scale * 1.2
	_pulse_tween = create_tween().set_loops()
	if backing_sprite:
		_pulse_tween.tween_property(backing_sprite, "modulate:a", 0.42, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		_pulse_tween.tween_interval(0.5)
	if glow_sprite:
		_pulse_tween.parallel().tween_property(glow_sprite, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
		_pulse_tween.parallel().tween_property(glow_sprite, "scale", _glow_base_scale * 2.1, 0.5).set_trans(Tween.TRANS_SINE)
	if backing_sprite:
		_pulse_tween.tween_property(backing_sprite, "modulate:a", 0.95, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		_pulse_tween.tween_interval(0.5)
	if glow_sprite:
		_pulse_tween.parallel().tween_property(glow_sprite, "modulate:a", 0.25, 0.5).set_trans(Tween.TRANS_SINE)
		_pulse_tween.parallel().tween_property(glow_sprite, "scale", _glow_base_scale * 1.1, 0.5).set_trans(Tween.TRANS_SINE)

func _disable_pickup() -> void:
	pickup_enabled = false
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	if collision_shape:
		collision_shape.disabled = true
	if is_in_group("items"):
		remove_from_group("items")
	if _pulse_tween and _pulse_tween.is_running():
		_pulse_tween.kill()
	if glow_sprite:
		glow_sprite.visible = false

func _is_non_world_pickup_context() -> bool:
	var node: Node = self
	while node:
		if node is CanvasLayer:
			return true
		if node.is_in_group("hud"):
			return true
		if node.name == "IconAnchor":
			return true
		var script_ref := node.get_script() as Script
		if script_ref:
			var script_path := String(script_ref.resource_path)
			if script_path == "res://scripts/item_pickup.gd" or script_path == "res://scripts/floating_text.gd":
				return true
		node = node.get_parent()
	return false
