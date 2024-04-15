extends Game_Manager

var concurrency_handler : ConcurrencyHandler

@onready var instruction_label : Label = $"../CanvasLayer/Instruction"
@onready var slider : HBoxContainer = $"../CanvasLayer/ScrollContainer/Slider"
@onready var start_button : Button = $"../CanvasLayer/Start Button"
@onready var character_setup = preload("res://Resource_Scenes/Character_Setup.tscn")

@export_file("*.tscn") var next_scene

var character_nodes : Array[Control]
var selected_character

# Called when the node enters the scene tree for the first time.
func _ready():
	concurrency_handler = ConcurrencyHandler.new()
	start_button.visible = false
	
	var folder_path = "res://Assets/Graphics/32x32/"
	var dir = DirAccess.open(folder_path)
	var files : PackedStringArray = dir.get_files()
	for path in files:
		# If the current file is not one of the agent image sheets, move onto the next one
		if "Agent" not in path or ".import" in path:
			continue
			
		# Get the gender of the current agent
		var is_male : bool = false
		if path.split("_")[1] == "M":
			is_male = true

		# Create a new character setup node by setting all its respective properties and adding it to the grid
		var new_setup = character_setup.instantiate()
		new_setup.setup_initial_values(load(folder_path+path), is_male)
		new_setup.sprite_button.pressed.connect(_character_selected.bind(new_setup))
		new_setup.name_textbox.text_submitted.connect(_character_name_entered)
		slider.add_child(new_setup)
		character_nodes.append(new_setup)
	
# Called once the player clicks on a character to be their avatar
func _character_selected(selected_node):
	instruction_label.text = "What's Your Name?"
	for node in character_nodes:
		node.disable_button()
	
	selected_character = selected_node
	selected_character.enable_textbox()

# Called once the player has entered their name into the text box
func _character_name_entered(text):
	instruction_label.text = "Generating the Other Characters"
	selected_character.set_name_text(text)
	selected_character.disable_textbox()

	for node in character_nodes:
		if node == selected_character:
			node.description_label.text = "Player"
			continue
		node.generate_info(self, concurrency_handler)
	await concurrency_handler.wait_for_responses(len(character_nodes)-1)
	
	_pick_target()

func _pick_target():
	var target_index : int = randi_range(0,len(character_nodes)-1)
	while character_nodes[target_index] == selected_character:
		target_index = randi_range(0,len(character_nodes)-1)
	
	var target_node = character_nodes[target_index]
	instruction_label.text = "Your Mission: Kill "+target_node.character_name
	target_node.highlight_panel.visible = true
	
	start_button.visible = true


func _on_redo_button_pressed():
	get_tree().reload_current_scene()


func _on_start_button_pressed():
	get_tree().change_scene_to_file(next_scene)
