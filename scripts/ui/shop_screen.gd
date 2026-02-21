extends "res://scripts/ui/menu_transitions.gd"

const SHOP_ENTRY_SCENE := preload("res://scenes/ui/ShopEntry.tscn")

@onready var back_button: Button = $Layout/VBox/Header/BackButton
@onready var coins_label: Label = $Layout/VBox/Header/Currencies/Coins/CoinsValue
@onready var tokens_label: Label = $Layout/VBox/Header/Currencies/Tokens/TokensValue
@onready var items_tab: Button = $Layout/VBox/Tabs/ItemsTab
@onready var weapons_tab: Button = $Layout/VBox/Tabs/WeaponsTab
@onready var amulets_tab: Button = $Layout/VBox/Tabs/AmuletsTab
@onready var abilities_tab: Button = $Layout/VBox/Tabs/AbilitiesTab
@onready var music_tab: Button = $Layout/VBox/Tabs/MusicTab
@onready var offers_list: VBoxContainer = $Layout/VBox/Scroll/Margin/OffersList

var _active_tab: String = "items"
const TAB_OUTLINE_ITEMS := Color(0.796078, 0.682353, 0.145098, 1.0)
const TAB_OUTLINE_WEAPONS := Color(0.113725, 0.701961, 0.482353, 1.0)
const TAB_OUTLINE_AMULETS := Color(0.87451, 0.486275, 0.827451, 1.0)
const TAB_OUTLINE_ABILITIES := Color(0.980392, 0.513725, 0.203922, 1.0) # #fa8334
const TAB_OUTLINE_MUSIC := Color(0.254902, 0.737255, 0.737255, 1.0) # #41bcbc

func _ready() -> void:
	super._ready()
	back_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/MainMenu.tscn")
	)
	items_tab.pressed.connect(func() -> void:
		_set_active_tab("items")
	)
	weapons_tab.pressed.connect(func() -> void:
		_set_active_tab("weapons")
	)
	amulets_tab.pressed.connect(func() -> void:
		_set_active_tab("amulets")
	)
	abilities_tab.pressed.connect(func() -> void:
		_set_active_tab("abilities")
	)
	music_tab.pressed.connect(func() -> void:
		_set_active_tab("music")
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
	_set_active_tab("items")

func _refresh() -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	coins_label.text = str(int(gd.call("get_balance", "coins")))
	tokens_label.text = str(int(gd.call("get_balance", "tokens")))
	_clear_list()
	for offer in _get_offers_for_tab(gd, _active_tab):
		_add_offer(offers_list, offer)
	_update_tab_visuals()

func _add_offer(parent: VBoxContainer, offer: Dictionary) -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	var entry: Node = SHOP_ENTRY_SCENE.instantiate()
	var entry_control: Control = entry as Control
	if entry_control:
		entry_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	elif kind == "music_track":
		bought = bool(gd.call("has_music_track", String(offer.get("id", ""))))
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
	gd.call("purchase_offer", offer_id)
	_refresh()

func _set_active_tab(tab_id: String) -> void:
	_active_tab = tab_id
	_refresh()

func _get_offers_for_tab(gd: Node, tab_id: String) -> Array:
	var out: Array = []
	match tab_id:
		"items":
			out = gd.call("get_shop_items")
		"weapons":
			for offer in gd.call("get_shop_weapons"):
				if bool(gd.call("has_weapon", String(offer.get("id", "")))):
					continue
				out.append(offer)
		"amulets":
			for offer in gd.call("get_shop_amulets"):
				if bool(gd.call("has_amulet", String(offer.get("id", "")))):
					continue
				out.append(offer)
		"abilities":
			for offer in gd.call("get_shop_abilities"):
				if bool(gd.call("has_ability", String(offer.get("id", "")))):
					continue
				out.append(offer)
		"music":
			for offer in gd.call("get_shop_music_tracks"):
				if bool(gd.call("has_music_track", String(offer.get("id", "")))):
					continue
				out.append(offer)
		_:
			out = []
	return out

func _clear_list() -> void:
	for child in offers_list.get_children():
		child.queue_free()

func _update_tab_visuals() -> void:
	items_tab.add_theme_color_override("font_outline_color", TAB_OUTLINE_ITEMS)
	weapons_tab.add_theme_color_override("font_outline_color", TAB_OUTLINE_WEAPONS)
	amulets_tab.add_theme_color_override("font_outline_color", TAB_OUTLINE_AMULETS)
	abilities_tab.add_theme_color_override("font_outline_color", TAB_OUTLINE_ABILITIES)
	music_tab.add_theme_color_override("font_outline_color", TAB_OUTLINE_MUSIC)
	items_tab.modulate = Color(1, 1, 1, 1) if _active_tab == "items" else Color(0.75, 0.75, 0.75, 1)
	weapons_tab.modulate = Color(1, 1, 1, 1) if _active_tab == "weapons" else Color(0.75, 0.75, 0.75, 1)
	amulets_tab.modulate = Color(1, 1, 1, 1) if _active_tab == "amulets" else Color(0.75, 0.75, 0.75, 1)
	abilities_tab.modulate = Color(1, 1, 1, 1) if _active_tab == "abilities" else Color(0.75, 0.75, 0.75, 1)
	music_tab.modulate = Color(1, 1, 1, 1) if _active_tab == "music" else Color(0.75, 0.75, 0.75, 1)
