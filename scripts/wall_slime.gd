extends Area2D

@export var speed: float = 70.0
@export_enum("Left Side", "Right Side") var wall_side: int = 0
@export var wall_check_distance: float = 18.0
@export var edge_lookahead: float = 20.0
@export var hazard_lookahead: float = 20.0
@export var hazard_probe_side_offset: float = -5.0
@export var wall_attach_offset: float = 10.0
@export var reverse_cooldown_time: float = 0.12
@export var knockback_decay: float = 900.0
@export var knockback_duration: float = 0.18
@export var max_health: int = 2
@export var death_scene: PackedScene

@export_group("Drop Rates")
@export_range(0, 100) var health_drop_rate: float = 30.0
@export_range(0, 100) var energy_drop_rate: float = 30.0
@export_range(0, 100) var coin_drop_rate: float = 30.0
@export var xp_drop_value: int = 12
@export var item_scene: PackedScene = preload("res://scenes/items/ItemPickup.tscn")

@onready var edge_cast: RayCast2D = $EdgeCast
@onready var wall_cast: RayCast2D = $WallCast
@onready var hazard_cast: RayCast2D = $HazardCast
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var move_direction: int = -1 # -1 up, 1 down
var knockback_velocity: float = 0.0
var knockback_timer: float = 0.0
var current_health: int = 2
var reverse_cooldown: float = 0.0
var locked_wall_x: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	current_health = max(1, max_health)
	area_entered.connect(_on_area_entered)
	_configure_cast_collision_modes()
	_configure_cast_exceptions()
	_apply_wall_side_visuals()
	_update_casts()
	_snap_to_wall()
	locked_wall_x = global_position.x
	var sprite := $AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("breathing"):
		sprite.play("breathing")

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta
		global_position.x += knockback_velocity * delta
		knockback_velocity = move_toward(knockback_velocity, 0.0, knockback_decay * delta)
	else:
		global_position.y += speed * float(move_direction) * delta

	if reverse_cooldown > 0.0:
		reverse_cooldown = max(0.0, reverse_cooldown - delta)

	_update_casts()
	var should_reverse := false
	if not _is_edge_supported() or _is_hazard_ahead():
		should_reverse = true
	if should_reverse and reverse_cooldown <= 0.0:
		move_direction *= -1
		reverse_cooldown = reverse_cooldown_time
		global_position.y += speed * 0.08 * float(move_direction)
		_update_casts()

	if knockback_timer <= 0.0:
		if not _is_wall_attached():
			_snap_to_wall()
		global_position.x = locked_wall_x

func apply_knockback(force: float, dir: float) -> void:
	knockback_velocity = force * signf(dir)
	knockback_timer = knockback_duration

func take_damage(amount: float = 1.0, kill_context: Dictionary = {}) -> void:
	var damage := maxi(1, int(ceil(amount)))
	current_health = max(0, current_health - damage)
	if current_health <= 0:
		die(kill_context)

func get_player_knockback_multiplier() -> float:
	return 1.5

func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.is_in_group("hazards"):
		take_damage(float(max_health))

func die(kill_context: Dictionary = {}) -> void:
	if not is_inside_tree():
		return
	var drops := _build_drop_requests(kill_context)
	var total := drops.size()
	for i in range(total):
		var req: Dictionary = drops[i]
		_spawn_item(int(req.get("type", 2)), int(req.get("value", 1)), i, total)
	if death_scene:
		var fx := death_scene.instantiate()
		get_parent().add_child(fx)
		fx.global_position = global_position
	queue_free()

func _apply_wall_side_visuals() -> void:
	var sprite := $AnimatedSprite2D
	if not sprite:
		return
	# Left side of wall = slime on wall's left face.
	# Right side of wall = slime on wall's right face.
	sprite.rotation_degrees = 270.0 if wall_side == 0 else 90.0

func _update_casts() -> void:
	var wall_dir := _wall_dir()
	if wall_cast:
		wall_cast.target_position = Vector2(float(wall_dir) * wall_check_distance, 0.0)
	if edge_cast:
		edge_cast.position = Vector2(0.0, float(move_direction) * edge_lookahead)
		edge_cast.target_position = Vector2(float(wall_dir) * wall_check_distance, 0.0)
	if hazard_cast:
		hazard_cast.position = Vector2(float(wall_dir) * hazard_probe_side_offset, 0.0)
		hazard_cast.target_position = Vector2(0.0, float(move_direction) * hazard_lookahead)

func _is_wall_attached() -> bool:
	if wall_cast == null:
		return true
	wall_cast.force_raycast_update()
	return wall_cast.is_colliding()

func _is_edge_supported() -> bool:
	if edge_cast == null:
		return true
	edge_cast.force_raycast_update()
	return edge_cast.is_colliding()

