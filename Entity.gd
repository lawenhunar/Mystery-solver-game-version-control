extends Node2D

class_name Entity

var entity_name : String
var location : String
var action : String
var interactable : Entity

var description : String

func _init(_entity_name, _location, _action, _interactable):
	entity_name = _entity_name
	location = _location
	action = _action
	interactable = interactable
	
	generate_description()

func generate_description():
	description = entity_name+" is currently at "+location+". "
	
	if action != "[nothing]":
		description += entity_name+" is currently "+action+". "
	
	if interactable != null:
		description += entity_name+" is currently interacting with "+interactable.entity_name+"."

func set_location(new_location: String):
	location = new_location
	generate_description()

func set_action(new_action: String):
	action = new_action
	generate_description()

func set_interactable(new_interactable: Entity):
	interactable = new_interactable
	generate_description()
