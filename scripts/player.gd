extends CharacterBody2D

enum PlayerMode {SMALL, BIG}
const ABILITY_SIZE_SHIFT := "size_shift"
const ABILITY_DOUBLE_JUMP := "double_jump"
const ABILITY_WALL_JUMP := "wall_jump"
const ABILITY_HEADBUTT := "headbutt"
const WEAPON_HEAD_SPIKE := "head_spike"
const AMULET_LEAP_OF_FAITH := "leap_of_faith"

@export var small_speed: float = 320.0
@export var small_gravity: float = 700.0
@export var small_scale: Vector2 = Vector2(0.7, 0.7)

@export var big_speed: float = 180.0
@export var big_gravity: float = 1800.0
@export var big_damage_multiplier: float = 0.6
@export var big_scale: Vector2 = Vector2(1.25, 1.25)
@export var small_frames: SpriteFrames
@export var big_frames: SpriteFrames

@export var small_jump_velocity: float = -550.0
@export var big_jump_velocity: float = -650.0
@export var squash_time: float = 0.12
@export var wall_slide_speed: float = 120.0
@export var wall_jump_vertical: float = -500.0
@export var wall_jump_horizontal: float = 750.0
@export var wall_jump_lock_time: float = 0.18
@export var headbutt_energy_cost: int = 12
@export var headbutt_duration: float = 0.16
@export var headbutt_dash_speed_small: float = 620.0
@export var headbutt_dash_speed_big: float = 780.0
@export var headbutt_knockback_small: float = 240.0
@export var headbutt_knockback_big: float = 360.0
@export var headbutt_damage_small: int = 1
@export var headbutt_damage_big_multiplier: float = 1.5
@export var variable_jump_hold_time: float = 0.16
@export var variable_jump_hold_gravity_scale: float = 0.45
@export var variable_jump_release_velocity_scale: float = 0.45
@export var wall_snap_distance: float = 6.0
@export var wall_snap_nudge: float = 1.5
@export var ground_friction: float = 1400.0
@export var air_accel: float = 2200.0
@export var air_brake: float = 0.0
@export var ground_accel: float = 3200.0
@export var midair_spin_speed: float = 5.0
@export var midair_spin_delay: float = 0.5
@export var flip_energy_reward: int = 5
@export var flip_reward_pickup_count_per_spin: int = 1
@export var flips_per_energy_reward: int = 5
@export var double_jump_energy_cost: int = 15
@export var wall_jump_energy_cost: int = 5
@export var death_anim_time: float = 0.4
@export var death_fade_time: float = 0.22
@export var xp_growth_multiplier: float = 1.25

var mode: PlayerMode = PlayerMode.SMALL
var damage_multiplier: float = 1.0
@export var max_health: int = 100
@export var max_energy: int = 100
@export var enemy_contact_damage: int = 20
@export var hazard_contact_damage: int = 20
@export var damage_cooldown: float = 1.1
@export var damage_input_lock_duration: float = 0.5
@export var big_mode_energy_cost: int = 10
@export var stomp_bounce_velocity: float = -520.0
@export var small_player_knockback: float = 160.0
@export var big_player_knockback: float = 100.0
@export var max_knockback: float = 500.0
@export var small_enemy_knockback: float = 120.0
@export var big_enemy_knockback: float = 220.0
@export var camera_smoothing_base_speed: float = 4.0
@export var size_shift_sfx_gain_db: float = 5.0
@export var run_sfx_interval_small: float = 0.16
@export var run_sfx_interval_big: float = 0.28
@export var run_sfx_volume_db_small: float = -14.0
@export var run_sfx_volume_db_big: float = -8.0
var current_health: int = max_health
var current_energy: int = max_energy
var damage_cooldown_timer: float = 0.0
@export var grounded_grace: float = 0.08
var grounded_timer: float = 0.0
@export var knockback_decay: float = 1200.0
var knockback_velocity: float = 0.0
var wall_normal: Vector2 = Vector2.ZERO
var air_time: float = 0.0
var spin_accumulated: float = 0.0
var spins_since_last_energy_reward: int = 0
var wall_jump_timer: float = 0.0
var base_body_size: Vector2 = Vector2.ZERO
var base_hurt_size: Vector2 = Vector2.ZERO
var base_body_collision_position: Vector2 = Vector2.ZERO
var base_hurtbox_position: Vector2 = Vector2.ZERO
var base_hurt_collision_position: Vector2 = Vector2.ZERO
var base_head_attachment_position: Vector2 = Vector2.ZERO
var base_head_attachment_sprite_position: Vector2 = Vector2.ZERO
var base_spike_hitbox_position: Vector2 = Vector2.ZERO
var base_spike_hitbox_shape_position: Vector2 = Vector2.ZERO
var input_lock_timer: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO
var wall_slide_sfx_timer: float = 0.0
var run_sfx_timer: float = 0.0
var is_killplane_respawning: bool = false
var extra_jumps_used: int = 0
var jump_hold_timer: float = 0.0
var is_headbutting: bool = false
var headbutt_timer: float = 0.0
var headbutt_dir: float = 1.0
var headbutt_hit_targets: Dictionary = {}
static var pending_coin_restore: bool = false
static var stored_coin_balance: int = 0
static var pending_fade_in: bool = false


var health_bar_bg: Control
var health_bar_fill: Control
var energy_bar_bg: Control
var energy_bar_fill: Control
var xp_bar_bg: Control
var xp_bar_fill: Control
var xp_level_label: Label
var left_panel: Panel
var right_panel: Panel
var coin_count_label: Label
var commentary_panel: Panel
var commentary_label: Label
var commentary_energy_item: Node2D
var consumable_panel: Panel
var consumable_left_button: Button
var consumable_right_button: Button
var consumable_health_item: Node2D
var consumable_energy_item: Node2D
var consumable_count_label: Label
var equipped_amulet_slot_1: TextureRect
var equipped_amulet_slot_2: TextureRect
var equipped_amulet_slot_3: TextureRect
var selected_consumable_key: String = "health"
var consumable_buttons_bound: bool = false
@onready var floating_text_scene: PackedScene = preload("res://scenes/ui/FloatingText.tscn")
@onready var item_pickup_scene: PackedScene = preload("res://scenes/items/ItemPickup.tscn")
@onready var coin_item_scene: PackedScene = preload("res://scenes/items/CoinItem.tscn")
@onready var health_item_scene: PackedScene = preload("res://scenes/items/HealthItem.tscn")
@onready var energy_item_scene: PackedScene = preload("res://scenes/items/EnergyItem.tscn")
@onready var hud_font: Font = preload("res://assets/fonts/gemunu-libre-v8-latin-700.ttf")
@onready var amulet_icon_leap_of_faith: Texture2D = preload("res://assets/ui/amulets/Leap_Of_Faith_Amulet.png")
@onready var hurtbox: Area2D = $Hurtbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var sfx_jump: AudioStreamPlayer = $SfxJump
@onready var sfx_stomp: AudioStreamPlayer = $SfxStomp
@onready var sfx_switch: AudioStreamPlayer = $SfxSwitch
@onready var sfx_hurt: AudioStreamPlayer = $SfxHurt
@onready var sfx_coin: AudioStreamPlayer = $SfxCoin
@onready var sfx_item_land: AudioStreamPlayer = $SfxItemLand
@onready var sfx_death: AudioStreamPlayer = $SfxDeath
@onready var sfx_land: AudioStreamPlayer = $SfxLand
@onready var sfx_wall_slide: AudioStreamPlayer = $SfxWallSlide
@onready var sfx_run: AudioStreamPlayer = $SfxRun
@onready var sfx_headbutt: AudioStreamPlayer = $SfxHeadbutt
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var head_attachment: Node2D = $AnimatedSprite2D/Head_Attachment
@onready var head_attachment_sprite: AnimatedSprite2D = $AnimatedSprite2D/Head_Attachment/AnimatedSprite2D
@onready var spike_hitbox: Area2D = $AnimatedSprite2D/Head_Attachment/SpikeHitbox
@onready var spike_hitbox_shape: CollisionShape2D = $AnimatedSprite2D/Head_Attachment/SpikeHitbox/CollisionShape2D
@onready var body_shape: RectangleShape2D = $CollisionShape2D.shape
@onready var hurt_shape: RectangleShape2D = $Hurtbox/CollisionShape2D.shape


