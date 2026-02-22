extends "res://scripts/ui/popup_window.gd"

signal activate_requested
signal cancelled

@onready var message_label: Label = $Panel/Margin/VBox/Content/Message
@onready var activate_button: Button = $Panel/Margin/VBox/Content/Buttons/ActivateButton
@onready var cancel_button: Button = $Panel/Margin/VBox/Content/Buttons/CancelButton

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
	if message_label:
		message_label.text = "Activate checkpoint for %d coin%s?" % [cost, ("" if cost == 1 else "s")]
	if activate_button:
		activate_button.text = "ACTIVATE"
		activate_button.disabled = not can_afford

func set_insufficient_funds(cost: int) -> void:
	if message_label:
		message_label.text = "Need %d coin%s to activate checkpoint." % [cost, ("" if cost == 1 else "s")]
	if activate_button:
		activate_button.disabled = true

func _on_activate_pressed() -> void:
	emit_signal("activate_requested")

func _on_cancel_pressed() -> void:
	close_popup()
	emit_signal("cancelled")
