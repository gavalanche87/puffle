extends "res://scripts/ui/menu_transitions.gd"

@onready var play_button: Button = $Layout/Buttons/PlayButton
@onready var shop_button: Button = $Layout/Buttons/ShopButton
@onready var character_button: Button = $Layout/Buttons/AmuletsButton
@onready var how_to_play_button: Button = $Layout/Buttons/HowToPlayButton
@onready var settings_button: Button = $Layout/Buttons/SettingsButton
@onready var title_label: Label = $Layout/Buttons/Title

var _title_tween: Tween

func _ready() -> void:
	super._ready()
	_start_title_tween()
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

func _start_title_tween() -> void:
	if title_label == null:
		return
	title_label.pivot_offset = title_label.size * 0.5
	title_label.scale = Vector2.ONE
	title_label.rotation_degrees = 0.0
	if _title_tween and _title_tween.is_running():
		_title_tween.kill()
	_title_tween = create_tween()
	_title_tween.set_loops()
	_title_tween.tween_property(title_label, "scale", Vector2(1.12, 1.12), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_title_tween.parallel().tween_property(title_label, "rotation_degrees", 3.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_title_tween.tween_property(title_label, "scale", Vector2(0.92, 0.92), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_title_tween.parallel().tween_property(title_label, "rotation_degrees", -3.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_title_tween.tween_property(title_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_title_tween.parallel().tween_property(title_label, "rotation_degrees", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
