extends "res://scripts/ui/menu_transitions.gd"

signal overlay_closed(from_pause_menu: bool)

@onready var back_button: Button = $Layout/VBox/Header/BackButton
@onready var music_slider: HSlider = $Layout/VBox/ContentPanel/Content/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Layout/VBox/ContentPanel/Content/SfxRow/SfxSlider
@onready var music_value: Label = $Layout/VBox/ContentPanel/Content/MusicRow/MusicValue
@onready var sfx_value: Label = $Layout/VBox/ContentPanel/Content/SfxRow/SfxValue
@onready var wipe_save_button: Button = $Layout/VBox/ContentPanel/Content/WipeSaveButton

var _overlay_mode: bool = false
var _opened_from_pause_menu: bool = false

func set_overlay_mode(enabled: bool, from_pause_menu: bool = false) -> void:
	_overlay_mode = enabled
	_opened_from_pause_menu = from_pause_menu

func _ready() -> void:
	super._ready()
	back_button.pressed.connect(_go_back)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	if wipe_save_button:
		wipe_save_button.pressed.connect(_on_wipe_save_pressed)
	var gd := get_node_or_null("/root/GameData")
	if gd:
		music_slider.value = gd.get_music_volume_linear() * 100.0
		sfx_slider.value = gd.get_sfx_volume_linear() * 100.0
	_update_labels()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _go_back() -> void:
	if _overlay_mode:
		emit_signal("overlay_closed", _opened_from_pause_menu)
		return
	go_to_scene("res://scenes/ui/MainMenu.tscn")

func _on_music_changed(value: float) -> void:
	var gd := get_node_or_null("/root/GameData")
	if gd:
		gd.set_music_volume_linear(value / 100.0)
	_update_labels()

func _on_sfx_changed(value: float) -> void:
	var gd := get_node_or_null("/root/GameData")
	if gd:
		gd.set_sfx_volume_linear(value / 100.0)
	_update_labels()

func _update_labels() -> void:
	music_value.text = "%d%%" % int(round(music_slider.value))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value))

func _on_wipe_save_pressed() -> void:
	var gd := get_node_or_null("/root/GameData")
	if gd and gd.has_method("wipe_save_data"):
		gd.call("wipe_save_data")
