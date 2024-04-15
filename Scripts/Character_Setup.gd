extends MarginContainer

var age : int
var character_name : String
var traits : String
var history : String
var is_male : bool

@onready var sprite_button : Button
@onready var highlight_panel : Panel
@onready var name_textbox : LineEdit
@onready var name_label : Label
@onready var description_label : RichTextLabel

func setup_initial_values(texture_sheet, _is_male):
	var agent_image = texture_sheet.get_image()
	var icon_image = _get_image_region(0, 3, agent_image)
	var new_size = icon_image.get_size()*10
	icon_image.resize(new_size.x,new_size.y,0)
	is_male = _is_male
	
	sprite_button = find_child("Sprite Button")
	highlight_panel = find_child("Highlight")
	name_textbox = find_child("Name TextBox")
	name_label = find_child("Name Label")
	description_label = find_child("Description Label")
	
	sprite_button.icon = ImageTexture.create_from_image(icon_image)
	name_textbox.visible = false
	highlight_panel.visible = false
	name_label.text = ""
	description_label.text = ""

func generate_info(game_manager, concurrency_handler):
	var random_letter = char(randi_range(65,90))
	var gender : String = "female"
	if is_male:
		gender = "male"
	character_name = await game_manager.chat_request("What's a random "+gender+" name that starts with "+random_letter)
	name_label.text = character_name
	
	age = randi_range(18,60)
	
	description_label.text += "Age: "+str(age)
	
	var traits_prompt : String = "I have a "+gender+" character who is "+str(age)+" years old named "+character_name+". "
	traits_prompt += "Come up with a few random traits for this character. Respond only with the traits like so:\nFunny, sarcastic, and smart"
	traits = await game_manager.chat_request(traits_prompt)
	description_label.text += "\n\nTraits: "+traits
	
	var existing_memories_prompt = "I have a video game character called "+character_name+" (gender: "+gender+", age: "+str(age)+", traits: "+traits+"). "
	existing_memories_prompt += "Write me 10 short sentences that describe "+character_name+"'s character, history, and current state. Imagine this character lives a pretty routine life. "
	existing_memories_prompt += "Your response should be a single paragraph, with statements separated by semi-colons. Examples of statements are as follows:\nJohn likes to go for walks;\nEmily has three dogs that she adores;\nStacy loves her job at the family restaurant;"
	
	var existing_memories = await game_manager.chat_request(existing_memories_prompt,92,200)
	description_label.text += "\n\n"+existing_memories
	
	concurrency_handler.response_complete()

func set_name_text(text):
	name_label.text = text

func disable_button():
	sprite_button.disabled = true

func enable_textbox():
	name_textbox.visible = true

func disable_textbox():
	name_textbox.visible = false

# Get a specific frame from the image sheet at a specific row and column, and make sure you cut out that extra space at the top
func _get_image_region(row, column, image) -> Image:
	var frame_size = Vector2(16, 32) # Size of each frame
	var frame_position = Vector2(column * frame_size.x, (row+0.3) * frame_size.y)
	var cutout_size = Vector2(frame_size.x,frame_size.y*0.7)
	var region = Rect2i(frame_position, cutout_size)
	return image.get_region(region)
