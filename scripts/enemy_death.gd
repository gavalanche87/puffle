extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	sprite.play("explode")
	particles.emitting = true
	sprite.animation_finished.connect(_on_anim_finished)

func _on_anim_finished() -> void:
	queue_free()
