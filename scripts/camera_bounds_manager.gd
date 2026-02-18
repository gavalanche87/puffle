extends Node
class_name CameraBoundsManager

## Automatically configures camera bounds based on level geometry
## Reusable across all levels - no hardcoded values

func _current_scene_root() -> Node:
	var tree := get_tree()
	if tree and tree.current_scene:
		return tree.current_scene
	return get_tree().root

func _is_in_current_scene(node: Node) -> bool:
	var root := _current_scene_root()
	return node != null and root != null and (node == root or root.is_ancestor_of(node))

## Finds the leftmost wall in the level
func _find_leftmost_wall() -> Node2D:
	var walls = get_tree().get_nodes_in_group("level_boundary_left")
	var scene_walls: Array = []
	for wall in walls:
		if wall is Node2D and _is_in_current_scene(wall):
			scene_walls.append(wall)
	if not scene_walls.is_empty():
		return scene_walls[0]
	
	# Fallback: find all Wall nodes and return leftmost
	var all_walls = []
	_find_nodes_by_script(_current_scene_root(), "res://scripts/tiled_body.gd", all_walls)
	
	var leftmost: Node2D = null
	var leftmost_x = INF
	for wall in all_walls:
		if wall.get("body_type") == "wall":
			if wall.global_position.x < leftmost_x:
				leftmost_x = wall.global_position.x
				leftmost = wall
	return leftmost

## Finds the rightmost wall in the level
func _find_rightmost_wall() -> Node2D:
	var walls = get_tree().get_nodes_in_group("level_boundary_right")
	var scene_walls: Array = []
	for wall in walls:
		if wall is Node2D and _is_in_current_scene(wall):
			scene_walls.append(wall)
	if not scene_walls.is_empty():
		return scene_walls[0]
	
	# Fallback: find all Wall nodes and return rightmost
	var all_walls = []
	_find_nodes_by_script(_current_scene_root(), "res://scripts/tiled_body.gd", all_walls)
	
	var rightmost: Node2D = null
	var rightmost_x = - INF
	for wall in all_walls:
		if wall.get("body_type") == "wall":
			if wall.global_position.x > rightmost_x:
				rightmost_x = wall.global_position.x
				rightmost = wall
	return rightmost

## Finds the lowest ground in the level
func _find_lowest_ground() -> Node2D:
	var grounds = get_tree().get_nodes_in_group("level_boundary_bottom")
	var scene_grounds: Array = []
	for ground in grounds:
		if ground is Node2D and _is_in_current_scene(ground):
			scene_grounds.append(ground)
	if not scene_grounds.is_empty():
		# Return the lowest one if multiple
		var lowest_ground: Node2D = scene_grounds[0]
		var lowest_ground_y = scene_grounds[0].global_position.y
		for ground in scene_grounds:
			if ground.global_position.y > lowest_ground_y:
				lowest_ground_y = ground.global_position.y
				lowest_ground = ground
		return lowest_ground
	
	# Fallback: find all Ground nodes and return lowest
	var all_grounds = []
	_find_nodes_by_script(_current_scene_root(), "res://scripts/tiled_body.gd", all_grounds)
	
	var lowest: Node2D = null
	var lowest_y = - INF
	for ground in all_grounds:
		if ground.get("body_type") == "ground":
			if ground.global_position.y > lowest_y:
				lowest_y = ground.global_position.y
				lowest = ground
	return lowest

## Helper to find nodes with a specific script
func _find_nodes_by_script(node: Node, script_path: String, result: Array) -> void:
	if node.get_script() and node.get_script().resource_path == script_path:
		result.append(node)
	for child in node.get_children():
		_find_nodes_by_script(child, script_path, result)

## Gets the right edge of a tiled body (wall or ground)
func _get_right_edge(body: Node2D) -> float:
	var bounds := _get_body_world_bounds(body)
	if bounds.size != Vector2.ZERO:
		return bounds.end.x
	var width := 32.0 # Fallback tile size
	return body.global_position.x + (width / 2.0)

