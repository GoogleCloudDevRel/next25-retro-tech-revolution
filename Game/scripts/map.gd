extends CanvasLayer

@onready var enemies = get_parent().get_node("Enemies")
@onready var gameManager = get_parent()	

var worldsize = Vector2()
var player
var has_player = false
var counter = 0
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	SignalBus.player_created.connect(_on_player_created)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#limit how frequently we refresh the map
	if counter == 60 :
		#display_enemies()
		counter = 0
	else:
		counter+=1

#remove all objects from the map
func clean_map():
		var children = $MapBackground.get_children()
		for child in children:
			child.free()	
		
#show on map
func show_on_map(elt, type):
	if elt.visible == true and has_player and player.global_position.distance_to(elt.global_position) < 1000:

				var elt_pos = elt.position
				var percent_x = elt_pos.x / 20000 #devide by mapsize
				var percent_y = elt_pos.y / 20000
				
				var pointer_size = 35
				
				var image_map_size_x = $MapBackground.size.x
				var image_map_size_y = $MapBackground.size.y
				
				var map_position_x = (image_map_size_x * percent_x) - (pointer_size/2)
				var map_position_y = (image_map_size_y * percent_y) - (pointer_size/2)
				
				#$MapBackground.material.set_shader_parameter("player_position",Vector2(image_map_size_x, image_map_size_y))
				
				
				var my_texture = TextureRect.new()
				my_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				
				match type:
					"player":
						my_texture.texture = load("res://assets/map/player.png")
						$MapBackground.material.set_shader_parameter("player_position",Vector2(map_position_x, map_position_y))
					"enemy":
						my_texture.texture = load("res://assets/map/enemies.png")
					"item":
						my_texture.texture = load("res://assets/map/item.png")
					"boss":
						my_texture.texture = load("res://assets/map/boss.png")
				
				
				var elt_rotation = rad_to_deg(elt.rotation) #enemy.rotation_degree.y
				
				my_texture.pivot_offset = Vector2(pointer_size/2, pointer_size/2)
				my_texture.size = Vector2(pointer_size, pointer_size)
				my_texture.rotation_degrees = (elt_rotation)
				#print(elt_rotation)
				$MapBackground.add_child(my_texture)
				my_texture.position = Vector2(map_position_x, map_position_y)
				
				
func _on_player_created(p):	
	has_player = true
	player = %Player
	print("found")
					
				
				
		
	
func display_enemies():
	clean_map()
	
	#for player in gameManager.players:
	#		if player.visible == true:
	show_on_map(player, "player")
	
	for enemy in gameManager.enemies:
			if enemy.visible == true:
				show_on_map(enemy, "enemy")
			
			
		
#show enemies on the map
func display_enemies_old():
		
		for enemy in gameManager.get_enemies():
			if enemy.visible == true:
				var enemy_pos = enemy.position
				var percent_x = enemy_pos.x / 13000 #devide by mapsize
				var percent_y = enemy_pos.y / 13000
				
				var pointer_size = 35
				
				var image_map_size_x = $MapBackground.size.x
				var image_map_size_y = $MapBackground.size.y
				
				var map_position_x = (image_map_size_x * percent_x) - (pointer_size/2)
				var map_position_y = (image_map_size_y * percent_y) - (pointer_size/2)
				
				var my_texture = TextureRect.new()
				my_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				
				my_texture.texture = load("res://assets/map/enemies.png")
				
				var enemy_rotation = rad_to_deg(enemy.rotation) #enemy.rotation_degree.y
				
				my_texture.pivot_offset = Vector2(pointer_size/2, pointer_size/2)
				my_texture.size = Vector2(pointer_size, pointer_size)
				my_texture.rotation_degrees = (enemy_rotation)
				print(enemy_rotation)
				$MapBackground.add_child(my_texture)
				my_texture.position = Vector2(map_position_x, map_position_y)
		
