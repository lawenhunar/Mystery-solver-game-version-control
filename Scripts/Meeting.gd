extends CanvasLayer

@onready var game_manager : Node = get_node("/root/Game/GameManager")

@onready var body_found = $Body_found

var openBool:bool
@onready var chat_panel = $Control/ChatPanel
@onready var vote_panel = $"Control/Vote panel"


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
		chat_panel.visible=true
		vote_panel.visible=false
		await get_tree().create_timer(35).timeout
		chat_panel.visible=false
		vote_panel.visible=true
		await get_tree().create_timer(10).timeout
		visible=false
		game_manager.end_meeting_dialogue()
		
