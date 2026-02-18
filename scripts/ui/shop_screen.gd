extends "res://scripts/ui/menu_transitions.gd"

const SHOP_ENTRY_SCENE := preload("res://scenes/ui/ShopEntry.tscn")

@onready var back_button: Button = $Layout/VBox/Header/BackButton
@onready var coins_label: Label = $Layout/VBox/Header/Currencies/Coins/CoinsValue
@onready var tokens_label: Label = $Layout/VBox/Header/Currencies/Tokens/TokensValue
@onready var status_label: Label = $Layout/VBox/Status
@onready var items_list: VBoxContainer = $Layout/VBox/Scroll/Margin/Content/ItemsList
@onready var abilities_list: VBoxContainer = $Layout/VBox/Scroll/Margin/Content/AbilitiesList
@onready var amulets_list: VBoxContainer = $Layout/VBox/Scroll/Margin/Content/AmuletsList
@onready var weapons_list: VBoxContainer = $Layout/VBox/Scroll/Margin/Content/WeaponsList

func _ready() -> void:
	super._ready()
	back_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/MainMenu.tscn")
	)
	var gd: Node = get_node_or_null("/root/GameData")
	if gd:
		if gd.has_method("add_currency"):
			gd.call("add_currency", "coins", 100)
			gd.call("add_currency", "tokens", 100)
		if gd.has_signal("currencies_changed"):
			gd.currencies_changed.connect(_refresh)
		if gd.has_signal("inventory_changed"):
			gd.inventory_changed.connect(_refresh)
		status_label.text = "Testing bonus: +100 Coins, +100 Tokens"
	_refresh()

func _refresh() -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	coins_label.text = str(int(gd.call("get_balance", "coins")))
	tokens_label.text = str(int(gd.call("get_balance", "tokens")))
	_clear_lists()
	for offer in gd.call("get_shop_items"):
		_add_offer(items_list, offer)
	for offer in gd.call("get_shop_abilities"):
		if bool(gd.call("has_ability", String(offer.get("id", "")))):
			continue
		_add_offer(abilities_list, offer)
	for offer in gd.call("get_shop_amulets"):
		if bool(gd.call("has_amulet", String(offer.get("id", "")))):
			continue
		_add_offer(amulets_list, offer)
	for offer in gd.call("get_shop_weapons"):
		if bool(gd.call("has_weapon", String(offer.get("id", "")))):
			continue
		_add_offer(weapons_list, offer)

func _add_offer(parent: VBoxContainer, offer: Dictionary) -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	var entry: Node = SHOP_ENTRY_SCENE.instantiate()
	var currency := String(offer.get("currency", "coins"))
	var cost := int(offer.get("cost", 0))
	var can_buy: bool = bool(gd.call("can_afford", currency, cost))
	var bought: bool = false
	var status: String = ""
	var kind := String(offer.get("kind", ""))
	if kind == "amulet":
		bought = bool(gd.call("has_amulet", String(offer.get("id", ""))))
		status = "Owned" if bought else ""
	elif kind == "ability":
		bought = bool(gd.call("has_ability", String(offer.get("id", ""))))
		status = "Owned" if bought else ""
	elif kind == "weapon":
		bought = bool(gd.call("has_weapon", String(offer.get("id", ""))))
		status = "Owned" if bought else ""
	else:
		var count: int = int(gd.call("get_inventory_count", String(offer.get("inventory_key", ""))))
		status = "Owned: %d" % count
	parent.add_child(entry)
	entry.setup(offer, status, can_buy, bought)
	entry.buy_requested.connect(_on_buy_requested)

func _on_buy_requested(offer_id: String) -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	var result: Dictionary = gd.call("purchase_offer", offer_id)
	status_label.text = String(result.get("message", ""))
	_refresh()

func _clear_lists() -> void:
	for child in items_list.get_children():
		child.queue_free()
	for child in abilities_list.get_children():
		child.queue_free()
	for child in amulets_list.get_children():
		child.queue_free()
	for child in weapons_list.get_children():
		child.queue_free()
