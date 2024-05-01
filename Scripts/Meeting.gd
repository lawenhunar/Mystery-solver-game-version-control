extends CanvasLayer

@onready var body_found = $Body_found


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(6).timeout
	body_found.visible=false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