var mode_tween: Tween
var coins: int = 0
var xp_level: int = 1
var xp_current: float = 0.0
var xp_to_next_level: float = 100.0
var is_dying: bool = false
var hud_flash_tween: Tween
var commentary_tween: Tween
var head_attachment_tween: Tween
var hud_base_modulates: Dictionary = {}
var base_max_health: int = 0

func _ready() -> void:
	_ensure_toggle_action()
	add_to_group("player")
	if pending_coin_restore:
		coins = stored_coin_balance
		pending_coin_restore = false
		_sync_coins_to_game_data()
	else:
		_pull_coins_from_game_data()
	current_health = max_health
	current_energy = max_energy
	base_max_health = max_health
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data and game_data.has_signal("inventory_changed"):
		if not game_data.inventory_changed.is_connected(_refresh_consumable_ui):
			game_data.inventory_changed.connect(_refresh_consumable_ui)
	if game_data and game_data.has_signal("amulets_changed"):
		if not game_data.amulets_changed.is_connected(_refresh_amulet_state):
			game_data.amulets_changed.connect(_refresh_amulet_state)
	if game_data and game_data.has_signal("abilities_changed"):
		if not game_data.abilities_changed.is_connected(_refresh_amulet_state):
			game_data.abilities_changed.connect(_refresh_amulet_state)
	if game_data and game_data.has_signal("weapons_changed"):
		if not game_data.weapons_changed.is_connected(_refresh_amulet_state):
			game_data.weapons_changed.connect(_refresh_amulet_state)
	_pull_xp_from_game_data()
	_cache_hud()
	_update_health_ui()
	_update_energy_ui()
	_update_xp_ui()
	_update_coins_ui()
	_refresh_consumable_ui()
	spawn_position = global_position
	_ensure_unique_collision_shapes()
	mode = PlayerMode.SMALL
	if sprite:
		sprite.rotation = 0.0
	if body_shape:
		base_body_size = body_shape.size
	if body_collision:
		base_body_collision_position = body_collision.position
	if hurt_shape:
		base_hurt_size = hurt_shape.size
	if hurtbox:
		base_hurtbox_position = hurtbox.position
		var hurt_collision := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if hurt_collision:
			base_hurt_collision_position = hurt_collision.position
	if head_attachment:
		base_head_attachment_position = head_attachment.position
	if head_attachment_sprite:
		base_head_attachment_sprite_position = head_attachment_sprite.position
	if spike_hitbox:
		base_spike_hitbox_position = spike_hitbox.position
		if not spike_hitbox.area_entered.is_connected(_on_spike_hitbox_area_entered):
			spike_hitbox.area_entered.connect(_on_spike_hitbox_area_entered)
	if spike_hitbox_shape:
		base_spike_hitbox_shape_position = spike_hitbox_shape.position
	_apply_mode(mode, false)
	var spike_allowed := _has_equipped_weapon(WEAPON_HEAD_SPIKE)
	_set_head_attachment_active(spike_allowed, false)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	# Camera now uses Godot's built-in offset and position_smoothing
	# No manual positioning needed
	if sprite:
		sprite.flip_h = true
	if camera:
		camera.enabled = true
		camera.make_current()
	if sfx_switch:
		sfx_switch.volume_db = size_shift_sfx_gain_db
	_refresh_amulet_state()
	_play_spawn_pop_tween()
	if pending_fade_in:
		pending_fade_in = false
		call_deferred("_fade_in_from_black")

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	if not health_bar_bg or not health_bar_fill or not energy_bar_bg or not energy_bar_fill or not xp_bar_bg or not xp_bar_fill or not xp_level_label:
		_cache_hud()
	if Input.is_action_just_pressed("toggle_mode"):
		if not _has_ability(ABILITY_SIZE_SHIFT):
			pass
		elif mode == PlayerMode.SMALL:
			if current_energy >= big_mode_energy_cost:
				current_energy = max(0, current_energy - big_mode_energy_cost)
				_update_energy_ui()
				mode = PlayerMode.BIG
				_apply_mode(mode, true)
				_play_sfx(sfx_switch)
		else:
			mode = PlayerMode.SMALL
			_apply_mode(mode, true)
			_play_sfx(sfx_switch)
	if Input.is_action_just_pressed("consumable_prev"):
		_cycle_consumable(-1)
	if Input.is_action_just_pressed("consumable_next"):
		_cycle_consumable(1)
	if Input.is_action_just_pressed("consumable_use"):
		_use_selected_consumable()
	if Input.is_action_just_pressed("headbutt") and input_lock_timer <= 0.0:
		_try_start_headbutt()
	if not _has_equipped_weapon(WEAPON_HEAD_SPIKE) and head_attachment and head_attachment.visible:
		_set_head_attachment_active(false, false)

	if input_lock_timer > 0.0:
		input_lock_timer -= delta
	if damage_cooldown_timer > 0.0:
		damage_cooldown_timer -= delta
	if wall_slide_sfx_timer > 0.0:
		wall_slide_sfx_timer -= delta
	if run_sfx_timer > 0.0:
		run_sfx_timer -= delta
	if knockback_velocity != 0.0:
		knockback_velocity = move_toward(knockback_velocity, 0.0, knockback_decay * delta)

	var input_dir := 0.0
	if input_lock_timer <= 0.0:
		input_dir = Input.get_axis("ui_left", "ui_right")
	wall_normal = Vector2.ZERO
	var snapped := _try_wall_snap()
	var wall_sliding := _is_wall_sliding(snapped)
	var should_spin := _should_spin_midair(snapped)
	var target_speed := input_dir * _current_speed()
	var accel := ground_accel if _is_grounded() else air_accel
	if is_headbutting:
		headbutt_timer = max(0.0, headbutt_timer - delta)
		velocity.x = _current_headbutt_speed() * headbutt_dir
		velocity.y = 0.0
		if sprite:
			sprite.rotation = _current_headbutt_rotation()
		if headbutt_timer <= 0.0:
			_end_headbutt()
	else:
		if input_dir != 0.0:
			velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		elif _is_grounded():
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
		elif air_brake > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, air_brake * delta)
	velocity.x += knockback_velocity

	var jump_pressed := Input.is_action_just_pressed("ui_accept") and input_lock_timer <= 0.0
	var jump_held := Input.is_action_pressed("ui_accept") and input_lock_timer <= 0.0
	var jump_released := Input.is_action_just_released("ui_accept")
	if is_headbutting:
		air_time = 0.0
		extra_jumps_used = 0
		jump_hold_timer = 0.0
	elif not is_on_floor():
		air_time += delta
		if wall_sliding or snapped:
			air_time = 0.0
		if wall_sliding:
			velocity.y = min(velocity.y + _current_gravity() * delta, wall_slide_speed)
		if jump_pressed and (wall_sliding or snapped):
			var wall_jump_cost := _current_wall_jump_energy_cost()
			if current_energy >= wall_jump_cost and _wall_jump():
				current_energy = max(0, current_energy - wall_jump_cost)
				_update_energy_ui()
				extra_jumps_used = 0
				_begin_variable_jump()
				_play_mode_switch_glow()
				_play_sfx(sfx_jump)
		elif jump_pressed and _can_double_jump():
			current_energy = max(0, current_energy - double_jump_energy_cost)
			_update_energy_ui()
			velocity.y = _current_jump_velocity()
			extra_jumps_used += 1
			_begin_variable_jump()
			_play_mode_switch_glow()
			_play_sfx(sfx_jump)
		else:
			velocity.y += _current_gravity() * delta
	else:
		air_time = 0.0
		extra_jumps_used = 0
		if jump_pressed:
			velocity.y = _current_jump_velocity()
			_begin_variable_jump()
			_play_sfx(sfx_jump)
		else:
			jump_hold_timer = 0.0

	if jump_released and velocity.y < 0.0:
		velocity.y *= clampf(variable_jump_release_velocity_scale, 0.0, 1.0)
		jump_hold_timer = 0.0
	elif jump_hold_timer > 0.0 and jump_held and velocity.y < 0.0:
		var hold_scale := clampf(variable_jump_hold_gravity_scale, 0.0, 1.0)
		var gravity_reduction := _current_gravity() * (1.0 - hold_scale) * delta
		velocity.y -= gravity_reduction
		jump_hold_timer = max(0.0, jump_hold_timer - delta)

	if should_spin and sprite and input_lock_timer <= 0.0:
		var spin_dir := signf(velocity.x)
		if spin_dir == 0.0:
			spin_dir = 1.0
		var spin_speed := midair_spin_speed
		if Input.get_axis("ui_left", "ui_right") != 0.0:
			spin_speed *= 2.5
		var delta_rot := spin_speed * delta * spin_dir
		sprite.rotation += delta_rot
		spin_accumulated += absf(delta_rot)
		if spin_accumulated >= TAU:
			var spins := int(floor(spin_accumulated / TAU))
			if spins > 0:
				spins_since_last_energy_reward += spins
				var reward_every := maxi(1, flips_per_energy_reward)
				var reward_batches: int = int(spins_since_last_energy_reward / reward_every)
				if reward_batches > 0:
					_spawn_flip_energy_pickups(reward_batches)
					_play_sfx(sfx_switch)
					_show_commentary_message("Nice Flips!", true)
					spins_since_last_energy_reward -= reward_batches * reward_every
				spin_accumulated -= spins * TAU
	else:
		_reset_sprite_rotation()

	var was_falling := velocity.y > 0.0
	var was_on_floor := is_on_floor()
	move_and_slide()
	if is_on_floor() and not was_on_floor and was_falling:
		_play_sfx(sfx_land)
	if is_on_floor():
		grounded_timer = grounded_grace
	else:
		grounded_timer = max(0.0, grounded_timer - delta)
	if wall_sliding and absf(velocity.y) > 10.0:
		if wall_slide_sfx_timer <= 0.0:
			_play_sfx(sfx_wall_slide)
			wall_slide_sfx_timer = 0.25
	else:
		wall_slide_sfx_timer = 0.0
	var moving_on_ground := is_on_floor() and absf(velocity.x) > 40.0 and not wall_sliding
	if moving_on_ground:
		if run_sfx_timer <= 0.0:
			if mode == PlayerMode.SMALL:
				sfx_run.volume_db = run_sfx_volume_db_small
				run_sfx_timer = run_sfx_interval_small
			else:
				sfx_run.volume_db = run_sfx_volume_db_big
				run_sfx_timer = run_sfx_interval_big
			_play_sfx(sfx_run)
	else:
		run_sfx_timer = 0.0
	_update_facing(wall_sliding)
	_update_animation(wall_sliding)
	
	# Visual feedback for damage/invulnerability
	if damage_cooldown_timer > 0.0:
		# Rapidly flicker between bright white and normal
		var flash_speed := 15.0
		if int(damage_cooldown_timer * flash_speed) % 2 == 0:
			sprite.modulate = Color(4, 4, 4, 1) # Bright white/glow
		else:
			sprite.modulate = Color(1, 1, 1, 1)
	else:
		sprite.modulate = Color(1, 1, 1, 1)
	
	# Adjust camera behavior
	if camera:
		# 1. Smoothing speed (Big mode fast fall needs faster tracking, otherwise use base)
		if mode == PlayerMode.BIG and velocity.y > 500.0:
			camera.position_smoothing_speed = 25.0
		else:
			camera.position_smoothing_speed = camera_smoothing_base_speed
			
	# Camera updates automatically via Godot's position_smoothing

