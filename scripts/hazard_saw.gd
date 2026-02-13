extends Area2D

@export var damage: int = 20
@export var rotation_speed_degrees: float = 300.0

func _ready() -> void:
	add_to_group("hazards")

func _process(delta: float) -> void:
	rotation += deg_to_rad(rotation_speed_degrees) * delta

func get_damage_amount() -> int:
	return damage
