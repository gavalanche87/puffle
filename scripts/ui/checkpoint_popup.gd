extends "res://scripts/ui/popup_window.gd"

signal activate_requested
signal loadout_requested
signal cancelled

@onready var message_label: Label = $Panel/Margin/VBox/Content/Message
@onready var activate_button: Button = $Panel/Margin/VBox/Content/Buttons/ActivateButton
@onready var cancel_button: Button = $Panel/Margin/VBox/Content/Buttons/CancelButton

var _mode: String = "activate"

func _ready() -> void:
	super._ready()
	set_title("CHECKPOINT")
	if close_button:
		close_button.visible = false
	if activate_button and not activate_button.pressed.is_connected(_on_activate_pressed):
		activate_button.pressed.connect(_on_activate_pressed)
	if cancel_button and not cancel_button.pressed.is_connected(_on_cancel_pressed):
		cancel_button.pressed.connect(_on_cancel_pressed)

func setup_for_cost(cost: int, can_afford: bool) -> void:
	_mode = "activate"
	set_title("CHECKPOINT")
	if message_label:
		message_label.text = "Activate checkpoint for %d coin%s?" % [cost, ("" if cost == 1 else "s")]
	if activate_button:
		activate_button.text = "ACTIVATE"
		activate_button.disabled = not can_afford
		activate_button.visible = true
	if cancel_button:
		cancel_button.text = "CANCEL"
		cancel_button.visible = true

func setup_for_menu() -> void:
	_mode = "menu"
	set_title("CHECKPOINT")
	if message_label:
		message_label.text = "Checkpoint active"
	if activate_button:
		activate_button.text = "LOADOUT"
		activate_button.disabled = false
		activate_button.visible = true
	if cancel_button:
		cancel_button.text = "CLOSE"
		cancel_button.visible = true

func set_insufficient_funds(cost: int) -> void:
	_mode = "activate"
	if message_label:
		message_label.text = "Need %d coin%s to activate checkpoint." % [cost, ("" if cost == 1 else "s")]
	if activate_button:
		activate_button.disabled = true

func _on_activate_pressed() -> void:
	if _mode == "menu":
		emit_signal("loadout_requested")
		return
	emit_signal("activate_requested")

func _on_cancel_pressed() -> void:
	close_popup()
	emit_signal("cancelled")
