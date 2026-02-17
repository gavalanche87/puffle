extends Control

signal opened
signal closed

@export var manage_pause_state: bool = true

@onready var title_label: Label = $Panel/Margin/VBox/Header/Title
@onready var content: Control = $Panel/Margin/VBox/Content
@onready var close_button: Button = $Panel/Margin/VBox/Footer/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if close_button:
		close_button.pressed.connect(close_popup)

func set_title(text: String) -> void:
	if title_label:
		title_label.text = text

func open_popup() -> void:
	if visible:
		return
	visible = true
	if manage_pause_state:
		get_tree().paused = true
	emit_signal("opened")

func close_popup() -> void:
	if not visible:
		return
	visible = false
	if manage_pause_state:
		get_tree().paused = false
	emit_signal("closed")
