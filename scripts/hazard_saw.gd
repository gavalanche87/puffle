extends Area2D

@export var damage: int = 20
@export var rotation_speed_degrees: float = 300.0
@export var attached_node_path: NodePath
@export var auto_attach_to_nearest: bool = true
@export var attach_search_radius: float = 72.0
@export var release_speed_min: float = 85.0
@export var release_speed_max: float = 145.0
@export var falling_saw_scene: PackedScene = preload("res://scenes/hazards/FallingSaw.tscn")

var _is_on_screen: bool = false
var _notifier: VisibleOnScreenNotifier2D
var _attached_node: Node2D
var _detached: bool = false

func _ready() -> void:
	add_to_group("hazards")
	_resolve_attached_node()
	_bind_attached_node()
	
	_notifier = VisibleOnScreenNotifier2D.new()
	# Set rect slightly larger than collision shape to avoid flickering at edges
	_notifier.rect = Rect2(-16, -16, 32, 32)
	_notifier.screen_entered.connect(_on_screen_entered)
	_notifier.screen_exited.connect(_on_screen_exited)
	add_child(_notifier)

func _process(delta: float) -> void:
	rotation += deg_to_rad(rotation_speed_degrees) * delta

func get_damage_amount() -> int:
	return damage

func _resolve_attached_node() -> void:
	if attached_node_path != NodePath():
		_attached_node = get_node_or_null(attached_node_path) as Node2D
	if _attached_node == null and auto_attach_to_nearest:
		_attached_node = _find_nearest_attach_candidate()
		if _attached_node:
			attached_node_path = get_path_to(_attached_node)

func _bind_attached_node() -> void:
	if _attached_node == null:
		return
	if _attached_node.has_signal("broken"):
		var on_broken := Callable(self, "_on_attached_broken")
		if not _attached_node.is_connected("broken", on_broken):
			_attached_node.connect("broken", on_broken)
	var on_exit := Callable(self, "_on_attached_tree_exiting")
	if not _attached_node.tree_exiting.is_connected(on_exit):
		_attached_node.tree_exiting.connect(on_exit)

func _find_nearest_attach_candidate() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := INF
	var roots: Array[Node] = [get_tree().current_scene]
	for root in roots:
		if root == null:
			continue
		var all := root.find_children("*", "Node2D", true, false)
		for entry in all:
			var node := entry as Node2D
			if node == null or node == self:
				continue
			if not _is_attach_candidate(node):
				continue
			var dist := global_position.distance_to(node.global_position)
			if dist <= attach_search_radius and dist < nearest_dist:
				nearest_dist = dist
				nearest = node
	return nearest

func _is_attach_candidate(node: Node2D) -> bool:
	if node.has_method("break_platform"):
		return true
	if node.get_script() and String(node.get_script().resource_path) == "res://scripts/tiled_body.gd":
		return String(node.get("body_type")) == "platform"
	return false

func _on_attached_broken(_platform: Node2D) -> void:
	_detach_to_falling_saw()

func _on_attached_tree_exiting() -> void:
	_detach_to_falling_saw()

func _detach_to_falling_saw() -> void:
	if _detached:
		return
	_detached = true
	if not is_inside_tree():
		queue_free()
		return
	var tree := get_tree()
	if tree == null:
		queue_free()
		return
	var root := tree.current_scene
	if root == null or falling_saw_scene == null:
		queue_free()
		return
	var falling := falling_saw_scene.instantiate() as Node2D
	if falling == null:
		queue_free()
		return
	root.add_child(falling)
	falling.global_position = global_position
	falling.global_rotation = global_rotation
	if falling.has_method("launch"):
		var speed := randf_range(release_speed_min, release_speed_max)
		var angle := randf_range(-PI * 0.88, -PI * 0.12)
		falling.call("launch", Vector2(cos(angle), sin(angle)) * speed)
	if falling.has_method("get_damage_amount"):
		falling.set("damage", damage)
	queue_free()

func _on_screen_entered() -> void:
	if not _is_on_screen:
		_is_on_screen = true
		var manager := get_tree().root.get_node_or_null("AudioManager")
		if manager and manager.has_method("add_saw_on_screen"):
			manager.call("add_saw_on_screen")

func _on_screen_exited() -> void:
	if _is_on_screen:
		_is_on_screen = false
		var manager := get_tree().root.get_node_or_null("AudioManager")
		if manager and manager.has_method("remove_saw_on_screen"):
			manager.call("remove_saw_on_screen")

func _exit_tree() -> void:
	if _is_on_screen:
		# Use get_node_or_null just in case scene tree is already clearing
		var manager = get_tree().root.get_node_or_null("AudioManager")
		if manager:
			manager.remove_saw_on_screen()
