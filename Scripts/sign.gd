extends CanvasLayer

@export var titleText:String
@export var bodyText:String

@onready var title = $Panel/title
@onready var body = $Panel/body


# Called when the node enters the scene tree for the first time.
func _ready():
	#visible=false
	title.text=titleText
	body.text=bodyText

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
