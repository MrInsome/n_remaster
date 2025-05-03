extends Camera2D

# Custom smoothing speed for camera movement (0 - instant, higher - faster)
@export var smoothing_speed: float = 5.0

# Enable manual limits override; if false, limits are auto-calculated from TileMapPlatforms
@export var use_manual_limits: bool = false

func _ready() -> void:
	# Enable built-in position smoothing
	position_smoothing_enabled = true
	position_smoothing_speed = smoothing_speed

	# Auto-calculate camera limits if manual override is not used
	if not use_manual_limits:
		_set_limits_from_tilemap()

func _process(delta: float) -> void:
	# Gather all player nodes in group "players"
	var players: Array = []
	for p in get_tree().get_nodes_in_group("players"):
		if p is Node2D:
			players.append(p)

	# If no players found, exit
	if players.size() == 0:
		return

	# Compute the average position of all players
	var target: Vector2 = Vector2.ZERO
	for p in players:
		target += p.global_position
	target /= players.size()

	# Smoothly interpolate camera position toward target using lerp
	global_position = lerp(global_position, target, smoothing_speed * delta)

	# Apply camera boundaries
	_apply_limits()

	# Clamp players within camera view
	_clamp_players_to_view()

func _set_limits_from_tilemap() -> void:
	# Find the TileMap named "TileMapPlatforms" in the parent node
	var tm = get_parent().get_node_or_null("TileMapPlatforms") as TileMap
	if tm:
		var used = tm.get_used_rect()
		var top_left = tm.map_to_world(used.position)
		var bottom_right = tm.map_to_world(used.position + used.size)

		# Assign built-in limit properties
		limit_left   = top_left.x
		limit_top    = top_left.y
		limit_right  = bottom_right.x
		limit_bottom = bottom_right.y

func _apply_limits() -> void:
	global_position.x = clamp(global_position.x, limit_left, limit_right)
	global_position.y = clamp(global_position.y, limit_top,  limit_bottom)

func _clamp_players_to_view() -> void:
	# Calculate the half-size of the camera view in world coordinates
	var view_size = get_viewport_rect().size * zoom
	var half_size = view_size * 0.5
	var min_bound = global_position - half_size
	var max_bound = global_position + half_size

	# Clamp each player position to within the camera view
	for p in get_tree().get_nodes_in_group("players"):
		if p is Node2D:
			var pos = p.global_position
			pos.x = clamp(pos.x, min_bound.x, max_bound.x)
			pos.y = clamp(pos.y, min_bound.y, max_bound.y)
			p.global_position = pos
