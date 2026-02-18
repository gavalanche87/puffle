extends CharacterBody2D

enum ItemType {HEALTH, ENERGY, COIN, XP}

@export var type: ItemType = ItemType.COIN:
	set(val):
		type = val
		_setup_item()

@export var value: int = 1
@export var gravity: float = 900.0
@export var friction: float = 0.95
@export var bounciness: float = 0.6

@onready var icon_anchor: Node2D = $IconAnchor
@onready var backing_sprite: Sprite2D = $Backing
@onready var glow_sprite: Sprite2D = $Glow
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSfx

var collected: bool = false
var pickup_lock_timer: float = 0.25
var backing_color: Color = Color(1.0, 0.9, 0.2, 0.9)
var glow_color: Color = Color(1.0, 0.9, 0.4, 0.8)
var icon_visual: Node2D
var icon_base_scale: Vector2 = Vector2.ONE
var glow_base_scale: Vector2 = Vector2.ONE
var item_backing: CanvasItem
var item_backing_base_scale: Vector2 = Vector2.ONE
var player_body_collision_disabled: bool = false

const HEALTH_ITEM_SCENE: PackedScene = preload("res://scenes/items/HealthItem.tscn")
const ENERGY_ITEM_SCENE: PackedScene = preload("res://scenes/items/EnergyItem.tscn")
const XP_ITEM_SCENE: PackedScene = preload("res://scenes/items/XPItem.tscn")
const COIN_ITEM_SCENE: PackedScene = preload("res://scenes/items/CoinItem.tscn")

