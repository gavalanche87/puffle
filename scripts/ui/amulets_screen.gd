extends "res://scripts/ui/menu_transitions.gd"
signal overlay_closed(from_pause_menu: bool)

const NAV_BUTTON_SCENE := preload("res://scenes/ui/NavButton.tscn")
const ICON_LEAP_OF_FAITH: Texture2D = preload("res://assets/ui/amulets/Leap_Of_Faith_Amulet.png")
const COLOR_AMULET_OUTLINE := Color(0.87451, 0.486275, 0.827451, 1.0) # #df7cd3
const COLOR_LIGHT_TEXT := Color(0.933333, 0.898039, 0.913725, 1.0) # #eee5e9
const AMULET_ICON_MAP := {
	"leap_of_faith": ICON_LEAP_OF_FAITH
}

@onready var back_button: Button = $Layout/VBox/Header/BackButton
@onready var split: HSplitContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split
@onready var slots_section: Panel = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection
@onready var slots_scroll: ScrollContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll
@onready var slot_1: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll/SlotsRow/Slot1
@onready var slot_2: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll/SlotsRow/Slot2
@onready var slot_3: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll/SlotsRow/Slot3
@onready var owned_list: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Left/OwnedScroll/OwnedList
@onready var selected_title: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/SelectedRow/SelectedTitle
@onready var selected_icon: TextureRect = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/SelectedRow/SelectedIcon
@onready var boon_label: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/BoonLabel
@onready var grievance_label: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/GrievanceLabel

var _selected_amulet_id: String = ""
var _manage_mode: bool = false
var _equipped_only_mode: bool = false
var _overlay_mode: bool = false
var _opened_from_pause_menu: bool = false
var _embedded_mode: bool = false

func set_manage_mode(enabled: bool) -> void:
	_manage_mode = enabled
	if is_inside_tree():
		_refresh()

func set_embedded_mode(enabled: bool) -> void:
	_embedded_mode = enabled
	if is_inside_tree():
		_apply_embedded_mode()

func set_equipped_only_mode(enabled: bool) -> void:
	_equipped_only_mode = enabled
	if is_inside_tree():
		_refresh()

func set_compact_mode(_enabled: bool) -> void:
	if is_inside_tree():
		_apply_embedded_mode()

func set_overlay_mode(enabled: bool, from_pause_menu: bool) -> void:
	_overlay_mode = enabled
	_opened_from_pause_menu = from_pause_menu

func _ready() -> void:
	super._ready()
	var gd: Node = get_node_or_null("/root/GameData")
	if (not _manage_mode) and gd and gd.has_method("get_amulet_screen_manage_mode"):
		_manage_mode = bool(gd.call("get_amulet_screen_manage_mode"))
	if gd and gd.has_signal("amulets_changed"):
		if not gd.amulets_changed.is_connected(_refresh):
			gd.amulets_changed.connect(_refresh)
	back_button.pressed.connect(_on_back_pressed)
	_bind_slot_buttons(slot_1, 0)
	_bind_slot_buttons(slot_2, 1)
	_bind_slot_buttons(slot_3, 2)
	_apply_embedded_mode()
	selected_title.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
	selected_title.add_theme_color_override("font_outline_color", COLOR_AMULET_OUTLINE)
	_refresh()

func _apply_embedded_mode() -> void:
	var bg := get_node_or_null("Background") as CanvasItem
	var header := get_node_or_null("Layout/VBox/Header") as CanvasItem
	if bg:
		bg.visible = not _embedded_mode
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

func _bind_slot_buttons(slot_node: VBoxContainer, slot_index: int) -> void:
	var action_btn := _get_slot_button(slot_node)
	if action_btn == null:
		return
	action_btn.pressed.connect(func() -> void:
		_on_slot_action_pressed(slot_index)
	)

func _on_back_pressed() -> void:
	if _embedded_mode:
		return
	if _overlay_mode:
		emit_signal("overlay_closed", _opened_from_pause_menu)
		return
	var gd: Node = get_node_or_null("/root/GameData")
	if _manage_mode and gd and gd.has_method("get_amulet_return_scene_path"):
		var return_path := String(gd.call("get_amulet_return_scene_path"))
		if gd.has_method("set_amulet_screen_manage_mode"):
			gd.call("set_amulet_screen_manage_mode", false)
		if return_path != "":
			go_to_scene(return_path)
			return
	if gd and gd.has_method("set_amulet_screen_manage_mode"):
		gd.call("set_amulet_screen_manage_mode", false)
	go_to_scene("res://scenes/ui/Character.tscn")

