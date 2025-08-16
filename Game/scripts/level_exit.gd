extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("Player exits")
		$/root/Game/GameManager.load_next_level()
	
	#pass # Replace with function body.