## Gets the left edge of a tiled body
func _get_left_edge(body: Node2D) -> float:
	var bounds := _get_body_world_bounds(body)
	if bounds.size != Vector2.ZERO:
		return bounds.position.x
	var width := 32.0 # Fallback tile size
	return body.global_position.x - (width / 2.0)

## Gets the top edge of a tiled body
func _get_top_edge(body: Node2D) -> float:
	var bounds := _get_body_world_bounds(body)
	if bounds.size != Vector2.ZERO:
		return bounds.position.y
	var height := 32.0 # Fallback tile size
	return body.global_position.y - (height / 2.0)

## Gets world-space bounds from a tiled body's CollisionShape2D (supports offsets/scales)
func _get_body_world_bounds(body: Node2D) -> Rect2:
	var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null:
		return Rect2()
	if collision.shape is RectangleShape2D:
		var rect_shape := collision.shape as RectangleShape2D
		var half := rect_shape.size * 0.5
		var xf := collision.global_transform
		var p0 := xf * Vector2(-half.x, -half.y)
		var p1 := xf * Vector2(half.x, -half.y)
		var p2 := xf * Vector2(half.x, half.y)
		var p3 := xf * Vector2(-half.x, half.y)
		var min_x := minf(minf(p0.x, p1.x), minf(p2.x, p3.x))
		var max_x := maxf(maxf(p0.x, p1.x), maxf(p2.x, p3.x))
		var min_y := minf(minf(p0.y, p1.y), minf(p2.y, p3.y))
		var max_y := maxf(maxf(p0.y, p1.y), maxf(p2.y, p3.y))
		return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	return Rect2()

## Main function to setup camera bounds
func setup_camera_bounds(camera: Camera2D, player: Node2D = null) -> void:
	if not camera:
		push_warning("CameraBoundsManager: No camera provided")
		return
	
	# Get viewport size dynamically
	var viewport = get_viewport()
	if not viewport:
		push_warning("CameraBoundsManager: No viewport found")
		return
	
	var viewport_size = viewport.get_visible_rect().size
	var zoom = camera.zoom.x # Assuming uniform zoom
	
	if player:
		print("  Player position: %v" % [player.global_position])
	
	# Find level boundaries
	var left_wall = _find_leftmost_wall()
	var right_wall = _find_rightmost_wall()
	var bottom_ground = _find_lowest_ground()
	
	# Calculate and set camera limits
	# Godot's camera limits work in screen space - just set them to the sprite edges
	
	if left_wall:
		var wall_left = _get_left_edge(left_wall)
		var wall_right = _get_right_edge(left_wall)
		camera.limit_left = int(wall_left)
		print("  Left Wall: pos=%v, left_edge=%.1f, right_edge=%.1f, limit_left=%d" %
			[left_wall.global_position, wall_left, wall_right, camera.limit_left])
	else:
		push_warning("CameraBoundsManager: No left wall found")
	
	if right_wall:
		var wall_left = _get_left_edge(right_wall)
		var wall_right = _get_right_edge(right_wall)
		camera.limit_right = int(wall_right)
		print("  Right Wall: pos=%v, left_edge=%.1f, right_edge=%.1f, limit_right=%d" %
			[right_wall.global_position, wall_left, wall_right, camera.limit_right])
	else:
		push_warning("CameraBoundsManager: No right wall found")
	
	if bottom_ground:
		var ground_bounds := _get_body_world_bounds(bottom_ground)
		var ground_bottom: float = ground_bounds.end.y if ground_bounds.size != Vector2.ZERO else (bottom_ground.global_position.y + 16.0)
		camera.limit_bottom = int(ground_bottom)
		print("  Bottom Ground: pos=%v, bottom_edge=%.1f, limit_bottom=%d" %
			[bottom_ground.global_position, ground_bottom, camera.limit_bottom])
	else:
		push_warning("CameraBoundsManager: No bottom ground found")
	
	# Set reasonable top limit (allow upward movement)
	camera.limit_top = -10000
	
	print("CameraBoundsManager: Bounds set - Left: %d, Right: %d, Bottom: %d, Top: %d" %
		[camera.limit_left, camera.limit_right, camera.limit_bottom, camera.limit_top])
	print("  Viewport: %v, Zoom: %.3f" %
		[viewport_size, zoom])
