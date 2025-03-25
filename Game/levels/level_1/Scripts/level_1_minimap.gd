extends Control

# References
@export var player: Node2D  # Your player node
@export var mini_map_size: Vector2 = Vector2(331.5, 279)  # Size of your mini map UI element
@export var view_radius: float = 500.0  # How much world space to show (radius from player)
@export var enemy_icon: Texture2D  # Texture for enemy markers
@export var player_icon: Texture2D  # Texture for player marker
@export var view_offset: Vector2 = Vector2(100, 380)  # Offset the center of the map from the player

# Optional - to control which areas to show
@export var map_bounds: Rect2 = Rect2(0, 0, 2440, 3000)  # Total world bounds
@export var show_bounds: bool = false  # Whether to show world boundary on minimap

######
@export var mini_map_width: float = 663-40
@export var mini_map_height: float = 558-40

# World coordinates range
var world_min_x: float = -544
var world_max_x: float = 2464
var world_min_y: float = -1664
var world_max_y: float = 688

# World dimensions
var world_width: float = 3008  # 2464 - (-544) = 3008
var world_height: float = 2352  # 688 - (-1664) = 2352

var visibility_radius:float = 350.0
########


# Array to store enemy marker nodes
var player_markers = []
var enemy_markers = []
var enemies = []
var items=[]
var boss


func _ready():
	# Set up the mini map size
	$Background.size = mini_map_size
	player_icon =  preload("res://assets/map/player.png")
	enemy_icon  = preload("res://assets/map/enemies.png")
	SignalBus.weapon_created.connect(_on_weapon_created)
	SignalBus.player_created.connect(_on_player_created)
	SignalBus.enemy_created.connect(_on_enemy_created)
	SignalBus.boss_created.connect(_on_boss_created)

func _on_boss_created(b):
	boss = b

func _on_weapon_created(w):
		items.append(w)

func _on_player_created(p):
		#print("------player created on mini map -------")
		player = p

func _on_enemy_created(e):
	enemies.append(e)
	#register_enemies()
	
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

func update_mini_map():
	#difficulty
	if SignalBus.game_difficulty == SignalBus.EASY:
		visibility_radius = 2000.0
	elif SignalBus.game_difficulty == SignalBus.MEDIUM:
		visibility_radius = 350.0
	else:
		visibility_radius = 200.0
	
	
	for n in $Background.get_children():
		$Background.remove_child(n)
		n.queue_free()
	draw_distance_circle(visibility_radius)
	if player != null: 
		draw_on_mini_map(player, "player")
	if boss != null: 
		print("has boss")
		draw_on_mini_map(boss, "boss")
	
	if enemies.size()> 0:
		for enemy in enemies:
			draw_on_mini_map(enemy, "enemy")
	
	if items.size()> 0:
		for item in items:
			draw_on_mini_map(item, "item")

# Calculate distance between player and another entity
func distance_to_player(entity: Node2D) -> float:
	if player and entity:
		return player.global_position.distance_to(entity.global_position)
	return 0.0

func draw_distance_circle(radius: float):
	var circle 
	if not $minimap/DistanceCircle:
		circle = Line2D.new()
		circle.name = "DistanceCircle"
		circle.width = 1.0
		circle.default_color = Color(1, 1, 1, 0.3)
		$Background.add_child(circle)
	else:
		circle = $minimap/DistanceCircle
	# Clear previous points
	circle.clear_points()
	
	# Calculate map radius
	var map_radius = radius / (world_width / mini_map_width)# Using X scale for simplicity
	
	# Draw circle with 32 segments
	var segments = 32
	var player_map_pos = world_to_map(player.global_position)
	
	for i in range(segments + 1):
		var angle = 2 * PI * i / segments
		var x = player_map_pos.x + cos(angle) * map_radius
		var y = player_map_pos.y + sin(angle) * map_radius
		circle.add_point(Vector2(x, y))

