class_name EnemyStateMachine extends Node
var states: Array[EnemyState]
var prev_state: EnemyState
var current_state: EnemyState

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
	var p = get_parent().get_parent().players[0]
	var e = get_parent()
	if !e.is_dead:
		var overlapping_enemies = p.hurtbox.get_overlapping_bodies()
		if overlapping_enemies.size() > 0:
				for i in overlapping_enemies.size():
					if overlapping_enemies[i].get_instance_id() == e.get_instance_id():
						SignalBus.player_taking_damage.emit(p, e)
						change_state(states[2])
						p.is_getting_hit(get_parent().damage_points)
						is_overlapping = true
		
		if !is_overlapping: #not overlapping
			change_state(states[0])		
	
		#dead
		if e.health == 0:
			print("dead")
			change_state(states[3])
			e.is_dead = true
			
			SignalBus.player_score_increased.emit(e.points)
			SignalBus.enemy_health_depleted.emit(e)	
			%CollisionShape.call_deferred("set", "disabled", true)
			var script = e.get_script()
			
			if script.get_global_name() == "Boss":
				print("Congrats")
				SignalBus.wait(5) #wait 5s
				SignalBus.screen_state.emit(SignalBus.GAMEOVER)
				

func initialize(_enemy: Enemy) -> void:
	states = []
	
	for c in get_children():
		if c is EnemyState:
			states.append(c)
	
	for s in states:
		s.enemy = _enemy
		s.state_machine = self
		s.init()
		
	if states.size() > 0:
		change_state(states[1])
		process_mode = Node.PROCESS_MODE_INHERIT
		
func change_state(new_state: EnemyState) -> void:
	if new_state == null || new_state == current_state || get_parent().is_dead:
		return
	
	if current_state:
		current_state.Exit()
		
	prev_state = current_state
	current_state = new_state
	current_state.Enter()
