extends Node2D

var type = "gauntlet"

func _ready():
	pass
	# Create an Area2D child node programmatically
	#var area = %Area2D
	#add_child(area)
	
	# Add collision shape
	#var collision = CollisionShape2D.new()
	#var shape = RectangleShape2D.new()  # or CircleShape2D depending on your needs
	#shape.extents = Vector2(32, 32)  # Adjust size to match your node
	#collision.shape = shape
	#area.add_child(collision)
	
	# Connect signals
	#area.body_entered.emit("_on_body_entered")

func _on_body_entered(body):
	print("Collision detected")
	# Check if the entering body is your player
	if body.is_in_group("player"):
		print("Player entered this Node2D!")
	# Do whatever you need her
	if body.has_method("_is_moving"): #player
		print("got a weapon")
		body.activate_weapon(type)
