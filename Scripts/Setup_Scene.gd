extends Game_Manager

@onready var instruction_label : Label = $"../CanvasLayer/Instruction"
@onready var slider : HBoxContainer = $"../CanvasLayer/ScrollContainer/Slider"
@onready var character_setup = preload("res://Resource_Scenes/Character_Setup.tscn")
var character_nodes : Array[Control]

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
		
		var button : Button = new_setup.find_child("Sprite Button")
		button.pressed.connect(_character_selected.bind(new_setup))
		button.icon = ImageTexture.create_from_image(icon_image)
		
		var text_box : LineEdit = new_setup.find_child("Name TextBox")
		text_box.visible = false
		text_box.text_submitted.connect(_character_name_entered.bind(new_setup))
		
		new_setup.find_child("Name Label").text = ""
		new_setup.find_child("History Label").text = ""
		slider.add_child(new_setup)
		character_nodes.append(new_setup)
		
		i += 1

func _character_selected(selected_node):
	instruction_label.text = "What's Your Name?"
	for node in character_nodes:
		node.find_child("Sprite Button").disabled = true
	
	selected_node.find_child("Name TextBox").visible = true

func _character_name_entered(text, selected_node):
	instruction_label.text = "Generating the Other Characters"
	selected_node.find_child("Name Label").text = text
	selected_node.find_child("Name TextBox").visible = false

	for i in len(character_nodes):
		var node = character_nodes[i]
		if node == selected_node:
			continue
		_generate_name(node, i<=len(character_nodes)/2)


func _generate_name(node, is_male):
	var random_letter = char(randi_range(65,90))
	var gender : String = "female"
	if is_male:
		gender = "male"
	node.find_child("Name Label").text = await chat_request("What's a random "+gender+" name that starts with "+random_letter)

# Get a specific frame from the image sheet at a specific row and column, and make sure you cut out that extra space at the top
func _get_image_region(row, column, image) -> Image:
	var frame_size = Vector2(16, 32) # Size of each frame
	var frame_position = Vector2(column * frame_size.x, (row+0.3) * frame_size.y)
	var cutout_size = Vector2(frame_size.x,frame_size.y*0.7)
	var region = Rect2i(frame_position, cutout_size)
	return image.get_region(region)
