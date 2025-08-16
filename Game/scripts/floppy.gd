extends CharacterBody2D

class_name Floppy

var speed = 300
var target_player
var health = 100.0
var damage_points = 10 #damage to player
var points = 5 
var type = "floppy"
var hit_count = 0
var id = 0

#@onready var players = $/root/Game/GameManager.get_players() #get_parent().get_child()
@onready var players = get_parent().players


func _ready():
	id = get_instance_id()

#find closest player in the list
func find_closest_player():
	var closest_player
	var closest_dist = -1
	if players.size() > 0:
		for i in range(0, players.size()): 
			var new_dist = self.global_position.distance_to(players[i].global_position)
			if new_dist < closest_dist or closest_dist == -1:
				closest_player = players[i]
				closest_dist = new_dist
		return closest_player
	return null

func take_damage(player_damage):
	#add health counter
	health -= player_damage
	hit_count += 1
	$HealthBar.value = health
	$AnimatedSprite2D/healthDepletion.play("enemyHit")
	SignalBus.enemy_taking_damage.emit(self, player_damage)
	#print("nhealth:" + str(health))
	if health <= 0: #dead
		SignalBus.player_score_increased.emit(points)
		SignalBus.enemy_health_depleted.emit(self)
		#$/root/Game/GameManager.update_score(points)
		#queue_free()
		# we don t remove the object as it seems to create problem when refreshing the mini map
		# but set them as invisible and no longer participating to the collision detection
		self.visible = false
		$CollisionShape2D.call_deferred("set", "disabled", true)
		
		
		const SMOKE_SCENE = preload("res://assets/enemies/smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_SCENE.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		
#find closest player and jump on him
func _physics_process(_delta):
	target_player = find_closest_player()
	if target_player != null:
		var direction = self.global_position.direction_to(target_player.global_position)
		velocity = direction * speed
		move_and_slide()
	
	
