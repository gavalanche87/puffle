extends CharacterBody2D

enum PlayerMode { SMALL, BIG }

@export var small_speed: float = 320.0
@export var small_gravity: float = 700.0
@export var small_scale: Vector2 = Vector2(1.5, 1.5)

@export var big_speed: float = 180.0
@export var big_gravity: float = 1800.0
@export var big_scale: Vector2 = Vector2(1.0, 1.0)
@export var big_damage_multiplier: float = 0.6
@export var small_frames: SpriteFrames
@export var big_frames: SpriteFrames

@export var small_jump_velocity: float = -550.0
@export var big_jump_velocity: float = -760.0
@export var squash_time: float = 0.12
@export var wall_slide_speed: float = 120.0
@export var wall_jump_vertical: float = -500.0
@export var wall_jump_horizontal: float = 750.0
@export var wall_jump_lock_time: float = 0.18
@export var wall_snap_distance: float = 6.0
@export var wall_snap_nudge: float = 1.5
@export var ground_friction: float = 1400.0
@export var air_accel: float = 2200.0
@export var air_brake: float = 0.0
@export var ground_accel: float = 3200.0

var mode: PlayerMode = PlayerMode.SMALL
var damage_multiplier: float = 1.0
@export var max_health: int = 100
@export var enemy_contact_damage: int = 20
@export var damage_cooldown: float = 0.5
@export var stomp_bounce_velocity: float = -520.0
@export var small_player_knockback: float = 160.0
@export var big_player_knockback: float = 100.0
@export var max_knockback: float = 500.0
@export var small_enemy_knockback: float = 120.0
@export var big_enemy_knockback: float = 220.0
var current_health: int = max_health
var damage_cooldown_timer: float = 0.0
@export var grounded_grace: float = 0.08
var grounded_timer: float = 0.0
@export var knockback_decay: float = 1200.0
var knockback_velocity: float = 0.0
var wall_normal: Vector2 = Vector2.ZERO
var wall_jump_timer: float = 0.0
var base_body_size: Vector2 = Vector2.ZERO
var base_hurt_size: Vector2 = Vector2.ZERO

var health_bar_bg: Control
var health_bar_fill: Control
var coins_label: Label
@onready var floating_text_scene: PackedScene = preload("res://scenes/FloatingText.tscn")
@onready var coin_icon: Texture2D = preload("res://assets/items/Coin.png")
@onready var heart_icon: Texture2D = preload("res://assets/items/pixel heart 2.png")
@onready var hurtbox: Area2D = $Hurtbox
@onready var sfx_jump: AudioStreamPlayer = $SfxJump
@onready var sfx_stomp: AudioStreamPlayer = $SfxStomp
@onready var sfx_switch: AudioStreamPlayer = $SfxSwitch
@onready var sfx_hurt: AudioStreamPlayer = $SfxHurt
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: RectangleShape2D = $CollisionShape2D.shape
@onready var hurt_shape: RectangleShape2D = $Hurtbox/CollisionShape2D.shape

var camera_offset: Vector2 = Vector2.ZERO

var mode_tween: Tween
var coins: int = 0

func _ready() -> void:
	_ensure_toggle_action()
	current_health = max_health
	_cache_hud()
	_update_health_ui()
	_update_coins_ui()
	if body_shape:
		base_body_size = body_shape.size
	if hurt_shape:
		base_hurt_size = hurt_shape.size
	_apply_mode(mode, false)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	camera_offset = camera.position
	_update_camera(true)

func _physics_process(delta: float) -> void:
	if not health_bar_bg or not health_bar_fill or not coins_label:
		_cache_hud()
	if Input.is_action_just_pressed("toggle_mode"):
		mode = PlayerMode.BIG if mode == PlayerMode.SMALL else PlayerMode.SMALL
		_apply_mode(mode, true)
		_play_sfx(sfx_switch)

	if damage_cooldown_timer > 0.0:
		damage_cooldown_timer -= delta
	if knockback_velocity != 0.0:
		knockback_velocity = move_toward(knockback_velocity, 0.0, knockback_decay * delta)

	var input_dir := Input.get_axis("ui_left", "ui_right")
	wall_normal = Vector2.ZERO
	var snapped := _try_wall_snap()
	var wall_sliding := _is_wall_sliding(snapped)
	var target_speed := input_dir * _current_speed()
	var accel := ground_accel if _is_grounded() else air_accel
	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	elif _is_grounded():
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
	elif air_brake > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, air_brake * delta)
	velocity.x += knockback_velocity

	if not is_on_floor():
		if wall_sliding:
			velocity.y = min(velocity.y + _current_gravity() * delta, wall_slide_speed)
		if Input.is_action_just_pressed("ui_accept") and (wall_sliding or snapped):
			_wall_jump()
			_play_sfx(sfx_jump)
		else:
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
	_update_facing(wall_sliding)
	_update_animation(wall_sliding)
	_update_camera()

func take_damage(amount: float) -> float:
	var final_amount := amount * damage_multiplier
	if damage_cooldown_timer > 0.0:
		return 0.0
	damage_cooldown_timer = damage_cooldown
	current_health = max(0, current_health - int(round(final_amount)))
	_update_health_ui()
	_spawn_floating_text("-%d" % int(round(final_amount)), Color(1, 0.2, 0.2), heart_icon)
	if current_health <= 0:
		get_tree().reload_current_scene()
	return final_amount

