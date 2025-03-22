extends Control

# References
@export var player: Node2D  # Your player node
@export var mini_map_size: Vector2 = Vector2(200, 200)  # Size of your mini map UI element
@export var view_radius: float = 500.0  # How much world space to show (radius from player)
@export var enemy_icon: Texture2D  # Texture for enemy markers
@export var player_icon: Texture2D  # Texture for player marker
@export var view_offset: Vector2 = Vector2.ZERO  # Offset the center of the map from the player

# Optional - to control which areas to show
@export var map_bounds: Rect2 = Rect2(0, 0, 2000, 2000)  # Total world bounds
@export var show_bounds: bool = false  # Whether to show world boundary on minimap

# Array to store enemy marker nodes
var enemy_markers = []
var enemies = []


func _ready():
	# Set up the mini map size
	$Background.size = mini_map_size
	
	SignalBus.player_created.connect(_on_player_created)
	SignalBus.enemy_created.connect(_on_enemy_created)
	

func _on_player_created(p):
		print("------player created on mini map -------")
		var player_marker = TextureRect.new()
		player_marker.texture = player_icon
		player_marker.size = Vector2(14, 14)  # Size of player icon
		player_marker.position = Vector2(-7, -7)  # Center the icon
		player_marker.name = "PlayerMarker"
		$Background.add_child(player_marker)

func _on_enemy_created(e):
	enemies.append(e)
	register_enemies()
	

func _process(delta):
	update_mini_map()
	
func register_enemies():
	# Clear existing markers
	for marker in enemy_markers:
		marker.queue_free()
	enemy_markers.clear()
	
	# Get all enemies in the scene
	#var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Create markers for each enemy
	for enemy in enemies:
		var marker = TextureRect.new()
		marker.texture = enemy_icon
		marker.size = Vector2(10, 10)  # Size of the enemy icon
		marker.position = Vector2(-5, -5)  # Center the icon
		
		# Store reference to the enemy with the marker
		marker.set_meta("enemy", enemy)
		
		# Add to the mini map
		$Background.add_child(marker)
		enemy_markers.append(marker)

func calculate_map_scale():
	# Calculate how many pixels per world unit
	# For a partial map, we use the view radius to determine scale
	return mini_map_size.x / (view_radius * 2)
		
func update_mini_map():
	if not player:
		return
	
	var map_scale = calculate_map_scale()
	var map_center = mini_map_size / 2
	
	# Update player position (always centered by default, but can be offset)
	$PlayerMarker.position = map_center + (view_offset * map_scale)
	
	# Update all enemy positions
	for marker in enemy_markers:
		var enemy = marker.get_meta("enemy")
		if is_instance_valid(enemy):
			# Get relative position to player
			var relative_pos = enemy.global_position - player.global_position
			
			# Convert world position to mini map position using the calculated scale
			var map_pos = map_center + (relative_pos * map_scale) + (view_offset * map_scale)
			
			# Check if the enemy is within our view radius
			if relative_pos.length() <= view_radius:
				marker.visible = true
				marker.position = map_pos
			else:
				# Option 1: Hide enemies outside the mini map view
				marker.visible = false
				
				# Option 2: Show markers at the edge of the minimap pointing toward distant enemies
				# Uncomment these lines if you want this behavior
				#var dir = relative_pos.normalized()
				#var edge_pos = map_center + dir * (mini_map_size.x / 2)
				#marker.visible = true
				#marker.position = edge_pos
				#marker.rotation = dir.angle() + PI/2
		else:
			# Enemy no longer exists, remove the marker
			marker.queue_free()
			enemy_markers.erase(marker)

# Optional function to draw world bounds on minimap
func _draw():
	if show_bounds:
		var map_scale = calculate_map_scale()
		var map_center = mini_map_size / 2
		
		# Calculate where the world bounds appear on the minimap
		var player_world_pos = player.global_position
		var min_corner = map_center + ((map_bounds.position - player_world_pos) * map_scale)
		var max_corner = map_center + ((map_bounds.end - player_world_pos) * map_scale)
		
		# Draw a rectangle representing the world bounds
		draw_rect(Rect2(min_corner, max_corner - min_corner), Color(1, 1, 1, 0.2), false)

# Call this to change the view radius (zoom level) of the mini map
func set_view_radius(new_radius):
	view_radius = new_radius
	# Optional: Clamp to reasonable limits
	view_radius = clamp(view_radius, 100, 2000)

# Call this to pan the mini map view
func set_view_offset(new_offset):
	view_offset = new_offset
	# Optional: Clamp to prevent too much offset
	view_offset = view_offset.clamp(Vector2(-view_radius, -view_radius), Vector2(view_radius, view_radius))
