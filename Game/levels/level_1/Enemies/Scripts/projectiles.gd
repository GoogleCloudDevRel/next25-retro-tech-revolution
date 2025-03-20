extends Area2D

class_name Projectiles

var speed = 300.0
var direction : Vector2
var travelled_distance = 0
var MAX_BULLET_RANGE = 400
var damage = 2
var type #basic type of bullets
var projectile

var rng = RandomNumberGenerator.new()

@onready var type_1 = preload("res://levels/level_1/Player/ui_projectile4.tscn")
@onready var type_2 = preload("res://levels/level_1/Player/ui_projectile5.tscn")

func _ready():
	
	#select the type of floppies
	var random_choice = rng.randi_range(0, 1)
	 
	if random_choice == 0: #3.5 inch floppy
		projectile =  type_1.instantiate()
		MAX_BULLET_RANGE = 700
		speed = 500.0
		damage = 1
	else: # 5.25 inch floppy 
		projectile =  type_2.instantiate()
		MAX_BULLET_RANGE = 400
		speed = 300.0
		damage = 2
	
	add_child(projectile)
	
	
func _physics_process(delta: float) -> void:
	#direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta
	
	travelled_distance += speed * delta
	if travelled_distance > MAX_BULLET_RANGE:
		queue_free()	


	
#we collided with an enemy
func _on_body_entered(body: Node2D) -> void:
	queue_free()
	if body.has_method("_is_moving"):
		body.is_getting_hit(damage)
		