func draw_on_mini_map(elt, type):
			if type=="player" or (type=="item" and (SignalBus.game_difficulty == SignalBus.EASY or SignalBus.game_difficulty == SignalBus.MEDIUM)) or ((type == "boss" or type == "enemy") and distance_to_player(elt) < visibility_radius):
				var new_marker = TextureRect.new()
				new_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				var pointer_size = 35
				match type:
					"player":
						new_marker.texture = load("res://assets/map/player.png")
						#$MapBackground.material.set_shader_parameter("player_position",Vector2(map_position_x, map_position_y))
					"enemy":
						new_marker.texture = load("res://assets/map/enemies.png")
					"item":
						new_marker.texture = load("res://assets/map/item.png")
					"boss":
						new_marker.texture = load("res://assets/map/boss.png")
				
				new_marker.pivot_offset = Vector2(pointer_size/2, pointer_size/2)
				new_marker.size = Vector2(pointer_size, pointer_size)
				$Background.add_child(new_marker)
				new_marker.position = world_to_map(elt.global_position)
			
	

func draw_on_mini_map_old(elt, type):
				var map_padding = 0
				var mini_map_width = 635-20 #($Background.size.x-(20))
				var mini_map_height = 530 -20#($Background.size.y-(20))
				
				var world_bounds: Rect2 = Rect2(Vector2(-544, -1664), Vector2(2464, 688))
				var effective_map_width = mini_map_width * (1.0 - map_padding * 2)
				var 	effective_map_height = mini_map_height * (1.0 - map_padding * 2)
				var scale_x = effective_map_width / world_bounds.size.x
				var scale_y = effective_map_height / world_bounds.size.y
				
				var scale_factor = min(scale_x, scale_y)
				
				var player_offset_x = (mini_map_width / 2) - (world_bounds.position.x + world_bounds.size.x / 2) * scale_factor
				var player_offset_y = (mini_map_height / 2) - (world_bounds.position.y + world_bounds.size.y / 2) * scale_factor
					
				
				var elt_pos = elt.position
				var percent_x = elt_pos.x / (2454+view_offset.x) #devide by mapsize
				var percent_y = elt_pos.y / (1654+view_offset.y)
				
				var pointer_size = 35
				
				var image_map_size_x = 635-20 #($Background.size.x-(20))
				var image_map_size_y = 530 -20#($Background.size.y-(20))
				
				var map_position_x = view_offset.x + (image_map_size_x * percent_x) - (pointer_size/2)
				var map_position_y = view_offset.y + (image_map_size_y * percent_y) - (pointer_size/2)
				
				#$MapBackground.material.set_shader_parameter("player_position",Vector2(image_map_size_x, image_map_size_y))
				
				
				var my_texture = TextureRect.new()
				my_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				
				match type:
					"player":
						my_texture.texture = load("res://assets/map/player.png")
						#$MapBackground.material.set_shader_parameter("player_position",Vector2(map_position_x, map_position_y))
					"enemy":
						my_texture.texture = load("res://assets/map/enemies.png")
				#	"item":
				#		my_texture.texture = load("res://assets/map/item.png")
				#	"boss":
				#		my_texture.texture = load("res://assets/map/boss.png")
				
				
				var elt_rotation = rad_to_deg(elt.rotation) #enemy.rotation_degree.y
				
				my_texture.pivot_offset = Vector2(pointer_size/2, pointer_size/2)
				my_texture.size = Vector2(pointer_size, pointer_size)
				my_texture.rotation_degrees = (elt_rotation)
				#print(elt_rotation)
				$Background.add_child(my_texture)
				my_texture.position = Vector2(map_position_x, map_position_y)
				print("bg"+str($Background.size.x)+",Global pos x:"+str(elt.position.x)+",y:"+str(elt.position.y)+", map pos"+str(map_position_x)+", y:"+str(map_position_y))


# Convert world coordinates to mini map coordinates
func world_to_map(world_pos: Vector2) -> Vector2:
	# Convert world position to normalized position (0.0 to 1.0)
	var normalized_x = (world_pos.x - world_min_x) / world_width
	var normalized_y = (world_pos.y - world_min_y) / world_height
	
	# Convert normalized position to mini map pixels
	var map_x = normalized_x * mini_map_width
	var map_y = normalized_y * mini_map_height
	
	# Optional: Clamp to mini map boundaries
	map_x = clamp(map_x, 0, mini_map_width)
	map_y = clamp(map_y, 0, mini_map_height)
	return Vector2(map_x, map_y)




func calculate_map_scale():
	# Calculate how many pixels per world unit
	# For a partial map, we use the view radius to determine scale
	return mini_map_size.x / (view_radius * 2)
		
func update_mini_map_v2():
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
