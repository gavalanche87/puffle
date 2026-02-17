extends "res://scripts/ui/menu_transitions.gd"

@onready var back_button: Button = $Layout/VBox/Header/BackButton

func _ready() -> void:
	super._ready()
	back_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/MainMenu.tscn")
	)
