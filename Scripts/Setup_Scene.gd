extends Node2D

@onready var slider : HBoxContainer = $"../CanvasLayer/ScrollContainer/Slider"
@onready var character_setup = preload("res://Resource_Scenes/Character_Setup.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Current index
	var i : int = 0
	# Folder where agent image sheets are located
	var folder_path : String = "res://Assets/Graphics/32x32/"
	while true:
		# Continue the loop only if the current agent image sheet exists
		var current_path : String = folder_path+"Agent_"+str(i)+".png"
		if !FileAccess.file_exists(current_path):
			break
		
		# Get the icon of the agent from the image sheet
		var agent_image = load(current_path).get_image()
		var icon_image = _get_image_region(0, 3, agent_image)
		var new_size = icon_image.get_size()*10
		icon_image.resize(new_size.x,new_size.y,0)
		
		# Create a new character setup node by setting all its respective properties and adding it to the grid
		var new_setup = character_setup.instantiate()
		new_setup.find_child("Sprite Button").icon = ImageTexture.create_from_image(icon_image)
		new_setup.find_child("Name Label").text = ""
		new_setup.find_child("History Label").text = ""
		slider.add_child(new_setup)
		
		i += 1

# Get a specific frame from the image sheet at a specific row and column, and make sure you cut out that extra space at the top
func _get_image_region(row, column, image) -> Image:
	var frame_size = Vector2(16, 32) # Size of each frame
	var frame_position = Vector2(column * frame_size.x, (row+0.3) * frame_size.y)
	var cutout_size = Vector2(frame_size.x,frame_size.y*0.7)
	var region = Rect2i(frame_position, cutout_size)
	return image.get_region(region)
