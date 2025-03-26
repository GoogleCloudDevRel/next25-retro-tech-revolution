extends Node

var score = 0

#stop watch 
var time = 0.0
var time_paused = true

#input actions - pause
var is_paused : bool = false
var is_able_to_pause : bool = true
@export var pause_game_action: StringName = &"pause_game"

#level
var current_level = 1
var level_path = "res://levels/"
const MAX_LEVEL = 3

#@export var Player: PackedScene
#@export var Floppy: PackedScene
#@export var Level: PackedScene

@export var players = []
@export var enemies = []

@export var stopwatch_label: Label
@export var score_label: Label

@onready var pauseScreen = $/root/Game/PauseCanvas


var display_width = ProjectSettings.get("display/window/size/viewport_width")
var display_height = ProjectSettings.get("display/window/size/viewport_height")

#current loaded scene (splashscreen --> questions --> controls --> background story)
var current_scene_instance =  null
@onready var splashScreen = preload("res://assets/screens/splashscreen/splashscreen.tscn")
@onready var questionsScreen = preload("res://assets/screens/questionsscreen/questions_screen.tscn")
@onready var controlsScreen = preload("res://assets/screens/controlsScreen/controls.tscn")
@onready var backstoryScreen = preload("res://assets/screens/backstory/backstory.tscn")
@onready var level1Screen = preload("res://levels/level_1/level_1_screen.tscn")
@onready var gameoverScreen = preload("res://assets/screens/gameover/game_over.tscn")

func _ready():
	#Connect to signals
	#SignalBus.bullet_created.connect(_on_bullet_created)
	SignalBus.screen_state.connect(_on_change_screen_state)
	SignalBus.player_created.connect(_on_add_player)
	SignalBus.enemy_created.connect(_on_add_enemy)
	SignalBus.player_health_depleted.connect(_on_player_health_depleted)
	
	#Connect to game server
	if SignalBus.standalone_mode:
		var client_peer = ENetMultiplayerPeer.new()
		client_peer.create_client("192.168.4.85", 7777)
		multiplayer.multiplayer_peer = client_peer
		SignalBus.client_id = multiplayer.get_unique_id()
	else:
		SignalBus.client_id = Time.get_unix_time_from_system()
	SignalBus.session_id = str(Time.get_unix_time_from_system())
	#launch the SplashScreen at the beginning
	SignalBus.screen_state.emit(SignalBus.SPLASHSCREEN)

#Level 1 loader
func load_level1():
	#level loading
	var l = preload("res://levels/level_1/level_1.tscn")
	var level = l.instantiate()
	level.z_index = -10
	add_child(level)
	

		
	#get_tree().paused = true	

#### load level
func _process(_delta: float) -> void:
	#pause / unpaused was pressed
	if Input.is_action_pressed(pause_game_action) and !is_paused and is_able_to_pause:
		SignalBus.pause_game.emit()
		is_paused = true
		pauseScreen.visible = true
		is_able_to_pause = false
		$pauseTimer.start()
		get_tree().paused = true #pause
	elif Input.is_action_pressed(pause_game_action) and is_paused and is_able_to_pause:
		get_tree().paused = false #unpause
		SignalBus.unpause_game.emit()
		is_paused = false
		pauseScreen.visible = false
		is_able_to_pause = false
		$pauseTimer.start()

# timer to be able ro pause again
func _on_timer_timeout() -> void:
	is_able_to_pause = true
	$pauseTimer.stop()

func _on_add_player(new_player):
	#new_player.position = PLAYER_SPAWN_POSITION
	#new_player.strength = rng.randi_range(STRENGTH_MIN, STRENGTH_MAX)
	#new_player.speed = rng.randi_range(SPEED_PLAYER_MIN, SPEED_PLAYER_MAX)
	#_players_spawn_node.add_child(new_player)
	players.append(new_player)


func _on_add_enemy(new_enemy):
		#get_parent().call_deferred("add_child",new_enemy)
		enemies.append(new_enemy)

func get_players():
	return players

func get_enemies():
	return enemies

### player score / health management
func update_score(points: int):
	score += points
	SignalBus.score_up.emit(score)

func _on_player_health_depleted(_p:Player) -> void:
	print("I m dead")
	SignalBus.stop_game_stopwatch.emit()
	SignalBus.screen_state.emit(SignalBus.GAMEOVER)
	
	
### health management

##########Signals######
#showing the screen with questions to customize the experience
func _on_change_screen_state(new_state) -> void:
	
	if current_scene_instance != null:
		current_scene_instance.queue_free()
	match new_state:
		SignalBus.SPLASHSCREEN:
			current_scene_instance = splashScreen.instantiate()
			add_child(current_scene_instance)
			SignalBus.gemini_backstory_requested.emit()
		SignalBus.QUESTIONS:
			current_scene_instance = questionsScreen.instantiate()
			add_child(current_scene_instance)
		SignalBus.CONTROLS:
			current_scene_instance = controlsScreen.instantiate()
			add_child(current_scene_instance)
		SignalBus.BACKSTORY:
			current_scene_instance = backstoryScreen.instantiate()
			add_child(current_scene_instance)
		SignalBus.LEVEL1:
			current_scene_instance =level1Screen.instantiate()
			current_scene_instance.z_index = -10
			add_child(current_scene_instance)
		SignalBus.GAMEOVER:
			current_scene_instance = gameoverScreen.instantiate()
			add_child(current_scene_instance)
	SignalBus.current_screen_state = new_state

	
	
#new bullet added to the game
func _on_bullet_created(new_bullet) -> void:
	#print("bullet shot")
	add_child(new_bullet)




	
