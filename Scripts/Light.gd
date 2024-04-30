extends PointLight2D

@onready var light = $".."

@onready var game_manager = $"../../../../../GameManager"
@onready var day_night_cycle = $"../../../../day_night cycle"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if day_night_cycle.time_as_float>9 && day_night_cycle.time_as_float<19:
		energy=0.2
	else:
		energy=0.9
	#if candle_lamp.as_entity.entity_name==null:
		#print("whi")
	if game_manager.get_item_action(light)=="off":
		light.visible=false
	elif game_manager.get_item_action(light)=="on":
		light.visible=true