func _refresh() -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	slots_section.visible = _manage_mode
	_clear_owned_list()
	var owned: Array = gd.call("get_owned_amulets")
	var equipped: Array = gd.call("get_equipped_amulets")
	var catalog: Array = gd.call("get_amulet_catalog")
	var selected_exists := false
	for entry_variant in catalog:
		var entry: Dictionary = entry_variant
		var amulet_id := String(entry.get("id", ""))
		var should_show: bool = owned.has(amulet_id)
		if _equipped_only_mode:
			should_show = equipped.has(amulet_id)
		if not should_show:
			continue
		selected_exists = selected_exists or amulet_id == _selected_amulet_id
		_add_owned_button(entry)
	if not selected_exists:
		var fallback_ids: Array = equipped if _equipped_only_mode else owned
		_selected_amulet_id = String(fallback_ids[0]) if not fallback_ids.is_empty() else ""
	_update_details(gd)
	_update_slot_ui(gd)

func _add_owned_button(entry: Dictionary) -> void:
	var amulet_id := String(entry.get("id", ""))
	var b := NAV_BUTTON_SCENE.instantiate() as Button
	if b == null:
		return
	b.text = String(entry.get("title", amulet_id))
	b.icon = _get_amulet_icon(amulet_id)
	b.expand_icon = true
	b.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
	b.add_theme_color_override("font_outline_color", COLOR_AMULET_OUTLINE)
	b.modulate = Color(1, 1, 1, 1)
	b.pressed.connect(func() -> void:
		_selected_amulet_id = amulet_id
		_refresh()
	)
	owned_list.add_child(b)

func _update_details(gd: Node) -> void:
	if _selected_amulet_id == "":
		selected_title.text = "No Amulet Selected"
		selected_icon.texture = null
		boon_label.text = "Boon:"
		grievance_label.text = "Grievance:"
		return
	var catalog: Array = gd.call("get_amulet_catalog")
	for entry_variant in catalog:
		var entry: Dictionary = entry_variant
		if String(entry.get("id", "")) != _selected_amulet_id:
			continue
		selected_title.text = String(entry.get("title", _selected_amulet_id))
		selected_icon.texture = _get_amulet_icon(_selected_amulet_id)
		boon_label.text = "Boon: %s" % String(entry.get("boon", ""))
		grievance_label.text = "Grievance: %s" % String(entry.get("grievance", ""))
		return

func _update_slot_ui(gd: Node) -> void:
	var equipped: Array = gd.call("get_equipped_amulets")
	var unlocked: int = int(gd.call("get_amulet_slots_unlocked"))
	_apply_slot(slot_1, 0, unlocked, equipped, gd)
	_apply_slot(slot_2, 1, unlocked, equipped, gd)
	_apply_slot(slot_3, 2, unlocked, equipped, gd)

func _apply_slot(slot_node: VBoxContainer, slot_index: int, unlocked: int, equipped: Array, gd: Node) -> void:
	slot_node.visible = slot_index < unlocked
	if not slot_node.visible:
		return
	var equipped_id := String(equipped[slot_index]) if equipped.size() > slot_index else ""
	var icon: TextureRect = slot_node.get_node("Backing/Icon")
	var action_btn := _get_slot_button(slot_node)
	if action_btn == null:
		return
	icon.texture = _get_amulet_icon(equipped_id)
	var owned: Array = gd.call("get_owned_amulets")
	if equipped_id == "":
		var already_equipped_elsewhere := _selected_amulet_id != "" and equipped.has(_selected_amulet_id)
		action_btn.disabled = (not _manage_mode) or _selected_amulet_id == "" or (not owned.has(_selected_amulet_id)) or already_equipped_elsewhere
		action_btn.text = "EQUIP"
	else:
		action_btn.disabled = not _manage_mode
		action_btn.text = "UNEQUIP"

func _on_slot_action_pressed(slot_index: int) -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	var equipped: Array = gd.call("get_equipped_amulets")
	var slot_value := String(equipped[slot_index]) if equipped.size() > slot_index else ""
	if slot_value != "":
		gd.call("unequip_amulet", slot_index)
		_refresh()
		return
	if _selected_amulet_id == "":
		return
	if equipped.has(_selected_amulet_id):
		return
	gd.call("equip_amulet", _selected_amulet_id, slot_index)
	_refresh()

func _clear_owned_list() -> void:
	for child in owned_list.get_children():
		child.queue_free()

func _get_amulet_icon(amulet_id: String) -> Texture2D:
	return AMULET_ICON_MAP.get(amulet_id, null)

func _get_slot_button(slot_node: VBoxContainer) -> Button:
	var btn := slot_node.get_node_or_null("EquipButton") as Button
	if btn:
		return btn
	for child in slot_node.get_children():
		var child_button := child as Button
		if child_button and String(child_button.name).begins_with("EquipButton"):
			return child_button
	return slot_node.get_node_or_null("ActionButton") as Button
