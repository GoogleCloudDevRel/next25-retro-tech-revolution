extends TextureRect

var map_radius
var circle_position

func _draw():
	#var map_scale = Vector2(mini_map_size.x/ world_width, mini_map_size.y/world_height) 
	#var map_radius = visibility_radius * map_scale.x
	draw_arc(circle_position, map_radius, 0, TAU, 32, Color.RED, 2.0) #ratio is 6
	#print(circle_position)
	
	
func on_draw_circle(cp, mr):
	map_radius = mr
	circle_position = cp
	queue_redraw()
