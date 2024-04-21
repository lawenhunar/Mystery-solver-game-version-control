extends Button

@export var kill_method:String

@onready var player = $".."

func _pressed():
	player.cause_of_kill=kill_method

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
