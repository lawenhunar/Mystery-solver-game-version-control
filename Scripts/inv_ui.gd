extends Control


@onready var inv:Inv=preload("res://Resources/player_inventory.tres")
@onready var slots:Array =  $NinePatchRect/GridContainer.get_children()
var isOpen=false


func _ready():
	inv.update.connect(update_slots)
	update_slots()
	close() 

func update_slots():
	for i in range(min(inv.slots.size(),slots.size())):
		slots[i].update(inv.slots[i])

func _process(delta):
	if Input.is_action_just_pressed("toggle inventory"):
		if isOpen:
			close()
		else:
			open()

func close():
	isOpen=false
	visible=false

func open():
	isOpen=true
	visible=true

