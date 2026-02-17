extends "res://scripts/ui/menu_transitions.gd"

@onready var back_button: Button = $Layout/VBox/Header/BackButton
@onready var music_slider: HSlider = $Layout/VBox/Content/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Layout/VBox/Content/SfxRow/SfxSlider
@onready var music_value: Label = $Layout/VBox/Content/MusicRow/MusicValue
@onready var sfx_value: Label = $Layout/VBox/Content/SfxRow/SfxValue

func _ready() -> void:
	super._ready()
	back_button.pressed.connect(_go_back)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	var gd := get_node_or_null("/root/GameData")
	if gd:
		music_slider.value = gd.get_music_volume_linear() * 100.0
		sfx_slider.value = gd.get_sfx_volume_linear() * 100.0
	_update_labels()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _go_back() -> void:
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
