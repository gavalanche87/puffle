extends "res://scripts/ui/popup_window.gd"

signal resume_requested
signal settings_requested
signal amulets_requested
signal main_menu_requested

@onready var resume_button: Button = $Panel/Margin/VBox/Content/Buttons/ResumeButton
@onready var settings_button: Button = $Panel/Margin/VBox/Content/Buttons/SettingsButton
@onready var amulets_button: Button = $Panel/Margin/VBox/Content/Buttons/AmuletsButton
@onready var main_menu_button: Button = $Panel/Margin/VBox/Content/Buttons/MainMenuButton

func _ready() -> void:
	super._ready()
	set_title("PAUSED")
	if close_button:
		close_button.visible = false
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button:
		settings_button.pressed.connect(func() -> void:
			emit_signal("settings_requested")
		)
	if amulets_button:
		amulets_button.pressed.connect(func() -> void:
			emit_signal("amulets_requested")
		)
	if main_menu_button:
		main_menu_button.pressed.connect(func() -> void:
			emit_signal("main_menu_requested")
		)

func _on_resume_pressed() -> void:
	emit_signal("resume_requested")
