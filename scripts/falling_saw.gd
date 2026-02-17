extends RigidBody2D

@export var damage: int = 20
@export var lifetime_seconds: float = 5.0
@export var fade_out_seconds: float = 0.35
@export var spin_speed_degrees: float = 720.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_area: Area2D = $HitArea
@onready var _notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var collision_sfx: AudioStreamPlayer2D = $CollisionSfx

var _is_on_screen: bool = false
var _fading_out: bool = false
var _collision_sfx_cooldown: float = 0.0

func _ready() -> void:
	gravity_scale = 1.0
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)
	angular_velocity = deg_to_rad(spin_speed_degrees)
	if hit_area:
		hit_area.add_to_group("hazards")
		hit_area.monitoring = true
		hit_area.monitorable = true
		hit_area.area_entered.connect(_on_hit_area_entered)
	if _notifier:
		_notifier.screen_entered.connect(_on_screen_entered)
		_notifier.screen_exited.connect(_on_screen_exited)
	if linear_velocity.length() < 10.0:
		linear_velocity = Vector2(randf_range(-90.0, 90.0), randf_range(-140.0, -85.0))
	_start_lifetime_sequence()

func launch(initial_velocity: Vector2) -> void:
	linear_velocity = initial_velocity

func get_damage_amount() -> int:
	return damage

func _process(delta: float) -> void:
	if _collision_sfx_cooldown > 0.0:
		_collision_sfx_cooldown -= delta
	if sprite:
		sprite.rotation += deg_to_rad(spin_speed_degrees) * delta

func _on_body_entered(_body: Node) -> void:
	if _collision_sfx_cooldown > 0.0:
		return
	if collision_sfx and collision_sfx.stream:
		collision_sfx.play()
	_collision_sfx_cooldown = 0.12

func _on_hit_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.is_in_group("enemies"):
		var enemy := area.get_parent()
		if enemy and enemy.has_method("die"):
			enemy.call_deferred("die")

func _start_lifetime_sequence() -> void:
	var tween := create_tween()
	tween.tween_interval(maxf(0.0, lifetime_seconds - fade_out_seconds))
	tween.tween_callback(_begin_fade_out)

func _begin_fade_out() -> void:
	if _fading_out:
		return
	_fading_out = true
	if body_shape:
		body_shape.set_deferred("disabled", true)
	if hit_area:
		hit_area.set_deferred("monitoring", false)
		hit_area.set_deferred("monitorable", false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, maxf(0.01, fade_out_seconds)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _on_screen_entered() -> void:
	if _is_on_screen:
		return
	_is_on_screen = true
	var manager := get_tree().root.get_node_or_null("AudioManager")
	if manager and manager.has_method("add_saw_on_screen"):
		manager.call("add_saw_on_screen")

func _on_screen_exited() -> void:
	if not _is_on_screen:
		return
	_is_on_screen = false
	var manager := get_tree().root.get_node_or_null("AudioManager")
	if manager and manager.has_method("remove_saw_on_screen"):
		manager.call("remove_saw_on_screen")

func _exit_tree() -> void:
	if _is_on_screen:
		var manager := get_tree().root.get_node_or_null("AudioManager")
		if manager and manager.has_method("remove_saw_on_screen"):
			manager.call("remove_saw_on_screen")
