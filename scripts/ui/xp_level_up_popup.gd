extends "res://scripts/ui/popup_window.gd"

@onready var message_label: Label = $Panel/Margin/VBox/Content/Message
@onready var token_amount_label: Label = $Panel/Margin/VBox/Content/RewardRow/TokenAmountLabel
@onready var token_sfx: AudioStreamPlayer = $TokenSfx

func _ready() -> void:
	super._ready()
	set_title("LEVEL UP")
	if close_button:
		close_button.text = "CLAIM"

func setup_reward(tokens_reward: int, new_level: int) -> void:
	var safe_reward: int = maxi(1, tokens_reward)
	if message_label:
		message_label.text = "Level %d Reached!" % new_level
	if token_amount_label:
		token_amount_label.text = "x%d" % safe_reward

func open_popup() -> void:
	super.open_popup()
	_play_token_sfx()

func close_popup() -> void:
	_play_token_sfx()
	super.close_popup()

func _play_token_sfx() -> void:
	if token_sfx and token_sfx.stream:
		token_sfx.stop()
		token_sfx.play()
