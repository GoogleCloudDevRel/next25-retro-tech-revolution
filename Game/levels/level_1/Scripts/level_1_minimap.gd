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
var circle_position = Vector2(-357,47)

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
		player = p

func _on_enemy_created(e):
	enemies.append(e)


func _draw():
	var map_scale = Vector2(mini_map_size.x/ world_width, mini_map_size.y/world_height) 
	var map_radius = visibility_radius * 0.21 #* map_scale.x
	$Background.on_draw_circle(circle_position, map_radius)
	
func _process(delta):
	update_mini_map()
	queue_redraw()
	
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
		visibility_radius = 500.0
	elif SignalBus.game_difficulty == SignalBus.MEDIUM:
		visibility_radius = 350.0
	else:
		visibility_radius = 200.0
	for n in $Background.get_children():
		$Background.remove_child(n)
		n.queue_free()
	
	#draw_distance_circle(visibility_radius)
	if player != null: 
		draw_on_mini_map(player, "player")
	if boss != null: 
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


func draw_on_mini_map(elt, type):
			if type=="player" or (type=="item" and (SignalBus.game_difficulty == SignalBus.EASY or SignalBus.game_difficulty == SignalBus.MEDIUM)) or ((type == "boss" or type == "enemy") and distance_to_player(elt) <= visibility_radius):
				var new_marker = TextureRect.new()
				new_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				var pointer_size = 15
				match type:
					"player":
						new_marker.texture = load("res://assets/minimap/marker_player.png")
						circle_position = world_to_map(elt.global_position)
					"enemy":
						new_marker.texture = load("res://assets/minimap/marker_enemy.png")
					"item":
						new_marker.texture = load("res://assets/minimap/marker_item.png")
					"boss":
						new_marker.texture = load("res://assets/minimap/marker_boss.png")
				new_marker.pivot_offset = Vector2(pointer_size/2, pointer_size/2)
				new_marker.size = Vector2(pointer_size, pointer_size)
				$Background.add_child(new_marker)
				new_marker.position = world_to_map(elt.global_position)
			
				

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
