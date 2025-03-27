extends Node

### listen to signals
func _ready():
	
	#game signals	
	SignalBus.screen_state.connect(_on_game_screen_state_action)
	SignalBus.pause_game.connect(_on_game_paused_action)
	SignalBus.unpause_game.connect(_on_game_unpaused_action)
	SignalBus.trivia_question_received.connect(_on_trivia_question_received_action)
	#Gemini
	
	SignalBus.gemini_help_requested_details.connect(_on_gemini_help_requested_action)
	SignalBus.gemini_help_received.connect(_on_gemini_help_received_action)
	
	SignalBus.gemini_backstory_requested_details.connect(_on_gemini_backstory_requested_action)
	#SignalBus.gemini_backstory_received.connect(_on_gemini_backstory_received_action)
	SignalBus.gemini_backstory_image_received.connect(_on_gemini_backstory_image_receive_action)
	
	#player signals
	SignalBus.player_created.connect(_on_player_created_action)
	SignalBus.bullet_created.connect(_on_bullet_created_action)
	SignalBus.player_moving.connect(_on_player_moving_action)
	SignalBus.player_taking_damage.connect(_on_player_taking_damage_action)
	SignalBus.player_health_depleted.connect(_on_player_health_depleted_action)
	SignalBus.player_iddle.connect(_on_player_iddle_action)
	SignalBus.player_score_increased.connect(_on_player_score_increased_action)
	
	
	#weapons new 
	SignalBus.weapon_activated.connect(_on_weapon_activated_action)
	SignalBus.weapon_changed.connect(_on_weapon_changed_action)
	
	#Enemy signals
	SignalBus.enemy_created.connect(_on_enemy_created_action)
	SignalBus.enemy_taking_damage.connect(_on_enemy_taking_damage_action)
	SignalBus.enemy_health_depleted.connect(_on_enemy_health_depleted_action)
	
	#Boss signals
	SignalBus.boss_created.connect(_on_boss_created_action)
	
	

###game events
func _on_game_screen_state_action(new_state): #OK except boss
	var request_data = {
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system()
	}
	match new_state:
		SignalBus.SPLASHSCREEN:
			request_data['event_type'] = "on_splashscreen_entered" #NG
		SignalBus.QUESTIONS:
			request_data['event_type'] = "on_questions_screen_entered" #OK
		SignalBus.CONTROLS:
			request_data['event_type'] = "on_controls_screen_entered" #OK
		SignalBus.BACKSTORY:
			request_data['event_type'] = "on_backstory_screen_entered" #OK
		SignalBus.LEVEL1:
			request_data['event_type'] = "on_level1_screen_entered" #OK
			request_data['score'] = SignalBus.score #score
			request_data['stopwatch'] = SignalBus.stopwatch#ms
		SignalBus.BOSS1:
			request_data['event_type'] = "on_boss1_screen_entered" #NG
			request_data['score'] = SignalBus.score #score
			request_data['stopwatch'] = SignalBus.stopwatch#ms
		SignalBus.GAMEOVER:
			request_data['event_type'] = "on_gameover_screen_entered" #OK
			request_data['score'] = SignalBus.score #score
			request_data['stopwatch'] = SignalBus.stopwatch#ms
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)
			
