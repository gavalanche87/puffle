extends Area2D

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
@export var next_scene_path: String
@export var spin_speed_deg: float = 140.0
@export var pulse_scale_amount: float = 0.12
@export var pulse_speed: float = 2.4

@onready var sprite: Sprite2D = $Sprite2D
var _base_scale: Vector2 = Vector2.ONE
var _pulse_time: float = 0.0
var _completed: bool = false

func _ready() -> void:
	if sprite:
		_base_scale = sprite.scale
	body_entered.connect(_on_body_entered)
	set_process(true)

func _process(delta: float) -> void:
	if sprite == null:
		return
	sprite.rotation_degrees += spin_speed_deg * delta
	_pulse_time += delta * pulse_speed
	var pulse := 1.0 + (sin(_pulse_time) * pulse_scale_amount)
	sprite.scale = _base_scale * pulse

func _on_body_entered(body: Node) -> void:
	if _completed:
		return
	if not (body is CharacterBody2D):
		return
	_completed = true
	var completion_time: float = 0.0
	var no_hit_bonus: bool = false
	var is_new_record: bool = false
	if body.has_method("on_level_goal_reached"):
		body.call("on_level_goal_reached")
	if body.has_method("get_level_completion_time"):
		completion_time = float(body.call("get_level_completion_time"))
	if body.has_method("get_no_hit_bonus_earned"):
		no_hit_bonus = bool(body.call("get_no_hit_bonus_earned"))
	if body.has_method("get_last_level_time_was_new_record"):
		is_new_record = bool(body.call("get_last_level_time_was_new_record"))
	var game_data := get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("register_level_complete_result"):
		game_data.call("register_level_complete_result", completion_time, no_hit_bonus, next_scene_path, 20, is_new_record)
	if PLAYER_SCRIPT:
		PLAYER_SCRIPT.clear_checkpoint_runtime_state()
	get_tree().change_scene_to_file("res://scenes/ui/LevelComplete.tscn")
