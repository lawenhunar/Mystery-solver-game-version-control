extends Node2D

@export var item: InvItem
var player=null
var player_in_area=false


func _on_pistol_area_body_entered(body):
	
	if body.has_method("player"):
		player_in_area=true
		player=body
	body.collect(item)


func _on_pistol_area_body_exited(body):
	if body.has_method("player"):
		player_in_area=false
