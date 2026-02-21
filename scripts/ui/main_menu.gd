extends "res://scripts/ui/menu_transitions.gd"

@onready var play_button: Button = $Layout/Buttons/PlayButton
@onready var shop_button: Button = $Layout/Buttons/ShopButton
@onready var character_button: Button = $Layout/Buttons/AmuletsButton
@onready var how_to_play_button: Button = $Layout/Buttons/HowToPlayButton
@onready var settings_button: Button = $Layout/Buttons/SettingsButton
@onready var wipe_save_button: Button = $Layout/Buttons/WipeSaveButton

func _ready() -> void:
	super._ready()
	play_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/LevelSelect.tscn")
	)
	shop_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/Shop.tscn")
	)
	character_button.pressed.connect(func() -> void:
		var gd: Node = get_node_or_null("/root/GameData")
		if gd and gd.has_method("set_amulet_screen_manage_mode"):
			gd.call("set_amulet_screen_manage_mode", false)
		go_to_scene("res://scenes/ui/Character.tscn")
	)
	how_to_play_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/HowToPlay.tscn")
	)
	settings_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/Settings.tscn")
	)
	wipe_save_button.pressed.connect(func() -> void:
		var gd: Node = get_node_or_null("/root/GameData")
		if gd and gd.has_method("wipe_save_data"):
			gd.call("wipe_save_data")
	)