func _is_hazard_ahead() -> bool:
	if hazard_cast == null:
		return false
	hazard_cast.force_raycast_update()
	if not hazard_cast.is_colliding():
		return false
	var collider := hazard_cast.get_collider() as Node
	if collider == null:
		return false
	if collider.is_in_group("hazards"):
		return true
	var parent := collider.get_parent()
	return parent != null and parent.is_in_group("hazards")

func _snap_to_wall() -> void:
	if wall_cast == null:
		return
	wall_cast.force_raycast_update()
	if not wall_cast.is_colliding():
		return
	var hit_point := wall_cast.get_collision_point()
	var wall_dir := _wall_dir()
	global_position.x = hit_point.x - float(wall_dir) * wall_attach_offset
	locked_wall_x = global_position.x

func _wall_dir() -> int:
	# +1 means wall is to the right, -1 means wall is to the left.
	return 1 if wall_side == 0 else -1

func _configure_cast_exceptions() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var player_body := node as PhysicsBody2D
		if player_body == null:
			continue
		if wall_cast:
			wall_cast.add_exception(player_body)
		if edge_cast:
			edge_cast.add_exception(player_body)
		if hazard_cast:
			hazard_cast.add_exception(player_body)

func _configure_cast_collision_modes() -> void:
	if wall_cast:
		wall_cast.collide_with_bodies = true
		wall_cast.collide_with_areas = false
	if edge_cast:
		edge_cast.collide_with_bodies = true
		edge_cast.collide_with_areas = false
	if hazard_cast:
		hazard_cast.collide_with_bodies = true
		hazard_cast.collide_with_areas = true

func _build_drop_requests(kill_context: Dictionary = {}) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	if not item_scene:
		return drops
	if xp_drop_value > 0:
		drops.append({"type": 3, "value": xp_drop_value})
	var roll := randf() * 100.0
	if roll < health_drop_rate:
		drops.append({"type": 0, "value": 1})
	elif roll < (health_drop_rate + energy_drop_rate):
		drops.append({"type": 1, "value": 1})
	elif roll < (health_drop_rate + energy_drop_rate + coin_drop_rate):
		drops.append({"type": 2, "value": 1})
	if _is_small_head_spike_kill(kill_context):
		drops.append({"type": 2, "value": 1})
	return drops

func _is_small_head_spike_kill(kill_context: Dictionary) -> bool:
	if kill_context.is_empty():
		return false
	return String(kill_context.get("source", "")) == "head_spike" and String(kill_context.get("player_mode", "")) == "small"

func _spawn_item(type: int, item_value: int = 1, spawn_index: int = 0, total_spawns: int = 1) -> void:
	if not item_scene:
		return
	var item := item_scene.instantiate()
	item.type = type
	item.value = item_value
	var root := get_tree().current_scene
	if root:
		root.add_child(item)
		item.global_position = _resolve_spawn_position(_get_spawn_origin(spawn_index, total_spawns))
		if item is CharacterBody2D:
			var throw_angle := _get_throw_angle(spawn_index, total_spawns)
			var throw_power := randf_range(250.0, 430.0)
			item.velocity = Vector2(cos(throw_angle), sin(throw_angle)) * throw_power
			item.velocity.y = clamp(item.velocity.y, -220.0, -90.0)

func _get_spawn_origin(spawn_index: int, total_spawns: int) -> Vector2:
	if total_spawns <= 1:
		return global_position + Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0))
	var radius := 14.0 + randf_range(-2.0, 2.0)
	var step := TAU / float(total_spawns)
	var angle := (step * float(spawn_index)) + randf_range(-0.2, 0.2)
	return global_position + Vector2.RIGHT.rotated(angle) * radius

func _get_throw_angle(spawn_index: int, total_spawns: int) -> float:
	if total_spawns <= 1:
		return randf_range(-PI * 0.68, -PI * 0.32)
	var t := float(spawn_index) / float(max(1, total_spawns - 1))
	var spread := lerpf(-PI * 0.72, -PI * 0.28, t)
	return spread + randf_range(-0.08, 0.08)

func _resolve_spawn_position(origin: Vector2) -> Vector2:
	var candidate := origin
	const MIN_DISTANCE := 18.0
	const MAX_ATTEMPTS := 8
	for i in range(MAX_ATTEMPTS):
		var has_overlap := false
		for node in get_tree().get_nodes_in_group("items"):
			var other := node as Node2D
			if not other:
				continue
			if other.global_position.distance_to(candidate) < MIN_DISTANCE:
				has_overlap = true
				break
		if not has_overlap:
			return candidate
		var angle := randf() * TAU
		var step := MIN_DISTANCE + float(i * 3)
		candidate = origin + Vector2.RIGHT.rotated(angle) * step
	return candidate
