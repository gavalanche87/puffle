extends Area2D

@export var speed: float = 80.0
@export var direction: int = -1
@export var fall_gravity: float = 1400.0
@export var max_fall_speed: float = 900.0
@export var floor_ray_length: float = 32.0
@export var wall_ray_length: float = 12.0
@export var knockback_decay: float = 900.0
@export var knockback_duration: float = 0.18
@export var death_scene: PackedScene
@export var flip_when_moving_right: bool = true

@export_group("Drop Rates")
@export_range(0, 100) var health_drop_rate: float = 30.0
@export_range(0, 100) var energy_drop_rate: float = 30.0
@export_range(0, 100) var coin_drop_rate: float = 30.0
@export var xp_drop_value: int = 10
@export var item_scene: PackedScene = preload("res://scenes/ItemPickup.tscn")

@onready var floor_cast: RayCast2D = $FloorCast
@onready var wall_cast: RayCast2D = $WallCast
@onready var ground_cast: RayCast2D = $GroundCast
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var knockback_velocity: float = 0.0
var knockback_timer: float = 0.0
var vertical_velocity: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)
	_configure_cast_exceptions()
	_update_casts()
	var sprite := $AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")

func _configure_cast_exceptions() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var player_body := node as PhysicsBody2D
		if player_body == null:
			continue
		if floor_cast:
			floor_cast.add_exception(player_body)
		if wall_cast:
			wall_cast.add_exception(player_body)
		if ground_cast:
			ground_cast.add_exception(player_body)

func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.is_in_group("hazards"):
		call_deferred("die")

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta
		global_position.x += knockback_velocity * delta
		knockback_velocity = move_toward(knockback_velocity, 0.0, knockback_decay * delta)
	else:
		global_position.x += speed * direction * delta

	# Gravity and landing snap so enemies can be placed in mid-air.
	vertical_velocity = min(vertical_velocity + fall_gravity * delta, max_fall_speed)
	global_position.y += vertical_velocity * delta

	_update_casts()
	if vertical_velocity >= 0.0 and _is_grounded():
		_snap_to_ground()
		vertical_velocity = 0.0

	# Patrol decisions should only run while grounded.
	if vertical_velocity == 0.0 and (_is_at_edge() or _is_hitting_wall()):
		direction *= -1

	_update_facing()

func apply_knockback(force: float, dir: float) -> void:
	knockback_velocity = force * signf(dir)
	knockback_timer = knockback_duration

func _update_facing() -> void:
	var sprite := $AnimatedSprite2D
	if sprite:
		sprite.flip_h = direction > 0 if flip_when_moving_right else direction < 0

func die(kill_context: Dictionary = {}) -> void:
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

func _build_drop_requests(kill_context: Dictionary = {}) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	if not item_scene:
		return drops
	if xp_drop_value > 0:
		drops.append({"type": 3, "value": xp_drop_value}) # ItemType.XP
		
	var roll := randf() * 100.0
	
	var h_rate := _get_effective_drop_rate(health_drop_rate)
	var e_rate := _get_effective_drop_rate(energy_drop_rate)
	var c_rate := _get_effective_drop_rate(coin_drop_rate)
	
	# Priority: Health > Energy > Coin
	if roll < h_rate:
		drops.append({"type": 0, "value": 1}) # ItemType.HEALTH
	elif roll < (h_rate + e_rate):
		drops.append({"type": 1, "value": 1}) # ItemType.ENERGY
	elif roll < (h_rate + e_rate + c_rate):
		drops.append({"type": 2, "value": 1}) # ItemType.COIN
	if _is_small_head_spike_kill(kill_context):
		drops.append({"type": 2, "value": 1}) # bonus coin on small-mode head spike kill
	return drops

func _is_small_head_spike_kill(kill_context: Dictionary) -> bool:
	if kill_context.is_empty():
		return false
	return String(kill_context.get("source", "")) == "head_spike" and String(kill_context.get("player_mode", "")) == "small"

func _get_effective_drop_rate(base_rate: float) -> float:
	# This can be expanded later to check for player "charms" or modifiers
	var multiplier := 1.0
	
	# Future: multiplier = GameManager.get_drop_multiplier()
	
	return base_rate * multiplier

func _spawn_item(type: int, item_value: int = 1, spawn_index: int = 0, total_spawns: int = 1) -> void:
	if not item_scene:
		return
		
	var item := item_scene.instantiate()
	# SET TYPE BEFORE ADD_CHILD so _ready can use it!
	item.type = type
	item.value = item_value
	
	var root := get_tree().current_scene
	if root:
		root.add_child(item)
		item.global_position = _resolve_spawn_position(_get_spawn_origin(spawn_index, total_spawns))
		
		# Give the item a random "throw" velocity
		if item is CharacterBody2D:
			var throw_angle := _get_throw_angle(spawn_index, total_spawns)
			var throw_power := randf_range(250.0, 430.0)
			item.velocity = Vector2(cos(throw_angle), sin(throw_angle)) * throw_power
			# Keep launch upward but cap excessive arcs that cause unstable chains.
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

func _is_at_edge() -> bool:
	floor_cast.force_raycast_update()
	return not floor_cast.is_colliding()

func _is_hitting_wall() -> bool:
	wall_cast.force_raycast_update()
	return wall_cast.is_colliding()

func _is_grounded() -> bool:
	ground_cast.force_raycast_update()
	return ground_cast.is_colliding()

func _snap_to_ground() -> void:
	if not ground_cast.is_colliding():
		return
	var collision_point := ground_cast.get_collision_point()
	var bottom_offset := _get_bottom_offset()
	global_position.y = collision_point.y - bottom_offset

func _get_bottom_offset() -> float:
	if collision_shape == null or collision_shape.shape == null:
		return 0.0
	if collision_shape.shape is RectangleShape2D:
		var rect := collision_shape.shape as RectangleShape2D
		# Compute bottom in global space so parent scaling (e.g. GreenEnemy scale=2)
		# is correctly accounted for when snapping to the floor.
		var local_bottom := collision_shape.position + Vector2(0.0, rect.size.y * 0.5)
		var global_bottom := to_global(local_bottom)
		return global_bottom.y - global_position.y
	return collision_shape.position.y

func _update_casts() -> void:
	floor_cast.target_position = Vector2(direction * 12.0, floor_ray_length)
	wall_cast.target_position = Vector2(direction * wall_ray_length, 0.0)
	ground_cast.target_position = Vector2(0.0, floor_ray_length)
