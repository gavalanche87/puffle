extends "res://scripts/ui/menu_transitions.gd"

@onready var play_button: Button = $Layout/Panel/Margin/Buttons/PlayButton
@onready var shop_button: Button = $Layout/Panel/Margin/Buttons/ShopButton
@onready var how_to_play_button: Button = $Layout/Panel/Margin/Buttons/HowToPlayButton
@onready var settings_button: Button = $Layout/Panel/Margin/Buttons/SettingsButton

func _ready() -> void:
	super._ready()
	play_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/LevelSelect.tscn")
	)
	shop_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/Shop.tscn")
	)
	how_to_play_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/HowToPlay.tscn")
	)
	settings_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/Settings.tscn")
	)
