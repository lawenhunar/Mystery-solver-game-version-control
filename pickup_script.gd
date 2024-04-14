extends Node2D

@export var item: InvItem
@export var item_name: String
@onready var sprite_2d = $interactible_area/Sprite2D

var player=null
var player_in_area=false

func _ready():
	#sprite_2d.texture
	pass


func _on_interactible_area_body_entered(body):
	print("entered area")
	if body.has_method("Player"):
		player=body
		player_in_area=true
		player.collect(item)
		await get_tree().create_timer(0.1).timeout
		self.queue_free()
