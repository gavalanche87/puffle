extends Area2D

@export var speed: float = 80.0
@export var direction: int = -1
@export var floor_ray_length: float = 32.0
@export var wall_ray_length: float = 12.0
@export var knockback_decay: float = 900.0
@export var knockback_duration: float = 0.18
@export var death_scene: PackedScene

@onready var floor_cast: RayCast2D = $FloorCast
@onready var wall_cast: RayCast2D = $WallCast

var knockback_velocity: float = 0.0
var knockback_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_update_casts()

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta
		global_position.x += knockback_velocity * delta
		knockback_velocity = move_toward(knockback_velocity, 0.0, knockback_decay * delta)
	else:
		global_position.x += speed * direction * delta

	_update_casts()
	if _is_at_edge() or _is_hitting_wall():
		direction *= -1

	_update_facing()

func apply_knockback(force: float, dir: float) -> void:
	knockback_velocity = force * signf(dir)
	knockback_timer = knockback_duration

func _update_facing() -> void:
	var sprite := $AnimatedSprite2D
	if sprite:
		sprite.flip_h = direction > 0

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

func _update_casts() -> void:
	floor_cast.target_position = Vector2(direction * 12.0, floor_ray_length)
	wall_cast.target_position = Vector2(direction * wall_ray_length, 0.0)