func _on_game_paused_action(): #OK
	print("game paused")
	var request_data = {
			"event_type": "on_game_paused",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"timestamp": Time.get_unix_time_from_system(),
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms
			
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_game_unpaused_action(): #OK
	var request_data = {
			"event_type": "on_game_unpaused",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_trivia_question_received_action(question, answer): #tobe tested
	var request_data = {
			"event_type": "on_trivia_question_received",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"question": question,
			"answer_selected": answer
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

#### Gemini
func _on_gemini_help_requested_action(prompt_text, screenshot_filename): #NG
	var request_data = {
			"event_type": "on_gemini_help_requested",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"prompt_text": prompt_text,
			"screenshot": screenshot_filename,
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms 
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_gemini_help_received_action(help): #NG
	var request_data = {
			"event_type": "on_gemini_help_received",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"help": help,
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms 
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_adjust_difficulty_action(new_difficulty, reason): #NG
	var request_data = {
			"event_type": "on_adjust_difficulty",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"new_difficulty": new_difficulty,
			"reason": reason,
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_gemini_backstory_requested_action(prompt_text:String):
	
	print("sending bs signal")
	var request_data = {
			"event_type": "on_gemini_backstory_requested",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"prompt": prompt_text
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)
	
func _on_gemini_backstory_text_received_action(story:String): #OK
	var request_data = {
			"event_type": "on_gemini_backstory_text_received",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"backstory": story
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_gemini_backstory_image_receive_action(): 
	var request_data = {
			"event_type": "on_gemini_backstory_image_received",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"backstory_image": SignalBus.GCS_BUCKET_BACKSTORIES+"/"+ SignalBus.session_id +".png"
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)


###player events
func _on_player_created_action(p:Player): #OK
	var request_data = {
			"event_type": "on_player_created",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"player_x": p.position.x,
			"player_y": p.position.y,
			"player_health":p.health,
			"player_hit_count":p.hit_count
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_bullet_created_action(b:Bullet): #OK
	var request_data = {
			"event_type": "on_bullet_created",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"bullet_type": b.type,
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_player_moving_action(p:Player, left_stick_x, left_stick_y): #OK
	var request_data = {
			"event_type": "on_player_moving",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"player_x": p.position.x, 
			"player_y": p.position.y, 
			"player_health": p.health, 
			"player_hit_count": p.hit_count, 
			"player_left_stick_x": left_stick_x, 
			"player_left_stick_y": left_stick_y
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend( json_string)

func _on_player_iddle_action(p:Player): #OK
	var request_data = {
			"event_type": "on_player_iddle",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"player_x": p.position.x,
			"player_y": p.position.y,
			"player_health":p.health,
			"player_hit_count":p.hit_count,
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

#func _on_player_weapon_changed_action(p:Player): #TODO
#	pass #TODO

func _on_player_health_depleted_action(p:Player): #OK
	var request_data = {
			"event_type": "on_player_health_depleted",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"player_x": p.position.x, 
			"player_y": p.position.y, 
			"player_hit_count": p.hit_count,
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)


func _on_player_taking_damage_action(p:Player, e:Enemy): #OK
	var request_data = {
			"event_type": "on_player_taking_damage",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"player_x": p.position.x, 
			"player_y": p.position.y, 
			"player_health": p.health, 
			"player_hit_count": p.hit_count,
			"enemy_id": e.get_instance_id(),
			"enemy_type": e.type,
			"enemy_health": e.health,
			"enemy_hit_count": e.hit_count,
			"enemy_points": e.points,
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms	
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_player_score_increased_action(points:int):
	#send score + stopwatch
	
			#"score": 0, #score
			#"stopwatch": 30000#ms
	#TODO
	var request_data = {
			"event_type": "on_weapon_activated",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"added_points": points,
			"score":  SignalBus.score,
			"stopwatch": SignalBus.stopwatch#ms
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)	

###weapons
func _on_weapon_activated_action(weapon_name:String, weapon_idx:int): #TODO
	var request_data = {
			"event_type": "on_weapon_activated",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"activated_weapon": weapon_name,
			"activated_weapon_idx":  weapon_idx
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)		

func _on_weapon_changed_action(weapon_name:String, weapon_idx:int): #TODO
	var request_data = {
			"event_type": "on_weapon_changed",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"new_weapon": weapon_name,
			"new_weapon_idx":  weapon_idx
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)		

###Enemies event
func _on_enemy_created_action(e:Enemy): #OK
	var request_data = {
			"event_type": "on_enemy_created",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"enemy_id": e.get_instance_id(),
			"enemy_type": e.type,
			"enemy_x": e.position.x, 
			"enemy_y": e.position.y, 
			"enemy_health": e.health, 
			"enemy_hit_count": e.hit_count,
			"enemy_points": e.points	
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_enemy_taking_damage_action(e:Enemy, player_damage:int): #OK
	var request_data = {
			"event_type": "on_enemy_taking_damage",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"enemy_id": e.get_instance_id(),
			"enemy_type": e.type,
			"enemy_x": e.position.x,
			"enemy_y": e.position.y,
			"enemy_health": e.health,
			"enemy_hit_count": e.hit_count,
			"enemy_points": e.points,
			"player_damage":  player_damage,
			"score": SignalBus.score, #score
			"stopwatch": SignalBus.stopwatch#ms
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

func _on_enemy_health_depleted_action(e:Enemy): #TODO
	var request_data = {
			"event_type": "on_enemy_created",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"enemy_id": e.get_instance_id(),
			"enemy_type": e.type,
			"enemy_x": e.position.x, 
			"enemy_y": e.position.y, 
			"enemy_health": e.health, 
			"enemy_hit_count": e.hit_count,
			"enemy_points": e.points	
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)

###Boss event
func _on_boss_created_action(b:Boss):
	var request_data = {
			"event_type": "on_boss_created",
			"session_id": SignalBus.session_id,
			"client_id": SignalBus.client_id,
			"ts": Time.get_unix_time_from_system(),
			"enemy_id": b.get_instance_id(),
			"enemy_type": b.type,
			"enemy_x": b.position.x, 
			"enemy_y": b.position.y, 
			"enemy_health": b.health, 
			"enemy_hit_count": b.hit_count,
			"enemy_points": b.points	
	}
	var json_string = JSON.stringify(request_data)
	_call_rpc_backend(json_string)
	
	
	#print("bullet" + b.name + " @" + str(Time.get_unix_time_from_system()))

###RPC declaration###
func _call_rpc_backend(json_string:String):
	if SignalBus.standalone_mode:
		ApiIntegration.call_api_bridge_analytics(json_string) #call directly gcp through the API bridge
	else:
		rpc_id(1,"_send_event_to_analytics",  json_string) #call gcp through the game server

####actual call to the game server
@rpc("any_peer")
func _send_event_to_analytics(_json_string):
	pass