func take_damage(amount: float) -> float:
	var final_amount := amount * damage_multiplier
	if damage_cooldown_timer > 0.0:
		return 0.0
	damage_cooldown_timer = damage_cooldown
	current_health = max(0, current_health - int(round(final_amount)))
	input_lock_timer = damage_input_lock_duration
	_update_health_ui()
	_flash_left_panel(Color(1.0, 0.56, 0.78, 1.0))
	if current_health <= 0 and not is_dying:
		call_deferred("_start_death_sequence")
	return final_amount

func _ensure_unique_collision_shapes() -> void:
	if body_collision and body_collision.shape:
		if not body_collision.shape.resource_local_to_scene:
			var body_shape_copy := body_collision.shape.duplicate(true)
			body_shape_copy.resource_local_to_scene = true
			body_collision.shape = body_shape_copy
		body_shape = body_collision.shape as RectangleShape2D
	if hurtbox:
		var hurt_collision := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if hurt_collision and hurt_collision.shape:
			if not hurt_collision.shape.resource_local_to_scene:
				var hurt_shape_copy := hurt_collision.shape.duplicate(true)
				hurt_shape_copy.resource_local_to_scene = true
				hurt_collision.shape = hurt_shape_copy
			hurt_shape = hurt_collision.shape as RectangleShape2D

func _apply_mode(new_mode: PlayerMode, animate: bool) -> void:
	_play_mode_switch_glow()
	if new_mode == PlayerMode.SMALL:
		_set_mode_scale(small_scale, animate)
		damage_multiplier = 1.0
		_set_frames(small_frames)
		_apply_collision_scale(1.0)
	else:
		_set_mode_scale(big_scale, animate)
		damage_multiplier = big_damage_multiplier
		_set_frames(big_frames)
		var collision_scale := big_scale.y / maxf(0.001, small_scale.y)
		_apply_collision_scale(collision_scale)

