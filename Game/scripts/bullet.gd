extends Area2D

class_name Bullet

var speed = 300.0
var direction : Vector2
var travelled_distance = 0
var MAX_BULLET_RANGE = 400
var damage = 5
var type #basic type of bullets

func _ready():
	type = "basic"
	rotation = direction.angle()
	
func _physics_process(delta: float) -> void:
	#direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta
	
	travelled_distance += speed * delta
	if travelled_distance > MAX_BULLET_RANGE:
		queue_free()	

#set initial position
func set_shooting_point(p):
	global_position = p.global_position
	#global_rotation = p.global_rotation
	
#we collided with an enemy
func _on_body_entered(body: Node2D) -> void:
	queue_free()
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
