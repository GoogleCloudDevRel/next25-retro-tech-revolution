extends Weapon

func _ready():
	SignalBus.weapon_created.emit(self)
	type = "blaster"
	pass

func _on_body_entered(body):
	#print("Collision detected")
	# Check if the entering body is your player
	#if body.is_in_group("player"):
		#print("Player entered this Node2D!")
	# Do whatever you need her
	if body.has_method("_is_moving"): #player
		#print("got a blaster")
		body.activate_weapon(type)
