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

@onready var floor_cast: RayCast2D = $FloorCast
@onready var wall_cast: RayCast2D = $WallCast
@onready var ground_cast: RayCast2D = $GroundCast
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var knockback_velocity: float = 0.0
var knockback_timer: float = 0.0
var vertical_velocity: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_update_casts()
	var sprite := $AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")

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

func die() -> void:
	if death_scene:
		var fx := death_scene.instantiate()
		get_parent().add_child(fx)
		fx.global_position = global_position
	queue_free()

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
