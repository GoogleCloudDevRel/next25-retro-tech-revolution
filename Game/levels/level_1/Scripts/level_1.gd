extends Node2D

var rng = RandomNumberGenerator.new()

const SPAWN_MIN = 0
const SPAWN_MAX = 17000

const STRENGTH_MIN = 5
const STRENGTH_MAX = 10

const SPEED_PLAYER_MIN = 300
const SPEED_PLAYER_MAX = 500

const SPEED_MIN = 10
const SPEED_MAX = 80

const PLAYER_SPAWN_POSITION = Vector2(0, 0)
const MAX_NUMBER_ENEMIES = 4

@export var CRT_scene: PackedScene = preload("res://levels/level_1/Enemies/CRT/crt.tscn")
#@export var Player: PackedScene = preload("res://assets/players/player.tscn")
#@export var Floppy: PackedScene = preload("res://assets/enemies/floppy/floppy.tscn")
@onready var tilesmap = $floor_tiles
@onready var tiles = tilesmap.get_used_cells_by_id(0, -1 ,Vector2(1, 0))
@export var enemy_number = 5

@export var players = []
@export var enemies = []
@export var bullets = []

func _ready():
	
	if SignalBus.game_difficulty == SignalBus.HARD:
		#change the weapon s position
		$UI_W1.global_position.x = 2128
		$UI_W1.global_position.y = 544
	
	
	
	players.append(%player)
	SignalBus.player_created.emit(%player)
	SignalBus.bullet_created.connect(_on_new_bullet)
	SignalBus.floppy_created.connect(_on_new_floppy)
	generateEnemies()

#func _input(event: InputEvent) -> void:
#	%player
#	print("gameport received")

#func _physics_process(delta: float) -> void:
#	if Input.is_action_just_pressed("up"):
#		print("going up")

func _on_new_bullet(b:Bullet):
	add_child(b)
	bullets.append(b)

func _on_new_floppy(b:Projectiles, origine_position):

	var direction_to_player = origine_position.direction_to(players[0].global_position).normalized()
	var variation = Vector2(
			randf_range(-30, 30),
			randf_range(-30, 30)
		)
	print(direction_to_player)
	add_child(b)
	bullets.append(b)
	b.global_position = origine_position + variation
	b.direction = direction_to_player

#randomly add enemies
func generateEnemies():
		pass
		#add random enemies
		#for i in MAX_NUMBER_ENEMIES:
			#var enemy = CRT_scene.instantiate()
			#var spawner = tiles[ randi() % tilesmap.tile_set.tile_size ]
			#enemy.position = spawner * tilesmap.tile_set.tile_size
			#enemies.append(enemy)
	
	
	#		var xPos = rng.randi_range(SPAWN_MIN, SPAWN_MAX)
	#	var yPos = rng.randi_range(SPAWN_MIN, SPAWN_MAX)
	#	new_enemy.position = Vector2(xPos,yPos)
	#	new_enemy.damage_points = rng.randi_range(STRENGTH_MIN, STRENGTH_MAX)
	#	new_enemy.speed = rng.randi_range(SPEED_MIN, SPEED_MAX)
	#	add_child(new_enemy)
	#	enemies.append(new_enemy)
	#	SignalBus.enemy_created.emit(new_enemy)
