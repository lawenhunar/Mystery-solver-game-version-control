extends AnimatedSprite2D

@onready var texture_image : Image = $"..".animation_texture.get_image()

var frames = SpriteFrames.new()
var frame_count : int = 6
var frame_size = Vector2(16, 32) # Size of each frame

func _ready():
	var actions = ["idle", "run"]
	var directions = ["right", "up", "left", "down"]
	
	if get_parent().is_in_group("Agent"):
		get_parent().icon = _get_texture_region(0, 3)
	
	for i in 2:
		for j in 4:
			var current_animation_name = actions[i]+" "+directions[j] 
			frames.add_animation(current_animation_name)
			
			for f in frame_count:
				var frame_texture = _get_texture_region(i+1, j*6 + f)
				frames.add_frame(current_animation_name, frame_texture)
				if i == 1:
					frames.set_animation_speed(current_animation_name, 10)
	
	sprite_frames = frames
	animation = "idle down"
	play("idle down")

func _get_texture_region(row, column) -> Texture:
	var frame_position = Vector2(column * frame_size.x, row * frame_size.y)
	var region = Rect2i(frame_position, frame_size)
	var image_region = texture_image.get_region(region)
	return ImageTexture.create_from_image(image_region)
