extends CharacterBody2D
class_name Player_v0

signal health_depleted

@onready var hurtbox = $HurtBox

var strength = 50
var speed = 800
var health = 100.0
const DAMAGE_RATE = 10.0
var friction = 0.18
var hit_count = 0
var x = 0
var y = 0
var counter = 0

var can_call_gemini = false #call gemini only if we haven t called it within the last 1min

#network id
@export var player_id := 1:
	set(id):
		player_id = id

func _ready():
	name = str(get_multiplayer_authority())

	#$Name.text = str(name)


func _physics_process(delta):
		#if is_multiplayer_authority():
		var direction = Input.get_vector("left","right","up","down")
		$AnimatedPlayer/healthDepletion.play("player_animation")
		#move
		velocity = direction * speed
		#var direction:Vector2 = Vector2.ZERO
		
		# Notify the movement
		_is_moving()	
	
		
		#if direction.length() > 1.0:
		#	direction = direction.normalized()
		#var target_velocity = direction * speed
		#velocity += (target_velocity - velocity) * friction
			
		
		#velocity = move_and_slide(velocity)
		#if Input.is_action_just_pressed("Fire"):
		
		#### are we firing ?
		var nb_round = int(global_rotation_degrees / 360)
		var actual_degrees = global_rotation_degrees - (360 * nb_round)
		
		if Input.is_action_just_pressed("attack"):	
			$Gun.shoot()
			if actual_degrees > 100 and actual_degrees < 270 :
				call_deferred("_fire_looking_back","top")
			else:
				call_deferred("_fire_looking_front","top")
		
		#####are we getting damages ?
		var overlapping_enemies = hurtbox.get_overlapping_bodies()
		if overlapping_enemies.size() > 0:
			if counter > 30:# wait 30 frames 
				for i in overlapping_enemies.size():
					if overlapping_enemies[i].has_method("take_damage"):
						#SignalBus.player_taking_damage.emit(self, overlapping_enemies[i])
						call_gemini_help()
						hit_count += 1
						print("getting hit"+ str(health) + " "+ str(overlapping_enemies[i].damage_points))
						health -=	overlapping_enemies[i].damage_points
						$AnimatedPlayer/healthDepletion.play("depleting")
						$HealthBar.value = health
						counter = 0
						
			else:
				counter += 1 + delta
		else: #reset counter if no overlap
			counter = 0
			
		#check if we are dead	
		if health <= 0:			
			SignalBus.player_health_depleted.emit(self)
		
		#print("x" + str(direction.x))
		#move left
		if velocity.length() > 0.0:
			#$hero.play_walk_animation()
			$AnimatedPlayer.play("walking")
		else: #player is idle
			$AnimatedPlayer.play("idle")
			SignalBus.player_iddle.emit(self) #iddle event
			call_gemini_help() #ask for help from gemini
			
		
		#print("flip_status1:" + str($AnimatedPlayer.flip_h))
		if direction.x < 0: #leftw
			#print("flip f")
			$AnimatedPlayer.flip_h = true
			#print("flip_status2:" + str($AnimatedPlayer.flip_h))
		if direction.x > 0: #right
			#print("flip t")
			$AnimatedPlayer.flip_h = false
			#print("flip_status2:" + str($AnimatedPlayer.flip_h))
		move_and_slide()

func _is_moving() -> void:
		var left_stick_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var left_stick_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		
		# Apply deadzone to avoid detecting tiny movements
		if abs(left_stick_x) < 0.5:
			left_stick_x = 0
		if abs(left_stick_y) < 0.5:
			left_stick_y = 0
			
		# Use the values (for example, to move a character)
		if left_stick_x != 0 or left_stick_y != 0:
			SignalBus.player_moving.emit(self, left_stick_x, left_stick_y)
			print("Left stick position: ", Vector2(left_stick_x, left_stick_y))

func _fire_looking_front(_direction) -> void:
	pass
	#$AnimatedPlayer.flip_h = true
	#$AnimatedPlayer.play("shooting")
	#$AnimatedPlayer.frame = 0	

func _fire_looking_back(_direction) -> void:
	pass
	#$AnimatedPlayer.flip_h = true
	#$AnimatedPlayer.play("shooting")
	#$AnimatedPlayer.frame = 1

#@rpc("unreliable")
#func remote_set_position(authority_velocity,authority_position, authority_health):
#	velocity = authority_velocity
#	global_position = authority_position
#	health = authority_health

func call_gemini_help():
	if health > 20 and health < 70 and can_call_gemini:
					#if counter_before_gemini_help >0:
					#		counter_before_gemini_help -= 1
					#else:
					#		counter_before_gemini_help = 20
					SignalBus.gemini_help_requested.emit()
					$CallGeminiTimer.start()
					can_call_gemini = false

func _on_call_gemini_timer_timeout() -> void:
	can_call_gemini = true
