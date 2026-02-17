extends Panel

@onready var title_label: Label = $Margin/VBox/Title
@onready var description_label: Label = $Margin/VBox/Description
@onready var price_label: Label = $Margin/VBox/Bottom/Price
@onready var state_label: Label = $Margin/VBox/Bottom/State
@onready var buy_button: Button = $Margin/VBox/Bottom/BuyButton

var offer_id: String = ""

signal buy_requested(offer_id: String)

func setup(data: Dictionary, status_text: String, can_buy: bool, bought: bool) -> void:
	offer_id = String(data.get("id", ""))
	title_label.text = String(data.get("title", "Item"))
	description_label.text = String(data.get("description", ""))
	price_label.text = "%d %s" % [int(data.get("cost", 0)), String(data.get("currency", "coins")).capitalize()]
	state_label.text = status_text
	buy_button.disabled = (not can_buy) or bought
	buy_button.text = "Owned" if bought else "Buy"

func _ready() -> void:
	buy_button.pressed.connect(func() -> void:
		emit_signal("buy_requested", offer_id)
	)
