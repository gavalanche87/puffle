extends Area2D

@export var damage: int = 20
@export var rotation_speed_degrees: float = 300.0

var _is_on_screen: bool = false
var _notifier: VisibleOnScreenNotifier2D

func _ready() -> void:
	add_to_group("hazards")
	
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

func _on_screen_entered() -> void:
	if not _is_on_screen:
		_is_on_screen = true
		get_tree().root.get_node("AudioManager").add_saw_on_screen()

func _on_screen_exited() -> void:
	if _is_on_screen:
		_is_on_screen = false
		get_tree().root.get_node("AudioManager").remove_saw_on_screen()

func _exit_tree() -> void:
	if _is_on_screen:
		# Use get_node_or_null just in case scene tree is already clearing
		var manager = get_tree().root.get_node_or_null("AudioManager")
		if manager:
			manager.remove_saw_on_screen()
