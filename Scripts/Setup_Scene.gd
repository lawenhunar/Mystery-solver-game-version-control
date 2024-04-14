extends Node2D

@onready var character_grid : GridContainer = $"../CanvasLayer/ScrollContainer/GridContainer"
@onready var character_setup = preload("res://Resource_Scenes/Character_Setup.tscn")

@export var grid_columns : int = 3
@export var grid_h_spacing : int = 400
@export var grid_v_spacing : int = 300

var frame_size = Vector2(16, 32) # Size of each frame

# Called when the node enters the scene tree for the first time.
func _ready():
	var i : int = 0
	var folder_path : String = "res://Assets/Graphics/32x32/"
	while true:
		var current_path : String = folder_path+"Agent_"+str(i)+".png"
		if !FileAccess.file_exists(current_path):
			break
		
		var agent_image = load(current_path).get_image()
		var icon_image = _get_image_region(0, 3, agent_image)
		var new_size = icon_image.get_size()*10
		icon_image.resize(new_size.x,new_size.y,0)
		
		var new_setup = character_setup.instantiate()
		new_setup.find_child("Sprite Button").texture_normal = ImageTexture.create_from_image(icon_image)
		new_setup.find_child("Name Label").text = ""
		new_setup.find_child("History Label").text = ""
		character_grid.add_child(new_setup)
		
		i += 1
	character_grid.columns = grid_columns
	character_grid.set("theme_override_constants/h_separation", grid_h_spacing)
	character_grid.set("theme_override_constants/v_separation", grid_v_spacing)

func _get_image_region(row, column, image) -> Image:
	var frame_position = Vector2(column * frame_size.x, row * frame_size.y)
	var region = Rect2i(frame_position, frame_size)
	return image.get_region(region)
