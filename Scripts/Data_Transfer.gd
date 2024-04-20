extends Node
class_name Data_Transfer

var player_info : Dictionary
var agent_infos : Array[Dictionary]

func _ready():
	set_player_info({"name":"Player","texture":load("res://Assets/Graphics/32x32/Characters/Alex_M.png")})
	add_agent_info({"name":"Luna","texture":load("res://Assets/Graphics/32x32/Characters/Luna_F.png"),"age":22,"gender":"female","traits":"Hot and mysterious","history":"nothing much"})

func reset_values():
	agent_infos.clear()

func add_agent_info(info):
	agent_infos.append(info)

func set_player_info(info):
	player_info = info
