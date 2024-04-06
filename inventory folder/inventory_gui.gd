extends Control

var isOpen=false

@onready var inventory:Inv =preload("res://inventory folder/player_inventory.tres")
@onready var slots: Array= $NinePatchRect.get_children()

func _ready():
	update_slots()
	close()
	
func update_slots():
	for i in range(min(inventory.items.size(),slots.size())):
		slots[i].update(inventory.items[i])
	
func _process(delta):
	if Input.is_action_just_pressed("toggle inventory"):
		if (isOpen):
			close()
		else:
			open()

func open():
	visible=true
	isOpen=true
	
func close():
	visible=false
	isOpen=false
