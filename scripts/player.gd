extends CharacterBody2D

enum PlayerMode { SMALL, BIG }

@export var small_speed: float = 320.0
@export var small_gravity: float = 700.0
@export var small_scale: Vector2 = Vector2(1.5, 1.5)

@export var big_speed: float = 180.0
@export var big_gravity: float = 1800.0
@export var big_scale: Vector2 = Vector2(3.0, 3.0)
@export var big_damage_multiplier: float = 0.6
@export var small_frames: SpriteFrames
@export var big_frames: SpriteFrames

@export var small_jump_velocity: float = -550.0
@export var big_jump_velocity: float = -380.0
@export var squash_time: float = 0.12

var mode: PlayerMode = PlayerMode.SMALL
var damage_multiplier: float = 1.0
@export var max_health: int = 100
@export var enemy_contact_damage: int = 20
@export var damage_cooldown: float = 0.5
@export var stomp_bounce_velocity: float = -520.0
@export var small_player_knockback: float = 420.0
@export var big_player_knockback: float = 260.0
@export var small_enemy_knockback: float = 120.0
@export var big_enemy_knockback: float = 220.0
var current_health: int = max_health
var damage_cooldown_timer: float = 0.0
@export var grounded_grace: float = 0.08
var grounded_timer: float = 0.0
@export var knockback_decay: float = 1200.0
var knockback_velocity: float = 0.0

@onready var health_label: Label = $CanvasLayer/HealthLabel
@onready var hurtbox: Area2D = $Hurtbox
@onready var sfx_jump: AudioStreamPlayer = $SfxJump
@onready var sfx_stomp: AudioStreamPlayer = $SfxStomp
@onready var sfx_switch: AudioStreamPlayer = $SfxSwitch
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var camera_offset: Vector2 = Vector2.ZERO

var mode_tween: Tween

func _ready() -> void:
	_ensure_toggle_action()
	current_health = max_health
	_update_health_ui()
	_apply_mode(mode, false)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	camera_offset = camera.position
	_update_camera(true)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_mode"):
		mode = PlayerMode.BIG if mode == PlayerMode.SMALL else PlayerMode.SMALL
		_apply_mode(mode, true)
		_play_sfx(sfx_switch)

	if damage_cooldown_timer > 0.0:
		damage_cooldown_timer -= delta
	if knockback_velocity != 0.0:
		knockback_velocity = move_toward(knockback_velocity, 0.0, knockback_decay * delta)

	var input_dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir * _current_speed() + knockback_velocity

	if not is_on_floor():
		velocity.y += _current_gravity() * delta
	else:
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = _current_jump_velocity()
			_play_sfx(sfx_jump)

	move_and_slide()
	if is_on_floor():
		grounded_timer = grounded_grace
	else:
		grounded_timer = max(0.0, grounded_timer - delta)
	_update_facing()
	_update_animation()
	_update_camera()

func take_damage(amount: float) -> float:
	var final_amount := amount * damage_multiplier
	if damage_cooldown_timer > 0.0:
		return 0.0
	damage_cooldown_timer = damage_cooldown
	current_health = max(0, current_health - int(round(final_amount)))
	_update_health_ui()
	if current_health <= 0:
		get_tree().reload_current_scene()
	return final_amount

func _apply_mode(new_mode: PlayerMode, animate: bool) -> void:
	if new_mode == PlayerMode.SMALL:
		_set_mode_scale(small_scale, animate)
		damage_multiplier = 1.0
		_set_frames(small_frames)
	else:
		_set_mode_scale(big_scale, animate)
		damage_multiplier = big_damage_multiplier
		_set_frames(big_frames)

func _current_speed() -> float:
	return small_speed if mode == PlayerMode.SMALL else big_speed

func _current_gravity() -> float:
	return small_gravity if mode == PlayerMode.SMALL else big_gravity

func _current_jump_velocity() -> float:
	return small_jump_velocity if mode == PlayerMode.SMALL else big_jump_velocity

func _ensure_toggle_action() -> void:
	if InputMap.has_action("toggle_mode"):
		return
	InputMap.add_action("toggle_mode")
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_Z
	InputMap.action_add_event("toggle_mode", key_event)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemies"):
		return
	var is_stomp := velocity.y > 0.0 and global_position.y < area.global_position.y - 6.0
	if is_stomp and mode == PlayerMode.BIG:
		if area.has_method("die"):
			area.call("die")
		velocity.y = stomp_bounce_velocity
		_play_sfx(sfx_stomp)
	else:
		_apply_knockback(area)
		take_damage(enemy_contact_damage)

func _update_health_ui() -> void:
	if health_label:
		health_label.text = "HP: %d/%d" % [current_health, max_health]
	else:
		print("HP: %d/%d" % [current_health, max_health])

func _set_mode_scale(target_scale: Vector2, animate: bool) -> void:
	if not animate:
		scale = target_scale
		return
	if mode_tween and mode_tween.is_running():
		mode_tween.kill()
	var squash := Vector2(target_scale.x * 1.2, target_scale.y * 0.8)
	scale = squash
	mode_tween = create_tween()
	mode_tween.tween_property(self, "scale", target_scale, squash_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.play()

func _set_frames(frames: SpriteFrames) -> void:
	if not sprite or not frames:
		return
	var current_anim := sprite.animation
	var is_playing := sprite.is_playing()
	sprite.sprite_frames = frames
	if sprite.sprite_frames.has_animation(current_anim):
		sprite.play(current_anim)
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	if not is_playing:
		sprite.stop()

func _apply_knockback(enemy_area: Area2D) -> void:
	var dir := signf(global_position.x - enemy_area.global_position.x)
	if dir == 0.0:
		dir = -1.0
	var player_force := small_player_knockback if mode == PlayerMode.SMALL else big_player_knockback
	knockback_velocity = player_force * dir
	velocity.y = min(velocity.y, -80.0)

	var enemy_force := small_enemy_knockback if mode == PlayerMode.SMALL else big_enemy_knockback
	# Enemy knockback disabled for now.

func _update_camera(force: bool = false) -> void:
	if not camera:
		return
	var target := global_position + camera_offset
	if force:
		camera.global_position = target
	else:
		camera.global_position = camera.global_position.lerp(target, 0.2)

func _update_facing() -> void:
	if not sprite:
		return
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x > 0.0
	if _is_grounded():
		sprite.flip_v = false
	else:
		sprite.flip_v = velocity.y > 0.0 and mode == PlayerMode.BIG

func _update_animation() -> void:
	if not sprite:
		return
	var next_anim := "idle"
	if _is_grounded():
		if absf(velocity.x) > 1.0:
			next_anim = "run"
	else:
		next_anim = "jump" if velocity.y < 0.0 else "fall"
	if sprite.animation != next_anim:
		sprite.play(next_anim)

func _is_grounded() -> bool:
	return grounded_timer > 0.0