func _apply_mode(new_mode: PlayerMode, animate: bool) -> void:
	if new_mode == PlayerMode.SMALL:
		_set_mode_scale(small_scale, animate)
		damage_multiplier = 1.0
		_set_frames(small_frames)
		_apply_collision_scale(1.0)
	else:
		_set_mode_scale(big_scale, animate)
		damage_multiplier = big_damage_multiplier
		_set_frames(big_frames)
		_apply_collision_scale(3.0)

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
			_add_coins(100)
			_spawn_floating_text("+100", Color(1, 0.9, 0.2), coin_icon, area.global_position)
		velocity.y = stomp_bounce_velocity
		_play_sfx(sfx_stomp)
	else:
		_apply_knockback(area)
		_play_sfx(sfx_hurt)
		take_damage(enemy_contact_damage)

func _update_health_ui() -> void:
	if not health_bar_bg or not health_bar_fill:
		_cache_hud()
	if health_bar_bg and health_bar_fill:
		var ratio := 0.0
		if max_health > 0:
			ratio = clamp(float(current_health) / float(max_health), 0.0, 1.0)
		health_bar_fill.size.x = health_bar_bg.size.x * ratio
	else:
		print("HP: %d/%d" % [current_health, max_health])

func _add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	_update_coins_ui()

func _spawn_floating_text(text: String, color: Color, icon_tex: Texture2D, world_pos: Vector2 = Vector2.INF) -> void:
	if not floating_text_scene:
		return
	var fx := floating_text_scene.instantiate()
	get_tree().current_scene.add_child(fx)
	var spawn_pos := global_position if world_pos == Vector2.INF else world_pos
	spawn_pos.y -= 100.0
	fx.setup(text, color, icon_tex, spawn_pos)

func _update_coins_ui() -> void:
	if not coins_label:
		_cache_hud()
	if coins_label:
		coins_label.text = "%d" % coins

func _cache_hud() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if not hud and get_tree().current_scene:
		hud = get_tree().current_scene.get_node_or_null("HUD")
	if not hud:
		return
	health_bar_bg = hud.get_node_or_null("HealthBarBg")
	health_bar_fill = hud.get_node_or_null("HealthBarBg/HealthBarFill")
	coins_label = hud.get_node_or_null("CoinsLabel")

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
	knockback_velocity = clamp(player_force * dir, -max_knockback, max_knockback)
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

func _update_facing(wall_sliding: bool) -> void:
	if not sprite:
		return
	if wall_sliding and wall_normal != Vector2.ZERO:
		sprite.flip_h = wall_normal.x > 0.0
	elif absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x > 0.0
	if _is_grounded():
		sprite.flip_v = false
	else:
		sprite.flip_v = velocity.y > 0.0 and mode == PlayerMode.BIG

func _update_animation(wall_sliding: bool) -> void:
	if not sprite:
		return
	var next_anim := "idle"
	if _is_grounded():
		if absf(velocity.x) > 1.0:
			next_anim = "run"
	else:
		if wall_sliding:
			next_anim = "wall"
		else:
			next_anim = "jump" if velocity.y < 0.0 else "fall"
	if sprite.animation != next_anim:
		sprite.play(next_anim)

func _is_grounded() -> bool:
	return grounded_timer > 0.0

func _apply_collision_scale(multiplier: float) -> void:
	if not body_shape and not hurt_shape:
		return
	if body_shape:
		body_shape.size = base_body_size * multiplier
	if hurt_shape:
		hurt_shape.size = base_hurt_size * multiplier

func _is_wall_sliding(snapped: bool) -> bool:
	if mode != PlayerMode.SMALL:
		return false
	if _is_grounded():
		return false
	if not is_on_wall() and not snapped:
		return false
	if velocity.y < 0.0:
		return false
	if is_on_wall():
		wall_normal = get_wall_normal()
	return true

func _try_wall_snap() -> bool:
	if mode != PlayerMode.SMALL:
		return false
	if _is_grounded():
		return false
	if is_on_wall():
		wall_normal = get_wall_normal()
		return true
	if wall_snap_distance <= 0.0:
		return false
	if test_move(global_transform, Vector2(wall_snap_distance, 0.0)):
		wall_normal = Vector2(-1.0, 0.0)
		global_position.x += min(wall_snap_nudge, wall_snap_distance)
		return true
	elif test_move(global_transform, Vector2(-wall_snap_distance, 0.0)):
		wall_normal = Vector2(1.0, 0.0)
		global_position.x -= min(wall_snap_nudge, wall_snap_distance)
		return true
	return false

func _wall_jump() -> void:
	if wall_normal == Vector2.ZERO:
		if is_on_wall():
			wall_normal = get_wall_normal()
		elif wall_snap_distance > 0.0:
			if test_move(global_transform, Vector2(wall_snap_distance, 0.0)):
				wall_normal = Vector2(-1.0, 0.0)
			elif test_move(global_transform, Vector2(-wall_snap_distance, 0.0)):
				wall_normal = Vector2(1.0, 0.0)
	if wall_normal == Vector2.ZERO:
		return
	var away_dir := signf(wall_normal.x)
	wall_jump_timer = wall_jump_lock_time
	velocity.x = wall_jump_horizontal * away_dir
	velocity.y = wall_jump_vertical
	knockback_velocity = 0.0
