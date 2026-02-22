extends Area2D

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
@export var next_scene_path: String
@export var spin_speed_deg: float = 140.0
@export var pulse_scale_amount: float = 0.12
@export var pulse_speed: float = 2.4

@onready var sprite: Sprite2D = $Sprite2D
var _base_scale: Vector2 = Vector2.ONE
var _pulse_time: float = 0.0

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
	if not (body is CharacterBody2D):
		return
	var game_data := get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("complete_current_level"):
		game_data.call("complete_current_level")
	if PLAYER_SCRIPT:
		PLAYER_SCRIPT.clear_checkpoint_runtime_state()
	if game_data and game_data.has_method("is_level_flow_active") and game_data.call("is_level_flow_active"):
		game_data.call("exit_level_flow")
		get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")
		return
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
