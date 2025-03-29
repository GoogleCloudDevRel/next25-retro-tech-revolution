extends Area2D

var bullet_1 = preload("res://assets/tools/bullet/Bullet.tscn")
var bullet_2 = preload("res://assets/tools/bullet/Tornado.tscn")
var MAX_NUM_BULLET = 3
var current_num_bullet = MAX_NUM_BULLET
var radius: float = 35.0 
var facing_direction #need to be initialised

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("left", "right")
	input_vector.y = Input.get_axis("up", "down")
	if input_vector != Vector2.ZERO:
		facing_direction = input_vector.normalized()
		var angle_rad = input_vector.angle()
		var angle_deg = rad_to_deg(angle_rad)
		var offset = Vector2(cos(angle_rad), sin(angle_rad)) * radius
		$WeaponPivot/Pistol.global_position = global_position + offset
		#$WeaponPivot/Pistol/ShootingPoint.rotation_degrees = angle_rad

func _physics_process_old(_delta):
	var ennemies_in_range = get_overlapping_bodies()
	if ennemies_in_range.size() > 0:
		var target_enemy = ennemies_in_range[0]
		look_at(target_enemy.global_position)
	
	var nb_round = int(global_rotation_degrees / 360)
	var actual_degrees = global_rotation_degrees - (360 * nb_round)
	if actual_degrees < 0: 
		actual_degrees += 360 
		
	if actual_degrees > 100 and actual_degrees < 270 :
		$WeaponPivot/Pistol.flip_v	= true
		#get_parent().call_deferred("_looking_back","top")
	else:
		#get_parent().call_deferred("_looking_front","top")
		$WeaponPivot/Pistol.flip_v	= false
	###moved to player	
	#if Input.is_action_just_pressed("Fire"):	
	#	shoot()
	#	if actual_degrees > 100 and actual_degrees < 270 :
	#		get_parent().call_deferred("_fire_looking_back","top")
	#	else:
	#		get_parent().call_deferred("_fire_looking_front","top")
		
func shoot(current_weapon):
	if current_weapon  == "blaster":
		if current_num_bullet > 0:
			var b = bullet_1.instantiate()
			b.direction = facing_direction
			b.set_shooting_point($WeaponPivot/Pistol/ShootingPoint)
			SignalBus.bullet_created.emit(b)
			current_num_bullet -= 1
	else: #gauntlet
			var b = bullet_2.instantiate()
			b.direction = facing_direction
			b.set_shooting_point($WeaponPivot/Pistol/ShootingPoint)
			SignalBus.bullet_created.emit(b)
			current_num_bullet -= 1
		

#cool down
func _on_timer_timeout() -> void:
	current_num_bullet = MAX_NUM_BULLET
	#if Input.is_action_just_pressed("Fire"):
		#shoot()
