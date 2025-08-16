extends Bullet

var pivot = Vector2(1, 2)
var angle = 0
var linear_speed = 400 
var radius = 70 
var radius_speed = 10
var ShootingPoint

func _ready():
	type = "tornado"
	MAX_BULLET_RANGE = 4000
	damage = 2

func _physics_process(delta: float) -> void:
	
	travelled_distance += linear_speed * delta
	radius += radius_speed * delta
	var angular_speed = linear_speed / radius
	angle += angular_speed * delta
	position =  ShootingPoint.global_position + Vector2(radius, 0).rotated(angle)
	
	if travelled_distance > MAX_BULLET_RANGE:
		queue_free()	

func set_shooting_point(p):
	ShootingPoint = p
	global_position = p.global_position
	global_rotation = p.global_rotation
	
#we collided with an enemy
#func _on_body_entered(body: Node2D) -> void:
#	queue_free()
#	if body.has_method("take_damage"):
#		body.take_damage(20)
		
