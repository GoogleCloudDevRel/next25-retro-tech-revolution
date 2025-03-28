class_name EnemyStateMachine extends Node
var states: Array[EnemyState]
var prev_state: EnemyState
var current_state: EnemyState

var enemy: Enemy
var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	
	pass

func _process(delta):
	if current_state:
		change_state(current_state.Process(delta))
	pass
	
func _physics_process(delta):
	if current_state:
		change_state(current_state.Physics(delta))
	
	#manage attacks
	var is_overlapping = false
	player = SignalBus.players[0]
	
	if !enemy.is_dead:
		if player != null:
			var distance_to_player = enemy.global_position.distance_to(player.global_position)
			if distance_to_player < enemy.detection_radius:
				change_state(states[2])
				var overlapping_enemies = player.hurtbox.get_overlapping_bodies()
				if overlapping_enemies.size() > 0:
					for i in overlapping_enemies.size():
						if overlapping_enemies[i].get_instance_id() == enemy.get_instance_id():
							SignalBus.player_taking_damage.emit(player, enemy)
							player.is_getting_hit(get_parent().damage_points)
							is_overlapping = true
		#dead
		if enemy.health <= 0:
			SignalBus.enemy_health_depleted.emit(enemy)
			change_state(states[3])
			print("dead")
			enemy.on_death()
			
		
			

func initialize(_enemy: Enemy) -> void:
	states = []
	enemy = _enemy
	for c in get_children():
		if c is EnemyState:
			states.append(c)
	
	for s in states:
		s.enemy = _enemy
		s.state_machine = self
		s.init()
		
	if states.size() > 0:
		change_state(states[1])
		process_mode = PROCESS_MODE_PAUSABLE
		#process_mode = Node.PROCESS_MODE_INHERIT ###### PROBLEM WILL FREEZE ALL ENEMIES!!!!!
		
func change_state(new_state: EnemyState) -> void:
	if new_state == null || new_state == current_state || get_parent().is_dead:
		return
	
	if current_state:
		current_state.Exit()
		
	prev_state = current_state
	current_state = new_state
	current_state.Enter()
