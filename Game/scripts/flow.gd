extends Bullet

var angle = 90 
var wave_radius = 50 
var wave_speed = 15

var velocity: Vector2 
var bullet_position: Vector2 
var time_flying = 0

func _ready():
	MAX_BULLET_RANGE = 800
	damage = 10
	speed = 70
	type = "flow"
	bullet_position = position
	velocity = Vector2(speed, 0).rotated(deg_to_rad(angle))

func _physics_process(delta: float) -> void:
	velocity = Vector2.RIGHT.rotated(rotation)
	
	time_flying += delta 
	bullet_position += velocity * speed * delta
	var wave_vector = ( 
		velocity.normalized().orthogonal() * sin(time_flying * wave_speed) * wave_radius 
	) 
	position = bullet_position + wave_vector

	travelled_distance += speed * delta
	if travelled_distance > MAX_BULLET_RANGE:
		queue_free()	

#set initial position
#func set_shooting_point(p):
#	global_position = p.global_position
#	global_rotation = p.global_rotation

#func _on_body_entered(body: Node2D) -> void:
#	queue_free()
#	if body.has_method("take_damage"):
#		body.take_damage(10)
		
