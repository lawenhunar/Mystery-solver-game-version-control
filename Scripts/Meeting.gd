extends CanvasLayer

@onready var body_found = $Body_found

var openBool:bool
@onready var chat_timer = $Control/ChatPanel/ChatTimer
@onready var vote_timer = $"Control/Vote panel/VoteTimer"

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
		await get_tree().create_timer(6).timeout
		body_found.visible=false
		openBool=false
		#chat_timer.start()
		
