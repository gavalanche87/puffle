extends "res://scripts/ui/menu_transitions.gd"

const NAV_BUTTON_SCENE := preload("res://scenes/ui/NavButton.tscn")
const ICON_HEAD_SPIKE: Texture2D = preload("res://assets/ui/weapons/Head_Spike_Weapon.png")
const COLOR_WEAPON_OUTLINE := Color(0.113725, 0.701961, 0.482353, 1.0) # #1db37b
const COLOR_LIGHT_TEXT := Color(0.933333, 0.898039, 0.913725, 1.0) # #eee5e9
const WEAPON_ICON_MAP := {
	"head_spike": ICON_HEAD_SPIKE
}

@onready var back_button: Button = $Layout/VBox/Header/BackButton
@onready var split: HSplitContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split
@onready var background: ColorRect = $Background
@onready var header: Control = $Layout/VBox/Header
@onready var slot_1: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll/SlotsRow/Slot1
@onready var slot_2: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll/SlotsRow/Slot2
@onready var slot_3: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll/SlotsRow/Slot3
@onready var owned_list: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Left/OwnedScroll/OwnedList
@onready var selected_title: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/SelectedRow/SelectedTitle
@onready var selected_icon: TextureRect = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/SelectedRow/SelectedIcon
@onready var description_label: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/DescriptionLabel
@onready var slots_section: Panel = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection
@onready var slots_scroll: ScrollContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll

var _selected_weapon_id: String = ""
var _manage_mode: bool = false
var _embedded_mode: bool = false

func set_manage_mode(enabled: bool) -> void:
	_manage_mode = enabled
	if is_inside_tree():
		_refresh()

func set_embedded_mode(enabled: bool) -> void:
	_embedded_mode = enabled
	if is_inside_tree():
		_apply_embedded_mode()

func set_compact_mode(_enabled: bool) -> void:
	if is_inside_tree():
		_apply_embedded_mode()

func _ready() -> void:
	super._ready()
	var gd: Node = get_node_or_null("/root/GameData")
	if (not _manage_mode) and gd and gd.has_method("get_amulet_screen_manage_mode"):
		_manage_mode = bool(gd.call("get_amulet_screen_manage_mode"))
	if gd and gd.has_signal("weapons_changed"):
		if not gd.weapons_changed.is_connected(_refresh):
			gd.weapons_changed.connect(_refresh)
	if back_button:
		back_button.pressed.connect(func() -> void:
			go_to_scene("res://scenes/ui/Character.tscn")
		)
	_bind_slot_button(slot_1)
	if slot_2:
		slot_2.visible = false
	if slot_3:
		slot_3.visible = false
	_apply_embedded_mode()
	selected_title.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
	selected_title.add_theme_color_override("font_outline_color", COLOR_WEAPON_OUTLINE)
	_refresh()

func _apply_embedded_mode() -> void:
	if background:
		background.visible = not _embedded_mode
	if header:
		header.visible = not _embedded_mode
	if split:
		split.mouse_filter = Control.MOUSE_FILTER_IGNORE
		split.dragger_visibility = 2
	if slots_scroll:
		slots_scroll.horizontal_scroll_mode = 2
		slots_scroll.vertical_scroll_mode = 0
		var hbar := slots_scroll.get_h_scroll_bar()
		if hbar:
			hbar.modulate.a = 0.0
			hbar.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _bind_slot_button(slot_node: VBoxContainer) -> void:
	if slot_node == null:
		return
	var action_btn := _get_slot_button(slot_node)
	if action_btn == null:
		return
	action_btn.pressed.connect(func() -> void:
		_on_slot_action_pressed()
	)

func _refresh() -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	slots_section.visible = _manage_mode
	_clear_owned_list()
	var owned: Array = gd.call("get_owned_weapons")
	var catalog: Array = gd.call("get_weapon_catalog")
	var selected_exists := false
	for entry_variant in catalog:
		var entry: Dictionary = entry_variant
		var weapon_id := String(entry.get("id", ""))
		if not owned.has(weapon_id):
			continue
		selected_exists = selected_exists or weapon_id == _selected_weapon_id
		_add_owned_button(entry)
	if not selected_exists:
		_selected_weapon_id = String(owned[0]) if not owned.is_empty() else ""
	_update_details(gd)
	_update_slot_ui(gd)

func _add_owned_button(entry: Dictionary) -> void:
	var weapon_id := String(entry.get("id", ""))
	var button: Button = NAV_BUTTON_SCENE.instantiate() as Button
	if button == null:
		return
	button.text = String(entry.get("title", weapon_id))
	button.icon = _get_weapon_icon(weapon_id)
	button.expand_icon = true
	button.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
	button.add_theme_color_override("font_outline_color", COLOR_WEAPON_OUTLINE)
	button.modulate = Color(1, 1, 1, 1)
	button.pressed.connect(func() -> void:
		_selected_weapon_id = weapon_id
		_refresh()
	)
	owned_list.add_child(button)

func _update_details(gd: Node) -> void:
	if _selected_weapon_id == "":
		selected_title.text = "No Weapon Selected"
		selected_icon.texture = null
		description_label.text = ""
		return
	var catalog: Array = gd.call("get_weapon_catalog")
	for entry_variant in catalog:
		var entry: Dictionary = entry_variant
		if String(entry.get("id", "")) != _selected_weapon_id:
			continue
		selected_title.text = String(entry.get("title", _selected_weapon_id))
		selected_icon.texture = _get_weapon_icon(_selected_weapon_id)
		description_label.text = String(entry.get("boon", ""))
		return

func _update_slot_ui(gd: Node) -> void:
	if slot_1 == null:
		return
	var equipped_id := String(gd.call("get_equipped_weapon"))
	var icon: TextureRect = slot_1.get_node_or_null("Backing/Icon") as TextureRect
	var action_btn := _get_slot_button(slot_1)
	if icon:
		icon.texture = _get_weapon_icon(equipped_id)
	if action_btn:
		if equipped_id == "":
			action_btn.text = "EQUIP"
			action_btn.disabled = (not _manage_mode) or _selected_weapon_id == "" or (not bool(gd.call("has_weapon", _selected_weapon_id)))
		else:
			action_btn.text = "UNEQUIP"
			action_btn.disabled = not _manage_mode

func _on_slot_action_pressed() -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	var equipped_id := String(gd.call("get_equipped_weapon"))
	if equipped_id != "":
		gd.call("unequip_weapon")
		_refresh()
		return
	if _selected_weapon_id == "":
		return
	gd.call("equip_weapon", _selected_weapon_id)
	_refresh()

func _clear_owned_list() -> void:
	for child in owned_list.get_children():
		child.queue_free()

func _get_weapon_icon(weapon_id: String) -> Texture2D:
	return WEAPON_ICON_MAP.get(weapon_id, null)

func _get_slot_button(slot_node: VBoxContainer) -> Button:
	var btn := slot_node.get_node_or_null("EquipButton") as Button
	if btn:
		return btn
	for child in slot_node.get_children():
		var child_button := child as Button
		if child_button and String(child_button.name).begins_with("EquipButton"):
			return child_button
	return slot_node.get_node_or_null("ActionButton") as Button
