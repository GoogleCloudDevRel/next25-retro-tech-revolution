extends SubViewport

#@onready var player = $"../../../../player"
@onready var camera_2d = $Camera2D

var has_player = false
var player

func _ready() -> void:
	world_2d = get_tree().root.world_2d
	SignalBus.player_created.connect(_on_player_created)
	
	
	
#func _physics_process(delta: float) -> void:
	#if has_player:
	#	$Camera2D.position = player.position
	


func _on_player_created(p):	
	has_player = true
	player = p
	print("found")
	
