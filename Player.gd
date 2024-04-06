extends CharacterBody2D

@onready var game_manager : Node = get_node("/root/Main/GameManager")

@export var agent_name : String
@export var animation_texture : Texture
@onready var animated_sprite_2d = $AnimatedSprite2D

@export var inventory: Inv

var previous_velocity : Vector2

var dialogue_history : Array
var dialogue_partner : Node2D

var as_entity : Entity

signal callback_signal
var lock : Mutex = Mutex.new()

@onready var popup_ui_label : Label = $"Popup UI"
var is_showing_popup : bool
var popup_alpha : float

var nearby_entity : Node

func _ready():
	as_entity = Entity.new(agent_name, game_manager.get_location(global_position), "desperate to talk to somebody", null)
	

func _physics_process(_delta):
	if game_manager.is_UI_active():
		return
	
	velocity = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		velocity.x -=1
	if Input.is_key_pressed(KEY_RIGHT):
		velocity.x +=1
	if Input.is_key_pressed(KEY_UP):
		velocity.y -=1
	if Input.is_key_pressed(KEY_DOWN):
		velocity.y +=1
	velocity *= 180
	move_and_slide()
		
	
	if velocity != Vector2.ZERO:
		if velocity.x < 0:
			animated_sprite_2d.animation = "run left"
		elif velocity.x > 0: 
			animated_sprite_2d.animation = "run right"
		elif velocity.y < 0:
			animated_sprite_2d.animation = "run up"
		elif velocity.y > 0: 
			animated_sprite_2d.animation = "run down"
	else:
		if previous_velocity.x < 0:
			animated_sprite_2d.animation = "idle left"
		elif previous_velocity.x > 0: 
			animated_sprite_2d.animation = "idle right"	
		elif previous_velocity.y < 0:
			animated_sprite_2d.animation = "idle up"
		elif previous_velocity.y > 0: 
			animated_sprite_2d.animation = "idle down"
	
	previous_velocity = velocity
	
	as_entity.set_location(game_manager.get_location(global_position))
	
	var target_alpha : float = 0
	if is_showing_popup:
		target_alpha = 1
	popup_alpha = lerpf(popup_alpha, target_alpha, 0.2)
	popup_ui_label.label_settings.font_color.a = popup_alpha

func _input(_event):
	if game_manager.is_UI_active():
		return
		
	if Input.is_key_pressed(KEY_I) and is_showing_popup:
		if nearby_entity.is_in_group("Agent"):
			if nearby_entity.dialogue_partner != null:
				return
			game_manager.enter_new_dialogue(nearby_entity)
			as_entity.set_action("talking with "+nearby_entity.as_entity.entity_name)
			nearby_entity.receive_dialogue("")
		elif nearby_entity.is_in_group("Item"):
			game_manager.setup_item_panel(nearby_entity)
			as_entity.set_interactable(nearby_entity.as_entity)

func _on_interaction_zone_body_entered(body):
	if body == self:
		return
	
	if body.is_in_group("Entity"):
		nearby_entity = body
		is_showing_popup = true


func _on_interaction_zone_body_exited(body):
	if body.is_in_group("Entity") and body == nearby_entity:
		nearby_entity = null
		is_showing_popup = false
