extends CanvasLayer

@onready var weapon_container = $WeaponContainer

var current_weapon_index = 0
var weapons = [
	{"name": "unarmed", "visible":false,"disabled":true, "texture_unselected": preload("res://assets/hud/assets/greyed_blaster.png"), "texture_selected":preload("res://assets/hud/assets/selected_blaster.png") },
	{"name": "blaster", "visible":true,"disabled":true, "texture_unselected": preload("res://assets/hud/assets/greyed_blaster.png"), "texture_selected":preload("res://assets/hud/assets/selected_blaster.png") },
	{"name": "gauntlet", "visible":true, "disabled":true, "texture_unselected": preload("res://assets/hud/assets/greyed_gauntlet.png"), "texture_selected":preload("res://assets/hud/assets/selected_gauntlet.png")},	
]

var weapon_rects = []

# Size configuration
var selected_size = Vector2(150, 150)  # Larger size for selected weapon
var unselected_size = Vector2(100, 100)  # Smaller size for unselected weapons


func _ready():
	SignalBus.weapon_activated.connect(_on_weapon_activated)
	SignalBus.weapon_changed.connect(_on_weapon_changed)
	
	# Create texture rects for all weapons
	create_weapon_texture_rects()
	update_weapon_display()

func _on_weapon_activated(weapon_name, weapon_idx):
	#print("weapon activated in hud" + str(weapon_idx))
	weapons[weapon_idx]['disabled'] = false
	current_weapon_index = weapon_idx
	update_weapon_display()

func _on_weapon_changed(weapon_name, weapon_idx):
	#print("weapon changed in hud" + str(weapon_idx))
	current_weapon_index =  weapon_idx
	update_weapon_display()


#func _process(delta):
#	if Input.is_action_just_pressed("cycle_weapon"):
#		cycle_weapon()

func create_weapon_texture_rects():
	# Clear any existing texture rects
	for rect in weapon_rects:
		if is_instance_valid(rect):
			rect.queue_free()
	weapon_rects.clear()
	
	# Create a new TextureRect for each weapon
	for weapon in weapons:
		var texture_rect = TextureRect.new()
		# Start with unselected texture
		texture_rect.texture = weapon["texture_unselected"]
		texture_rect.expand = true
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(100, 100)  # Adjust size as needed
		texture_rect.visible = weapon["visible"]  # Use the visibility flag
		
		# Add to the scene
		weapon_container.add_child(texture_rect)
		weapon_rects.append(texture_rect)

func cycle_weapon():
	# Find the next visible weapon
	var start_index = current_weapon_index
	var found_next = false
	
	while !found_next:
		current_weapon_index = (current_weapon_index + 1) % weapons.size()
		if weapons[current_weapon_index]["visible"] or current_weapon_index == start_index:
			found_next = true
	
	update_weapon_display()


func _find_weapon_index(weapon_name):
	for i in range(weapons.size()):
		if weapons[i]['name'] == weapon_name:
			return i
	
func update_weapon_display():
	# Update all weapon textures based on selection state
	for i in range(weapons.size()):
		#if i < weapon_rects.size():
			# Update visibility based on weapon's visible flag
			weapon_rects[i].visible = weapons[i]["visible"]
			
			if !weapons[i]["visible"]:
				continue
				
			# Update texture based on selection state
			if i == current_weapon_index && !weapons[i]["disabled"]:
				weapon_rects[i].texture = weapons[i]["texture_selected"]
				weapon_rects[i].custom_minimum_size = selected_size
			else:
				weapon_rects[i].texture = weapons[i]["texture_unselected"]
				weapon_rects[i].custom_minimum_size = unselected_size
	
	#print("Switched to " + weapons[current_weapon_index]["name"])

# Function to set weapon visibility
func set_weapon_visibility(index, is_visible):
	if index >= 0 and index < weapons.size():
		weapons[index]["visible"] = is_visible
		update_weapon_display()
		
		# If we're hiding the current weapon, cycle to the next one
		if index == current_weapon_index and !is_visible:
			cycle_weapon()

# Add a new weapon with both textures
func add_new_weapon(weapon_name, selected_texture_path, unselected_texture_path, is_visible=true):
	var selected_texture = load(selected_texture_path)
	var unselected_texture = load(unselected_texture_path)
	
	var new_weapon = {
		"name": weapon_name, 
		"texture_selected": selected_texture,
		"texture_unselected": unselected_texture,
		"visible": is_visible
	}
	
	weapons.append(new_weapon)
	
	# Create and add TextureRect for this new weapon
	var new_rect = TextureRect.new()
	new_rect.texture = unselected_texture
	new_rect.expand = true
	new_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	new_rect.custom_minimum_size = unselected_size
	new_rect.visible = is_visible
	
	weapon_container.add_child(new_rect)
	weapon_rects.append(new_rect)
	
	#print("Added new weapon: " + weapon_name)
	update_weapon_display()
