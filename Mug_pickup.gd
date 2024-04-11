extends Node2D

@export var item: InvItem

var player=null
var player_in_area=false

func _ready():
	pass
#
#func _process(delta):
	#if player_in_area:
		#player.collect(item)

#
#func _on_pistol_area_body_entered(body):
	#print("entered area")
	#if body.has_method("Player"):
		#player=body
		#player_in_area=true
		#player.collect(item)
#


#func _on_pistol_area_body_exited(body):
	#if body.has_method("Player"):
		#player_in_area=false


func _on_mug_area_body_entered(body):
	print("entered area mug")
	if body.has_method("Player"):
		player=body
		player_in_area=true
		player.collect(item)

