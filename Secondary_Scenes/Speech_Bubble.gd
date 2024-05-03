extends Sprite2D

@onready var speech_text : RichTextLabel = $"Speech Text"

@export var lifetime_frames : int = 100 # Number of frames the speech bubble will be shown

# Called when the node enters the scene tree for the first time.
func _ready():
	speech_text.text = ""
	
	var tween = create_tween()
	var target_scale = scale
	scale = Vector2.ZERO
	tween.tween_property(self, "scale",target_scale,0.4).set_trans(Tween.TRANS_BOUNCE)

func _physics_process(_delta):
	lifetime_frames-=1
	if lifetime_frames == 0:
		var tween = create_tween()
		tween.tween_property(self, "scale",Vector2.ZERO,0.4).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_callback(queue_free)

func set_direction(is_left:bool,is_up:bool):
	if is_left:
		position.x = abs(position.x)
		flip_h = false
	else:
		position.x = -abs(position.x)
		speech_text.position.x -= 90
		flip_h = true
	
	flip_v = is_up
	if is_up:
		position.y += 10
	else:
		position.y -= 10
