extends CanvasLayer

@onready var game_manager : Node = get_node("/root/Game/GameManager")

@onready var body_found : Label = $"Body Found"

var openBool:bool
@onready var chat_box : TextEdit = $"Chat Box"


# Called when the node enters the scene tree for the first time.
func _ready():
	#visible=false
	#await get_tree().create_timer(6).timeout
	#body_found.visible=false
	openBool=true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if visible &&openBool:
		body_found.visible=true
		#await get_tree().create_timer(3).timeout
		body_found.visible=false
		openBool=false
		chat_box.visible=true
		await get_tree().create_timer(1).timeout
		chat_box.visible=false
		
		game_manager.setup_voting_process()
		await get_tree().create_timer(10).timeout
		visible=false
		game_manager.end_meeting_dialogue()
		


func _on_text_edit_text_changed():
	if "\n" in chat_box.text:
		game_manager.add_group_message(chat_box.text)
		chat_box.clear()
