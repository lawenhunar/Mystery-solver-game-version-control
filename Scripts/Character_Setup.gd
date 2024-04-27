extends MarginContainer

var character_name : String
var texture_sheet : Texture
var age : int
var gender : String
var traits : String
var history : String
var is_male : bool

var sprite_button : Button
var highlight_panel : Panel
var name_textbox : LineEdit
var name_label : Label
var description_label : RichTextLabel

func _initialize_children():
	sprite_button = $"Panel/Control/Sprite Button"
	highlight_panel = $Panel/Control/Highlight
	name_textbox = $"Panel/Name TextBox"
	name_label = $"Panel/Name Label"
	description_label = $"Panel/Description Label"

func setup_initial_values(_texture_sheet, _is_male):
	texture_sheet = _texture_sheet
	var agent_image = texture_sheet.get_image()
	var icon_image = _get_image_region(0, 3, agent_image)
	var new_size = icon_image.get_size()*10
	icon_image.resize(new_size.x,new_size.y,0)
	is_male = _is_male
	
	_initialize_children()
	
	sprite_button.icon = ImageTexture.create_from_image(icon_image)
	name_textbox.visible = false
	highlight_panel.visible = false
	name_label.text = ""
	description_label.text = ""

func generate_info(game_manager, concurrency_handler):
	age = randi_range(18,60)
	
	var random_letter = char(randi_range(65,90))
	gender = "female"
	if is_male:
		gender = "male"
	character_name = await game_manager.chat_request("What's a random name for a "+str(age)+" old "+gender+" that starts with "+random_letter)
	name_label.text = character_name
	description_label.text += "Age: "+str(age)
	
	var traits_prompt : String = "I have a "+gender+" character who is "+str(age)+" years old named "+character_name+". "
	traits_prompt += "Come up with a few random traits for this character. Respond only with the traits like so:\nFunny, sarcastic, and smart"
	traits = await game_manager.chat_request(traits_prompt)
	description_label.text += "\n\nTraits: "+traits
	
	var history_prompt = "I have a video game character called "+character_name+" (gender: "+gender+", age: "+str(age)+", traits: "+traits+"). "
	history_prompt += "Write me 10 short sentences that describe "+character_name+"'s character, history, and current state. Imagine this character lives a pretty routine life. "
	history_prompt += "Your response should be a single paragraph, with statements separated by semi-colons. Examples of statements are as follows:\nJohn likes to go for walks;\nEmily has three dogs that she adores;\nStacy loves her job at the family restaurant;"
	
	history = await game_manager.chat_request(history_prompt,92,200)
	description_label.text += "\n\n"+history
	
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