func _ready() -> void:
	add_to_group("items")
	if pickup_area:
		pickup_area.add_to_group("items")
		pickup_area.set_deferred("monitorable", true)
	_disable_player_body_collision()
	_setup_item()

	icon_base_scale = icon_visual.scale if icon_visual else Vector2.ONE
	item_backing_base_scale = _get_canvas_scale(item_backing)
	glow_base_scale = glow_sprite.scale
	backing_sprite.visible = false

	if icon_visual:
		icon_visual.scale = Vector2.ZERO
	glow_sprite.scale = Vector2.ZERO
	if item_backing and item_backing is Node2D:
		(item_backing as Node2D).scale = Vector2.ZERO

	var intro := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if icon_visual:
		intro.tween_property(icon_visual, "scale", icon_base_scale, 0.25)
	if item_backing and item_backing is Node2D:
		intro.tween_property(item_backing, "scale", item_backing_base_scale, 0.25)
	intro.tween_property(glow_sprite, "scale", glow_base_scale, 0.3)

	var pulse := create_tween().set_loops()
	if item_backing:
		pulse.tween_property(item_backing, "modulate:a", 0.38, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		pulse.tween_interval(0.5)
	pulse.parallel().tween_property(glow_sprite, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	pulse.parallel().tween_property(glow_sprite, "scale", glow_base_scale * 2.2, 0.5).set_trans(Tween.TRANS_SINE)
	if item_backing:
		pulse.tween_property(item_backing, "modulate:a", 0.95, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		pulse.tween_interval(0.5)
	pulse.parallel().tween_property(glow_sprite, "modulate:a", 0.25, 0.5).set_trans(Tween.TRANS_SINE)
	pulse.parallel().tween_property(glow_sprite, "scale", glow_base_scale * 1.2, 0.5).set_trans(Tween.TRANS_SINE)

func _setup_item() -> void:
	if not is_node_ready():
		return

	_clear_icon_visual()
	match type:
		ItemType.HEALTH:
			icon_visual = HEALTH_ITEM_SCENE.instantiate() as Node2D
			backing_color = Color(1.0, 0.2, 0.25, 0.9)
			glow_color = Color(1.0, 0.35, 0.35, 0.8)
			particles.color = Color(1, 0.2, 0.2)
		ItemType.ENERGY:
			icon_visual = ENERGY_ITEM_SCENE.instantiate() as Node2D
			backing_color = Color(0.2, 0.75, 1.0, 0.9)
			glow_color = Color(0.35, 0.75, 1.0, 0.8)
			particles.color = Color(0.2, 0.6, 1.0)
		ItemType.COIN:
			icon_visual = COIN_ITEM_SCENE.instantiate() as Node2D
			backing_color = Color(1.0, 0.85, 0.15, 0.9)
			glow_color = Color(1.0, 0.9, 0.4, 0.8)
			particles.color = Color(1.0, 0.9, 0.2)
		ItemType.XP:
			icon_visual = XP_ITEM_SCENE.instantiate() as Node2D
			backing_color = Color(0.7, 0.3, 1.0, 0.9)
			glow_color = Color(0.85, 0.45, 1.0, 0.85)
			particles.color = Color(0.75, 0.35, 1.0)

	if icon_visual:
		icon_anchor.add_child(icon_visual)
		if type == ItemType.XP:
			var xp_label := icon_visual.get_node_or_null("XpLevelLabel") as Label
			if xp_label:
				xp_label.visible = false
			var xp_icon := icon_visual.get_node_or_null("XpIcon") as CanvasItem
			if xp_icon:
				xp_icon.modulate = Color(0.78, 0.45, 1.0, 1.0)
		icon_visual.position = Vector2.ZERO
		item_backing = _find_item_backing(icon_visual)

	icon_base_scale = icon_visual.scale if icon_visual else Vector2.ONE
	item_backing_base_scale = _get_canvas_scale(item_backing)
	glow_base_scale = glow_sprite.scale

	if item_backing:
		item_backing.modulate = backing_color
	glow_sprite.modulate = glow_color

func _physics_process(delta: float) -> void:
	if collected:
		return
	if not player_body_collision_disabled:
		_disable_player_body_collision()

	if pickup_lock_timer > 0.0:
		pickup_lock_timer -= delta

	velocity.y += gravity * delta

	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider_obj := collision.get_collider() as Node
		if collider_obj and collider_obj.is_in_group("player"):
			var player_body := collider_obj as PhysicsBody2D
			if player_body:
				add_collision_exception_with(player_body)
				player_body.add_collision_exception_with(self)
			return
		velocity = velocity.bounce(collision.get_normal()) * bounciness
		if collision.get_normal().y < -0.7:
			velocity.x *= friction
			if abs(velocity.y) < 50.0:
				velocity.y = 0.0

	if abs(velocity.x) > 10.0:
		if icon_visual:
			icon_visual.rotation += (velocity.x * delta) * 0.12

func collect(player: Node2D) -> void:
	if collected or pickup_lock_timer > 0.0:
		return
	if player and player.has_method("can_collect_item"):
		var allowed := bool(player.call("can_collect_item", int(type)))
		if not allowed:
			return
	collected = true

	collision_layer = 0
	collision_mask = 0
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if body_collision:
		body_collision.disabled = true
		body_collision.set_deferred("disabled", true)
	if pickup_area:
		pickup_area.monitoring = false
		pickup_area.monitorable = false
		pickup_area.set_deferred("monitoring", false)
		pickup_area.set_deferred("monitorable", false)

	if pickup_sfx:
		pickup_sfx.play()

	if type == ItemType.HEALTH or type == ItemType.ENERGY or type == ItemType.XP or type == ItemType.COIN:
		_fly_xp_to_hud(player)
		return

	_play_pickup_burst()
	if player.has_method("on_item_picked"):
		player.call("on_item_picked", type, value)
	queue_free()

func _fly_xp_to_hud(player: Node2D) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null and get_tree().current_scene:
		hud = get_tree().current_scene.get_node_or_null("HUD")

	var target_path := "XpBarBg"
	if type == ItemType.HEALTH:
		target_path = "HealthBarBg"
	elif type == ItemType.ENERGY:
		target_path = "EnergyBarBg"
	elif type == ItemType.COIN:
		target_path = "CoinItem/CoinIcon"
	var target_node: Node = null
	if hud:
		target_node = hud.get_node_or_null(target_path)
		if target_node == null:
			target_node = hud.find_child(target_path, true, false)

	var start_screen_pos := get_viewport().get_canvas_transform() * global_position
	var target_screen_pos := Vector2(560.0, 28.0)
	if type == ItemType.HEALTH:
		target_screen_pos = Vector2(120.0, 22.0)
	elif type == ItemType.ENERGY:
		target_screen_pos = Vector2(120.0, 52.0)
	elif type == ItemType.COIN:
		target_screen_pos = Vector2(454.0, 58.0)
	if target_node:
		if target_node is Control:
			var control := target_node as Control
			target_screen_pos = control.global_position + (control.size * 0.5)
		elif target_node is Node2D:
			target_screen_pos = (target_node as Node2D).global_position

	var target_parent: Node = hud if hud else get_tree().current_scene
	if target_parent:
		reparent(target_parent, false)
	position = start_screen_pos
	velocity = Vector2.ZERO

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", target_screen_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if icon_visual:
		tween.tween_property(icon_visual, "scale", icon_base_scale * 0.42, 0.5)
		tween.tween_property(icon_visual, "rotation", icon_visual.rotation + PI * 2.6, 0.5)
	if item_backing and item_backing is Node2D:
		tween.tween_property(item_backing, "scale", item_backing_base_scale * 0.6, 0.5)
	tween.tween_property(glow_sprite, "modulate:a", 0.0, 0.4)
	await tween.finished

	_play_pickup_burst()
	_apply_landing_reward(player)
	await get_tree().create_timer(0.12).timeout
	queue_free()

func _apply_landing_reward(player: Node2D) -> void:
	if type == ItemType.XP:
		if player.has_method("on_xp_item_landed"):
			player.call("on_xp_item_landed", value)
	elif type == ItemType.HEALTH:
		if player.has_method("on_health_item_landed"):
			player.call("on_health_item_landed", value)
	elif type == ItemType.ENERGY:
		if player.has_method("on_energy_item_landed"):
			player.call("on_energy_item_landed", value)
	elif type == ItemType.COIN:
		if player.has_method("on_coin_item_landed"):
			player.call("on_coin_item_landed", value)

func _play_pickup_burst() -> void:
	if icon_visual:
		icon_visual.visible = false
	if item_backing:
		item_backing.visible = false
	glow_sprite.visible = false
	particles.color = backing_color
	particles.amount = 18
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 220.0
	particles.gravity = Vector2.ZERO
	particles.spread = 180.0
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.restart()

func _clear_icon_visual() -> void:
	for child in icon_anchor.get_children():
		child.queue_free()
	icon_visual = null
	item_backing = null

func _find_item_backing(root: Node) -> CanvasItem:
	for node_name in ["HealthIconBacking", "EnergyIconBacking", "XpIconBacking", "CoinIconBacking"]:
		var found := root.get_node_or_null(node_name) as CanvasItem
		if found:
			return found
	return null

func _get_canvas_scale(item: CanvasItem) -> Vector2:
	if item and item is Node2D:
		return (item as Node2D).scale
	return Vector2.ONE

func _disable_player_body_collision() -> void:
	var disabled_any := false
	for node in get_tree().get_nodes_in_group("player"):
		var player_body := node as PhysicsBody2D
		if not player_body:
			continue
		add_collision_exception_with(player_body)
		player_body.add_collision_exception_with(self)
		disabled_any = true
	player_body_collision_disabled = disabled_any