func _play_spawn_pop_tween() -> void:
	if not sprite:
		return
	var base_scale := sprite.scale
	var base_modulate := sprite.modulate
	sprite.scale = base_scale * 0.7
	sprite.modulate = Color(base_modulate.r, base_modulate.g, base_modulate.b, 0.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale * 1.15, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(sprite, "scale", base_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func respawn_from_kill_plane(damage_amount: int = 30) -> void:
	if is_dying or is_killplane_respawning:
		return
	is_killplane_respawning = true
	velocity = Vector2.ZERO
	knockback_velocity = 0.0
	var fade_rect := _ensure_fade_overlay(0.0)
	if fade_rect:
		var fade_out := create_tween()
		fade_out.tween_property(fade_rect, "color:a", 0.85, 0.08).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		await fade_out.finished
	global_position = spawn_position
	velocity = Vector2.ZERO
	knockback_velocity = 0.0
	grounded_timer = 0.0
	air_time = 0.0
	_reset_sprite_rotation()
	_play_spawn_pop_tween()
	if fade_rect:
		var fade_in := create_tween()
		fade_in.tween_property(fade_rect, "color:a", 0.0, 0.12).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		await fade_in.finished
		var fade_layer := fade_rect.get_parent()
		if fade_layer:
			fade_layer.queue_free()
	damage_cooldown_timer = 0.0
	take_damage(float(damage_amount))
	is_killplane_respawning = false

func _current_speed() -> float:
	return small_speed if mode == PlayerMode.SMALL else big_speed

func _current_gravity() -> float:
	return small_gravity if mode == PlayerMode.SMALL else big_gravity

func _current_jump_velocity() -> float:
	var base_jump := small_jump_velocity if mode == PlayerMode.SMALL else big_jump_velocity
	var jump_mult := 2.0 if _has_equipped_amulet(AMULET_LEAP_OF_FAITH) else 1.0
	return base_jump * jump_mult

func _begin_variable_jump() -> void:
	jump_hold_timer = max(0.0, variable_jump_hold_time)

func _ensure_toggle_action() -> void:
	_ensure_action_has_key("toggle_mode", KEY_Z)
	_ensure_action_has_key("consumable_prev", KEY_Q)
	_ensure_action_has_key("consumable_next", KEY_E)
	_ensure_action_has_key("consumable_use", KEY_W)
	_ensure_action_has_key("headbutt", KEY_C)

func _ensure_action_has_key(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event_variant in InputMap.action_get_events(action_name):
		var key_event := event_variant as InputEventKey
		if key_event and key_event.keycode == keycode:
			return
	var new_event := InputEventKey.new()
	new_event.keycode = keycode
	InputMap.action_add_event(action_name, new_event)

func _set_head_attachment_active(active: bool, animate: bool) -> void:
	if not head_attachment:
		return
	head_attachment.visible = active
	if spike_hitbox:
		spike_hitbox.monitoring = active
		spike_hitbox.monitorable = active
	if spike_hitbox_shape:
		spike_hitbox_shape.set_deferred("disabled", not active)
	if not head_attachment_sprite:
		return
	if head_attachment_tween and head_attachment_tween.is_running():
		head_attachment_tween.kill()
	if active:
		if animate:
			head_attachment_sprite.scale = Vector2(1.0, 0.0)
			head_attachment_tween = create_tween()
			head_attachment_tween.tween_property(head_attachment_sprite, "scale:y", 1.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			head_attachment_sprite.scale = Vector2.ONE
		if sprite:
			_sync_head_attachment_animation(String(sprite.animation))
	else:
		head_attachment_sprite.scale = Vector2.ONE

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dying:
		return

	if area.is_in_group("items"):
		if area.has_method("collect"):
			area.call("collect", self)
		elif area.get_parent().has_method("collect"):
			area.get_parent().call("collect", self)
		return

	if area.is_in_group("destroyable_platforms"):
		return

	if area.is_in_group("hazards"):
		var amount := hazard_contact_damage
		if area.has_method("get_damage_amount"):
			amount = int(area.call("get_damage_amount"))
		_apply_knockback(area)
		_play_sfx(sfx_hurt)
		take_damage(amount * _hazard_damage_multiplier_from_amulets())
		return

	if not area.is_in_group("enemies"):
		return
	_apply_knockback(area)
	_play_sfx(sfx_hurt)
	take_damage(enemy_contact_damage)

func _on_spike_hitbox_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if is_dying:
		return
	if not head_attachment or not head_attachment.visible:
		return
	if area.is_in_group("enemies"):
		if is_headbutting:
			_apply_headbutt_hit(area)
			return
		var enemy_node: Node = area
		if not enemy_node.has_method("die") and area.get_parent() and area.get_parent().has_method("die"):
			enemy_node = area.get_parent()
		if enemy_node and enemy_node.has_method("take_damage"):
			var kill_context: Dictionary = {
				"source": "head_spike",
				"player_mode": ("small" if mode == PlayerMode.SMALL else "big")
			}
			enemy_node.call("take_damage", 1.0, kill_context)
		elif enemy_node and enemy_node.has_method("die"):
			var kill_context_legacy: Dictionary = {
				"source": "head_spike",
				"player_mode": ("small" if mode == PlayerMode.SMALL else "big")
			}
			enemy_node.call_deferred("die", kill_context_legacy)
		velocity.y = stomp_bounce_velocity
		_play_sfx(sfx_stomp)
		return
	if area.is_in_group("destroyable_platforms"):
		var target := area.get_parent()
		if mode == PlayerMode.BIG and target and target.has_method("break_platform"):
			target.call_deferred("break_platform")
			velocity.y = stomp_bounce_velocity
			_play_sfx(sfx_stomp)

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

func _update_energy_ui() -> void:
	if not energy_bar_bg or not energy_bar_fill:
		_cache_hud()
	if energy_bar_bg and energy_bar_fill:
		var ratio := 0.0
		if max_energy > 0:
			ratio = clamp(float(current_energy) / float(max_energy), 0.0, 1.0)
		energy_bar_fill.size.x = energy_bar_bg.size.x * ratio
	else:
		print("Energy: %d/%d" % [current_energy, max_energy])

func _add_coins(amount: int, play_sound: bool = true) -> void:
	if amount <= 0:
		return
	coins += amount
	_sync_coins_to_game_data()
	_update_coins_ui()
	if play_sound:
		_play_sfx(sfx_coin)

func _spawn_floating_text(text: String, color: Color, icon_tex: Texture2D, world_pos: Vector2 = Vector2.INF, outline_color: Color = Color(0, 0, 0, 0), outline_size: int = 0) -> void:
	if not floating_text_scene:
		return
	var fx := floating_text_scene.instantiate()
	get_tree().current_scene.add_child(fx)
	var spawn_pos := global_position if world_pos == Vector2.INF else world_pos
	spawn_pos.y -= 50.0
	fx.override_font = hud_font
	fx.outline_color = outline_color
	fx.outline_size = max(8, outline_size)
	fx.setup(text, color, icon_tex, spawn_pos)

func _spawn_floating_text_with_item(
	text: String,
	color: Color,
	item_scene: PackedScene,
	world_pos: Vector2 = Vector2.INF,
	outline_color: Color = Color(0, 0, 0, 0),
	outline_size: int = 0,
	icon_scale: float = 1.0,
	hide_backings: bool = true
) -> void:
	if not floating_text_scene:
		return
	if not item_scene:
		_spawn_floating_text(text, color, null, world_pos, outline_color, outline_size)
		return
	var fx := floating_text_scene.instantiate()
	get_tree().current_scene.add_child(fx)
	var spawn_pos := global_position if world_pos == Vector2.INF else world_pos
	spawn_pos.y -= 50.0
	fx.override_font = hud_font
	fx.outline_color = outline_color
	fx.outline_size = max(8, outline_size)
	if fx.has_method("setup_with_item_scene"):
		fx.call("setup_with_item_scene", text, color, item_scene, spawn_pos, icon_scale, hide_backings)
	else:
		fx.call("setup", text, color, null, spawn_pos)

func _spawn_screen_text(text: String, color: Color, screen_offset: Vector2, relative_to_player: bool = false, outline_color: Color = Color(0, 0, 0, 0), outline_size: int = 0) -> void:
	if not floating_text_scene:
		return
	var fx := floating_text_scene.instantiate()
	var hud := get_tree().get_first_node_in_group("hud")
	var parent_node := hud if hud else get_tree().current_scene
	parent_node.add_child(fx)
	var screen_pos := screen_offset
	if relative_to_player:
		screen_pos = global_position + screen_offset
	else:
		var cam := camera if camera else get_viewport().get_camera_2d()
		if cam:
			screen_pos = cam.global_position + screen_offset
	fx.override_font = hud_font
	fx.outline_color = outline_color
	fx.outline_size = max(8, outline_size)
	fx.setup(text, color, null, screen_pos)

func add_health(amount: int) -> void:
	if amount <= 0:
		return
	var old_health := current_health
	current_health = min(max_health, current_health + amount)
	var gained := current_health - old_health
	if gained > 0:
		_update_health_ui()
		_flash_left_panel(Color(0.42, 1.0, 0.55, 1.0))

func add_energy(amount: int) -> void:
	if amount <= 0:
		return
	current_energy = min(max_energy, current_energy + amount)
	_update_energy_ui()
	_flash_left_panel(Color(0.52, 0.86, 1.0, 1.0))

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp_current += amount
	var leveled_up := false
	while xp_current >= xp_to_next_level:
		xp_current -= xp_to_next_level
		xp_level += 1
		xp_to_next_level = ceil(xp_to_next_level * xp_growth_multiplier)
		leveled_up = true
	_update_xp_ui()
	_sync_xp_to_game_data()
	if leveled_up:
		_spawn_screen_text("LEVEL UP!", Color(1.0, 0.95, 0.35), Vector2(-52.0, -100.0), true, Color(0.35, 0.25, 0.0), 3)

func on_item_picked(type: int, value: int) -> void:
	match type:
		0: # HEALTH
			pass
		1: # ENERGY
			pass
		2: # COIN
			pass

func on_energy_item_landed(value: int) -> void:
	var gain := value if value > 1 else (value * 25)
	add_energy(gain)
	_play_sfx(sfx_item_land)

func on_health_item_landed(value: int) -> void:
	add_health(value * 20)
	_play_sfx(sfx_item_land)

func on_coin_item_landed(value: int) -> void:
	_add_coins(value, true)
	_play_sfx(sfx_item_land)
	_flash_right_panel(Color(0.98039216, 0.972549, 0.6745098, 1.0))

func can_collect_item(type: int) -> bool:
	match type:
		0: # HEALTH
			return current_health < max_health
		1: # ENERGY
			return current_energy < max_energy
		_:
			return true

func _spawn_flip_energy_pickups(spins: int) -> void:
	if not item_pickup_scene:
		return
	var drops_to_spawn: int = int(max(1, spins * max(1, flip_reward_pickup_count_per_spin)))
	var root := get_tree().current_scene
	if not root:
		return
	var spawn_origin := _get_flip_reward_spawn_world_pos()
	for i in range(drops_to_spawn):
		var item := item_pickup_scene.instantiate()
		item.type = 1 # ItemType.ENERGY
		item.value = flip_energy_reward
		root.add_child(item)
		var x_offset := randf_range(-10.0, 10.0) + float(i - drops_to_spawn / 2) * 14.0
		item.global_position = spawn_origin + Vector2(x_offset, randf_range(-4.0, 4.0))
		if item is CharacterBody2D:
			var body := item as CharacterBody2D
			body.velocity = Vector2(randf_range(-70.0, 70.0), randf_range(20.0, 90.0))

func _get_flip_reward_spawn_world_pos() -> Vector2:
	var viewport := get_viewport()
	var rect := viewport.get_visible_rect()
	var screen_pos := Vector2(rect.size.x * 0.5, 54.0)
	return viewport.get_canvas_transform().affine_inverse() * screen_pos

func _play_mode_switch_glow() -> void:
	if not energy_item_scene:
		return
	var root := get_tree().current_scene
	if root == null:
		return
	var fx := energy_item_scene.instantiate() as Node2D
	if fx == null:
		return
	root.add_child(fx)
	fx.global_position = sprite.global_position if sprite else global_position
	var icon := fx.get_node_or_null("EnergyIcon") as CanvasItem
	var outline := fx.get_node_or_null("EnergyIconOutline") as CanvasItem
	if icon:
		icon.visible = false
	if outline:
		outline.visible = false
	var backing := fx.get_node_or_null("EnergyIconBacking") as Sprite2D
	if backing == null:
		fx.queue_free()
		return
	var base_scale := backing.scale
	backing.modulate = Color(0.62, 0.85, 1.0, 0.9)
	backing.scale = base_scale * 0.75
	var tween := create_tween().set_parallel(true)
	tween.tween_property(backing, "scale", base_scale * 4.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(backing, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	fx.queue_free()

func _show_commentary_message(text: String, show_energy_icon: bool) -> void:
	if not commentary_panel or not commentary_label:
		_cache_hud()
	if not commentary_panel or not commentary_label:
		return
	if commentary_tween and commentary_tween.is_running():
		commentary_tween.kill()
	commentary_label.text = text
	if commentary_energy_item:
		commentary_energy_item.visible = show_energy_icon
	commentary_panel.visible = true
	commentary_panel.modulate.a = 0.0
	commentary_panel.scale = Vector2(0.92, 0.92)
	commentary_tween = create_tween()
	commentary_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	commentary_tween.tween_property(commentary_panel, "modulate:a", 1.0, 0.16)
	commentary_tween.parallel().tween_property(commentary_panel, "scale", Vector2.ONE, 0.16)
	commentary_tween.tween_interval(2.0)
	commentary_tween.tween_property(commentary_panel, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	commentary_tween.parallel().tween_property(commentary_panel, "scale", Vector2(0.92, 0.92), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	commentary_tween.tween_callback(func() -> void:
		commentary_panel.visible = false
	)

func on_xp_item_landed(value: int) -> void:
	add_xp(value)
	_play_sfx(sfx_item_land)
	_flash_right_panel(Color(0.7490196, 0.18431373, 0.6862745, 1.0))

func _cache_hud() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if not hud and get_tree().current_scene:
		hud = get_tree().current_scene.get_node_or_null("HUD")
	if not hud:
		return
	health_bar_bg = hud.get_node_or_null("HealthBarBg")
	health_bar_fill = hud.get_node_or_null("HealthBarBg/HealthBarFill")
	energy_bar_bg = hud.get_node_or_null("EnergyBarBg")
	energy_bar_fill = hud.get_node_or_null("EnergyBarBg/EnergyBarFill")
	xp_bar_bg = hud.get_node_or_null("XpBarBg")
	xp_bar_fill = hud.get_node_or_null("XpBarBg/XpBarFill")
	xp_level_label = hud.get_node_or_null("XpItem/XpLevelLabel")
	left_panel = hud.get_node_or_null("LeftPanel")
	right_panel = hud.get_node_or_null("RightPanel")
	coin_count_label = hud.get_node_or_null("CoinCountLabel")
	commentary_panel = hud.get_node_or_null("CommentaryPanel")
	commentary_label = hud.get_node_or_null("CommentaryPanel/CommentaryLabel")
	commentary_energy_item = hud.get_node_or_null("CommentaryPanel/CommentaryEnergyItem") as Node2D
	consumable_panel = hud.get_node_or_null("ConsumablePanel")
	consumable_left_button = hud.get_node_or_null("ConsumablePanel/ConsumableLeftButton")
	consumable_right_button = hud.get_node_or_null("ConsumablePanel/ConsumableRightButton")
	consumable_health_item = hud.get_node_or_null("ConsumablePanel/ConsumableHealthItem") as Node2D
	consumable_energy_item = hud.get_node_or_null("ConsumablePanel/ConsumableEnergyItem") as Node2D
	consumable_count_label = hud.get_node_or_null("ConsumablePanel/ConsumableCountLabel")
	equipped_amulet_slot_1 = hud.get_node_or_null("EquippedAmuletsPanel/AmuletSlot1") as TextureRect
	equipped_amulet_slot_2 = hud.get_node_or_null("EquippedAmuletsPanel/AmuletSlot2") as TextureRect
	equipped_amulet_slot_3 = hud.get_node_or_null("EquippedAmuletsPanel/AmuletSlot3") as TextureRect
	var health_backing := hud.get_node_or_null("HealthItem/HealthIconBacking") as CanvasItem
	var energy_backing := hud.get_node_or_null("EnergyItem/EnergyIconBacking") as CanvasItem
	var xp_backing := hud.get_node_or_null("XpItem/XpIconBacking") as CanvasItem
	var coin_backing := hud.get_node_or_null("CoinItem/CoinIconBacking") as CanvasItem
	var commentary_energy_backing := hud.get_node_or_null("CommentaryPanel/CommentaryEnergyItem/EnergyIconBacking") as CanvasItem
	var consumable_health_backing := hud.get_node_or_null("ConsumablePanel/ConsumableHealthItem/HealthIconBacking") as CanvasItem
	var consumable_energy_backing := hud.get_node_or_null("ConsumablePanel/ConsumableEnergyItem/EnergyIconBacking") as CanvasItem
	if health_backing:
		health_backing.visible = false
	if energy_backing:
		energy_backing.visible = false
	if xp_backing:
		xp_backing.visible = false
	if coin_backing:
		coin_backing.visible = false
	if commentary_energy_backing:
		commentary_energy_backing.visible = false
	if consumable_health_backing:
		consumable_health_backing.visible = false
	if consumable_energy_backing:
		consumable_energy_backing.visible = false
	_bind_consumable_buttons()
	_refresh_consumable_ui()
	if commentary_panel and not commentary_panel.visible:
		commentary_panel.modulate.a = 0.0
	for node in [
		left_panel, right_panel,
		health_bar_bg, health_bar_fill,
		energy_bar_bg, energy_bar_fill,
		xp_bar_bg, xp_bar_fill,
		consumable_panel
	]:
		if node is CanvasItem:
			_register_hud_base_modulate(node as CanvasItem)
	_update_equipped_amulet_icons()

func _bind_consumable_buttons() -> void:
	if consumable_buttons_bound:
		return
	if consumable_left_button and not consumable_left_button.pressed.is_connected(_on_consumable_left_pressed):
		consumable_left_button.pressed.connect(_on_consumable_left_pressed)
	if consumable_right_button and not consumable_right_button.pressed.is_connected(_on_consumable_right_pressed):
		consumable_right_button.pressed.connect(_on_consumable_right_pressed)
	consumable_buttons_bound = true

func _on_consumable_left_pressed() -> void:
	_cycle_consumable(-1)

func _on_consumable_right_pressed() -> void:
	_cycle_consumable(1)

func _cycle_consumable(direction: int) -> void:
	var available := _get_available_consumables()
	if available.is_empty():
		_refresh_consumable_ui()
		return
	var current_index := available.find(selected_consumable_key)
	if current_index == -1:
		current_index = 0
	var next_index := int(posmod(current_index + direction, available.size()))
	selected_consumable_key = String(available[next_index])
	_refresh_consumable_ui()

func _get_available_consumables() -> Array[String]:
	var available: Array[String] = []
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return available
	for key in ["health", "energy"]:
		var count: int = int(game_data.call("get_inventory_count", key))
		if count > 0:
			available.append(key)
	return available

func _refresh_consumable_ui() -> void:
	if not consumable_panel:
		return
	var available := _get_available_consumables()
	consumable_panel.visible = not available.is_empty()
	if available.is_empty():
		return
	if not available.has(selected_consumable_key):
		selected_consumable_key = "health" if available.has("health") else String(available[0])
	var game_data: Node = get_node_or_null("/root/GameData")
	var count := 0
	if game_data:
		count = int(game_data.call("get_inventory_count", selected_consumable_key))
	if consumable_count_label:
		consumable_count_label.text = "%d" % count
	if consumable_health_item:
		consumable_health_item.visible = selected_consumable_key == "health"
	if consumable_energy_item:
		consumable_energy_item.visible = selected_consumable_key == "energy"
	if consumable_left_button:
		consumable_left_button.visible = available.size() > 1
	if consumable_right_button:
		consumable_right_button.visible = available.size() > 1

func _use_selected_consumable() -> void:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return
	var key := selected_consumable_key
	if key == "health":
		if current_health >= max_health:
			return
	elif key == "energy":
		if current_energy >= max_energy:
			return
	else:
		return
	var consumed: bool = bool(game_data.call("consume_consumable", key, 1))
	if not consumed:
		_refresh_consumable_ui()
		return
	if key == "health":
		current_health = min(max_health, current_health + 25)
		_update_health_ui()
		_flash_left_panel(Color(0.11372549, 0.7019608, 0.48235294, 1.0))
	else:
		current_energy = min(max_energy, current_energy + 25)
		_update_energy_ui()
		_flash_left_panel(Color(0.52, 0.86, 1.0, 1.0))
	_play_sfx(sfx_item_land)
	_refresh_consumable_ui()

func _set_mode_scale(target_scale: Vector2, animate: bool) -> void:
	if not sprite:
		return
	if not animate:
		sprite.scale = target_scale
		return
	if mode_tween and mode_tween.is_running():
		mode_tween.kill()
	var squash := Vector2(target_scale.x * 1.2, target_scale.y * 0.8)
	sprite.scale = squash
	mode_tween = create_tween()
	mode_tween.tween_property(sprite, "scale", target_scale, squash_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.play()

func _flash_hud_nodes(nodes: Array, flash_color: Color) -> void:
	var targets: Array[CanvasItem] = []
	for node in nodes:
		if node is CanvasItem:
			var target := node as CanvasItem
			targets.append(target)
			_register_hud_base_modulate(target)
	if targets.is_empty():
		return
	if hud_flash_tween and hud_flash_tween.is_running():
		hud_flash_tween.kill()
		_reset_hud_flash_modulates()
	hud_flash_tween = create_tween().set_parallel(true)
	for target in targets:
		var base: Color = hud_base_modulates.get(target, target.modulate)
		target.modulate = base.lerp(flash_color, 0.8)
		hud_flash_tween.tween_property(target, "modulate", base, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hud_flash_tween.tween_callback(_reset_hud_flash_modulates)

func _register_hud_base_modulate(target: CanvasItem) -> void:
	if not target:
		return
	if not hud_base_modulates.has(target):
		hud_base_modulates[target] = target.modulate

func _reset_hud_flash_modulates() -> void:
	var stale: Array = []
	for target in hud_base_modulates.keys():
		if not is_instance_valid(target):
			stale.append(target)
			continue
		(target as CanvasItem).modulate = hud_base_modulates[target]
	for key in stale:
		hud_base_modulates.erase(key)

func _flash_left_panel(color: Color) -> void:
	if not left_panel:
		_cache_hud()
	if left_panel:
		_flash_hud_nodes([left_panel], color)

func _flash_right_panel(color: Color) -> void:
	if not right_panel:
		_cache_hud()
	if right_panel:
		_flash_hud_nodes([right_panel], color)

func _update_xp_ui() -> void:
	if not xp_bar_bg or not xp_bar_fill or not xp_level_label:
		_cache_hud()
	if xp_bar_bg and xp_bar_fill:
		var ratio := 0.0
		if xp_to_next_level > 0.0:
			ratio = clamp(xp_current / xp_to_next_level, 0.0, 1.0)
		xp_bar_fill.size.x = xp_bar_bg.size.x * ratio
	if xp_level_label:
		xp_level_label.text = "%d" % xp_level

func _update_coins_ui() -> void:
	if not coin_count_label:
		_cache_hud()
	if coin_count_label:
		coin_count_label.text = "%d" % coins

func _pull_coins_from_game_data() -> void:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return
	if game_data.has_method("get_balance"):
		coins = int(game_data.call("get_balance", "coins"))

func _pull_xp_from_game_data() -> void:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return
	if game_data.has_method("get_xp_state"):
		var state: Dictionary = game_data.call("get_xp_state")
		xp_level = max(1, int(state.get("xp_level", xp_level)))
		xp_to_next_level = maxf(1.0, float(state.get("xp_to_next_level", xp_to_next_level)))
		xp_current = clampf(float(state.get("xp_current", xp_current)), 0.0, xp_to_next_level)

func _sync_coins_to_game_data() -> void:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return
	if game_data.has_method("add_currency"):
		var current: int = int(game_data.call("get_balance", "coins"))
		var delta := coins - current
		if delta != 0:
			game_data.call("add_currency", "coins", delta)

func _sync_xp_to_game_data() -> void:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return
	if game_data.has_method("set_xp_state"):
		game_data.call("set_xp_state", xp_level, xp_current, xp_to_next_level)

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
	_sync_head_attachment_animation(String(sprite.animation))

func _apply_knockback(enemy_area: Area2D) -> void:
	# Reset all existing velocities/forces first
	velocity = Vector2.ZERO
	knockback_velocity = 0.0
	
	var dir := signf(global_position.x - enemy_area.global_position.x)
	if dir == 0.0:
		dir = -1.0
	var enemy_knockback_mult := 1.0
	if enemy_area and enemy_area.has_method("get_player_knockback_multiplier"):
		enemy_knockback_mult = maxf(0.0, float(enemy_area.call("get_player_knockback_multiplier")))
	var player_force := (small_player_knockback if mode == PlayerMode.SMALL else big_player_knockback) * 0.5 * enemy_knockback_mult
	knockback_velocity = clamp(player_force * dir, -max_knockback, max_knockback)
	velocity.y = -300.0 # Significant upward bounce

	var enemy_force := small_enemy_knockback if mode == PlayerMode.SMALL else big_enemy_knockback
	# Enemy knockback disabled for now.

func _update_camera(force: bool = false) -> void:
	# Camera now handled automatically by Godot's position_smoothing
	# No manual positioning needed
	pass

func _update_facing(wall_sliding: bool) -> void:
	if not sprite:
		return
	if is_headbutting:
		_update_head_attachment_transform()
		return
	if wall_sliding and wall_normal != Vector2.ZERO:
		sprite.flip_h = wall_normal.x > 0.0
	elif absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x > 0.0
	if _is_grounded():
		sprite.flip_v = false
	else:
		sprite.flip_v = velocity.y > 0.0 and mode == PlayerMode.BIG
	_update_head_attachment_transform()

func _update_head_attachment_transform() -> void:
	if not sprite:
		return
	if head_attachment_sprite:
		head_attachment_sprite.flip_h = sprite.flip_h
		head_attachment_sprite.flip_v = sprite.flip_v
	if head_attachment:
		var target_pos := base_head_attachment_position
		if sprite.flip_v:
			target_pos.y = absf(base_head_attachment_position.y)
		head_attachment.position = target_pos
	if head_attachment_sprite:
		var sprite_target_pos := base_head_attachment_sprite_position
		if sprite.flip_v:
			sprite_target_pos.y = absf(base_head_attachment_sprite_position.y)
		head_attachment_sprite.position = sprite_target_pos
	if spike_hitbox:
		var hitbox_target_pos := base_spike_hitbox_position
		if sprite.flip_h:
			hitbox_target_pos.x = -base_spike_hitbox_position.x
		if sprite.flip_v:
			hitbox_target_pos.y = absf(base_spike_hitbox_position.y)
		spike_hitbox.position = hitbox_target_pos
	if spike_hitbox_shape:
		var shape_target_pos := base_spike_hitbox_shape_position
		if sprite.flip_v:
			shape_target_pos.y = absf(base_spike_hitbox_shape_position.y)
		spike_hitbox_shape.position = shape_target_pos

func _update_animation(wall_sliding: bool) -> void:
	if not sprite:
		return
	if is_dying:
		return
	sprite.visible = true
	var next_anim := "idle"
	if _is_grounded():
		if absf(velocity.x) > 1.0:
			next_anim = "run"
	else:
		if wall_sliding:
			var use_wall := false
			if sprite.sprite_frames and sprite.sprite_frames.has_animation("wall") and sprite.sprite_frames.get_frame_count("wall") > 0:
				var tex := sprite.sprite_frames.get_frame_texture("wall", 0)
				use_wall = tex != null
			next_anim = "wall" if use_wall else "fall"
		else:
			next_anim = "jump" if velocity.y < 0.0 else "fall"
	if sprite.animation != next_anim:
		sprite.play(next_anim)
	_sync_head_attachment_animation(next_anim)

func _sync_head_attachment_animation(anim_name: String) -> void:
	if not head_attachment_sprite:
		return
	if head_attachment_sprite.sprite_frames == null:
		return
	if head_attachment_sprite.sprite_frames.has_animation(anim_name):
		if head_attachment_sprite.animation != anim_name or not head_attachment_sprite.is_playing():
			head_attachment_sprite.play(anim_name)
		return
	if head_attachment_sprite.sprite_frames.has_animation("idle"):
		if head_attachment_sprite.animation != "idle" or not head_attachment_sprite.is_playing():
			head_attachment_sprite.play("idle")

func _should_spin_midair(snapped: bool) -> bool:
	if mode != PlayerMode.SMALL:
		return false
	if _is_grounded():
		return false
	if air_time < midair_spin_delay:
		return false
	if snapped:
		return false
	if is_on_wall():
		return false
	return true

func _reset_sprite_rotation() -> void:
	if not sprite:
		return
	if is_headbutting:
		return
	if absf(sprite.rotation) > 0.001:
		sprite.rotation = 0.0
	spin_accumulated = 0.0

func _is_grounded() -> bool:
	return grounded_timer > 0.0

func _has_equipped_amulet(amulet_id: String) -> bool:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return false
	if game_data.has_method("is_amulet_equipped"):
		return bool(game_data.call("is_amulet_equipped", amulet_id))
	return false

func _has_ability(ability_id: String) -> bool:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return false
	if game_data.has_method("has_ability"):
		return bool(game_data.call("has_ability", ability_id))
	return false

func _has_equipped_weapon(weapon_id: String) -> bool:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return false
	if game_data.has_method("is_weapon_equipped"):
		return bool(game_data.call("is_weapon_equipped", weapon_id))
	return false

func _can_double_jump() -> bool:
	if _is_grounded():
		return false
	if not _has_ability(ABILITY_DOUBLE_JUMP):
		return false
	if current_energy < double_jump_energy_cost:
		return false
	return extra_jumps_used < 1

func _hazard_damage_multiplier_from_amulets() -> float:
	return 1.2 if _has_equipped_amulet(AMULET_LEAP_OF_FAITH) else 1.0

func _refresh_amulet_state() -> void:
	var size_shift_owned := _has_ability(ABILITY_SIZE_SHIFT)
	var head_spike_equipped := _has_equipped_weapon(WEAPON_HEAD_SPIKE)
	if not _has_ability(ABILITY_HEADBUTT) or not head_spike_equipped:
		_end_headbutt()
	if not size_shift_owned and mode == PlayerMode.BIG:
		mode = PlayerMode.SMALL
		_apply_mode(mode, false)
		_reset_sprite_rotation()
	extra_jumps_used = 0
	max_health = base_max_health
	current_health = min(current_health, max_health)
	_update_health_ui()
	_set_head_attachment_active(head_spike_equipped, false)
	_update_equipped_amulet_icons()

func validate_ability_state_from_amulets() -> void:
	_refresh_amulet_state()

func _update_equipped_amulet_icons() -> void:
	if not equipped_amulet_slot_1 or not equipped_amulet_slot_2 or not equipped_amulet_slot_3:
		return
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null:
		return
	var equipped: Array = []
	if game_data.has_method("get_equipped_amulets"):
		equipped = game_data.call("get_equipped_amulets")
	var id_1 := String(equipped[0]) if equipped.size() > 0 else ""
	var id_2 := String(equipped[1]) if equipped.size() > 1 else ""
	var id_3 := String(equipped[2]) if equipped.size() > 2 else ""
	equipped_amulet_slot_1.texture = _get_amulet_icon_texture(id_1)
	equipped_amulet_slot_1.visible = id_1 != ""
	equipped_amulet_slot_2.texture = _get_amulet_icon_texture(id_2)
	equipped_amulet_slot_2.visible = id_2 != ""
	equipped_amulet_slot_3.texture = _get_amulet_icon_texture(id_3)
	equipped_amulet_slot_3.visible = id_3 != ""

func _get_amulet_icon_texture(amulet_id: String) -> Texture2D:
	match amulet_id:
		AMULET_LEAP_OF_FAITH:
			return amulet_icon_leap_of_faith
		_:
			return null

func _apply_collision_scale(multiplier: float) -> void:
	if not body_shape and not hurt_shape:
		return
	if body_shape:
		body_shape.size = base_body_size * multiplier
	if body_collision:
		body_collision.position = base_body_collision_position * multiplier
	if hurt_shape:
		hurt_shape.size = base_hurt_size * multiplier
	if hurtbox:
		hurtbox.position = base_hurtbox_position * multiplier
		var hurt_collision := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if hurt_collision:
			hurt_collision.position = base_hurt_collision_position * multiplier

func _is_wall_sliding(snapped: bool) -> bool:
	if not _has_ability(ABILITY_WALL_JUMP):
		return false
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
	if not _has_ability(ABILITY_WALL_JUMP):
		return false
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

func _wall_jump() -> bool:
	if not _has_ability(ABILITY_WALL_JUMP):
		return false
	if wall_normal == Vector2.ZERO:
		if is_on_wall():
			wall_normal = get_wall_normal()
		elif wall_snap_distance > 0.0:
			if test_move(global_transform, Vector2(wall_snap_distance, 0.0)):
				wall_normal = Vector2(-1.0, 0.0)
			elif test_move(global_transform, Vector2(-wall_snap_distance, 0.0)):
				wall_normal = Vector2(1.0, 0.0)
	if wall_normal == Vector2.ZERO:
		return false
	var away_dir := signf(wall_normal.x)
	wall_jump_timer = wall_jump_lock_time
	velocity.x = wall_jump_horizontal * away_dir
	velocity.y = wall_jump_vertical
	knockback_velocity = 0.0
	return true

func _current_wall_jump_energy_cost() -> int:
	return maxi(1, int(floor(float(wall_jump_energy_cost) * 0.5)))

func _try_start_headbutt() -> void:
	if is_dying or is_headbutting:
		return
	if not _has_ability(ABILITY_HEADBUTT):
		return
	if not _has_equipped_weapon(WEAPON_HEAD_SPIKE):
		return
	if current_energy < headbutt_energy_cost:
		return
	current_energy = max(0, current_energy - headbutt_energy_cost)
	_update_energy_ui()
	is_headbutting = true
	headbutt_timer = max(0.05, headbutt_duration)
	headbutt_hit_targets.clear()
	knockback_velocity = 0.0
	var facing_sign := 1.0 if sprite and sprite.flip_h else -1.0
	if absf(velocity.x) > 1.0:
		facing_sign = signf(velocity.x)
	headbutt_dir = facing_sign
	velocity.x = _current_headbutt_speed() * headbutt_dir
	velocity.y = 0.0
	if sfx_headbutt and sfx_headbutt.stream:
		sfx_headbutt.stop()
		sfx_headbutt.play()
	if sprite:
		sprite.rotation = _current_headbutt_rotation()

func _end_headbutt() -> void:
	if not is_headbutting:
		return
	is_headbutting = false
	headbutt_timer = 0.0
	headbutt_hit_targets.clear()
	_reset_sprite_rotation()

func _current_headbutt_speed() -> float:
	return headbutt_dash_speed_small if mode == PlayerMode.SMALL else headbutt_dash_speed_big

func _current_headbutt_rotation() -> float:
	return PI * 0.5 if headbutt_dir >= 0.0 else PI * 1.5

func _apply_headbutt_hit(area: Area2D) -> void:
	if area == null:
		return
	var enemy_node: Node = area
	if not enemy_node.has_method("die") and area.get_parent() and area.get_parent().has_method("die"):
		enemy_node = area.get_parent()
	if enemy_node == null:
		return
	var enemy_key := enemy_node.get_instance_id()
	if headbutt_hit_targets.has(enemy_key):
		return
	headbutt_hit_targets[enemy_key] = true
	var knockback_force := headbutt_knockback_small if mode == PlayerMode.SMALL else headbutt_knockback_big
	if enemy_node.has_method("apply_knockback"):
		enemy_node.call("apply_knockback", knockback_force, headbutt_dir)
	var damage_value := float(headbutt_damage_small)
	if mode == PlayerMode.BIG:
		damage_value *= headbutt_damage_big_multiplier
	if enemy_node.has_method("take_damage"):
		enemy_node.call("take_damage", damage_value, {
			"source": "headbutt",
			"player_mode": ("small" if mode == PlayerMode.SMALL else "big"),
			"damage": damage_value
		})
	elif enemy_node.has_method("die"):
		var kill_context: Dictionary = {
			"source": "headbutt",
			"player_mode": ("small" if mode == PlayerMode.SMALL else "big"),
			"damage": damage_value
		}
		enemy_node.call_deferred("die", kill_context)

func _start_death_sequence() -> void:
	if is_dying:
		return
	is_dying = true
	input_lock_timer = 999.0
	velocity = Vector2.ZERO
	knockback_velocity = 0.0
	damage_cooldown_timer = 0.0
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if body_collision:
		body_collision.set_deferred("disabled", true)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
	if sprite:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("hurt"):
			sprite.play("hurt")
			_sync_head_attachment_animation("hurt")
		var death_tween := create_tween().set_parallel(true)
		death_tween.tween_property(sprite, "rotation", sprite.rotation + deg_to_rad(200.0), death_anim_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		death_tween.tween_property(sprite, "scale", sprite.scale * 0.7, death_anim_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		death_tween.tween_property(sprite, "modulate", Color(1.4, 0.35, 0.35, 0.2), death_anim_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_play_sfx(sfx_death)
	await get_tree().create_timer(death_anim_time).timeout
	var fade_rect := _ensure_fade_overlay(0.0)
	if fade_rect:
		var fade_tween := create_tween()
		fade_tween.tween_property(fade_rect, "color:a", 1.0, death_fade_time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		await fade_tween.finished
	stored_coin_balance = coins
	pending_coin_restore = true
	pending_fade_in = true
	get_tree().reload_current_scene()

func _ensure_fade_overlay(initial_alpha: float) -> ColorRect:
	var scene := get_tree().current_scene
	if not scene:
		return null
	var fade_layer := scene.get_node_or_null("__DeathFadeLayer") as CanvasLayer
	if fade_layer == null:
		fade_layer = CanvasLayer.new()
		fade_layer.name = "__DeathFadeLayer"
		fade_layer.layer = 100
		scene.add_child(fade_layer)
	var fade_rect := fade_layer.get_node_or_null("FadeRect") as ColorRect
	if fade_rect == null:
		fade_rect = ColorRect.new()
		fade_rect.name = "FadeRect"
		fade_rect.anchor_left = 0.0
		fade_rect.anchor_top = 0.0
		fade_rect.anchor_right = 1.0
		fade_rect.anchor_bottom = 1.0
		fade_rect.offset_left = 0.0
		fade_rect.offset_top = 0.0
		fade_rect.offset_right = 0.0
		fade_rect.offset_bottom = 0.0
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade_layer.add_child(fade_rect)
	fade_rect.color = Color(0, 0, 0, clamp(initial_alpha, 0.0, 1.0))
	return fade_rect

func _fade_in_from_black() -> void:
	await get_tree().process_frame
	var fade_rect := _ensure_fade_overlay(1.0)
	if not fade_rect:
		return
	var fade_tween := create_tween()
	fade_tween.tween_property(fade_rect, "color:a", 0.0, death_fade_time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	await fade_tween.finished
	var fade_layer := fade_rect.get_parent()
	if fade_layer:
		fade_layer.queue_free()
