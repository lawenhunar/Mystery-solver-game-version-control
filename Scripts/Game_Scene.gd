extends Game_Manager

@onready var time_label = $"../UI/TimePanel/TimeLabel"
@onready var request_label = $"../UI/TimePanel/Request Label"
@onready var time_panel = $"../UI/TimePanel"

@onready var layout = $"../Layout"

@onready var player = get_node("/root/Game/Player")
@onready var agents_root = $"../Agents"
@onready var agent_scene = preload("res://Secondary_Scenes/Agent.tscn")

@onready var dialogue_panel = get_node("/root/Game/UI/Dialogue Panel")
var current_agent

@onready var item_panel = get_node("/root/Game/UI/Item Panel")
var current_item

@onready var inv_ui = $"../UI/inv_ui"

var in_game_time
var month_conversions = {
	1: "January",
	2: "February",
	3: "March",
	4: "April",
	5: "May",
	6: "June",
	7: "July",
	8: "August",
	9: "September",
	10: "October",
	11: "November",
	12: "December",
}

var weekday_conversions = {
	0: "Sunday",
	1: "Monday",
	2: "Tuesday",
	3: "Wednesday",
	4: "Thursday",
	5: "Friday",
	6: "Saturday",
}

func _ready():
	in_game_time = Time.get_unix_time_from_datetime_string("2024-03-11T08:00:00")
	dialogue_panel.visible = false
	item_panel.visible = false
	
	# Create all the agents using the information generated in the setup scene
	for info in DataTransfer.agent_infos:
		var new_agent = agent_scene.instantiate()
		agents_root.add_child(new_agent)
		
		var all_standing_zones : Array = get_all_standing_zones()
		var chosen_location = all_standing_zones.pick_random()
		
		new_agent.setup_intial_values(info, chosen_location.global_position)
	
	# Create the player using the information generated in the setup scene
	player.agent_name = DataTransfer.player_info.name
	player.animation_texture = DataTransfer.player_info.texture

func _update_time():
	super._update_time()
	in_game_time += 60
	time_label.text = "Time: " + get_current_datetime_string()
	_update_stats()

func get_location(point: Vector2) -> String:
	var result_path = ""
	
	var current_node = layout
	while current_node.get_child_count() != 0:
		var does_intersect : bool = false
		for node in current_node.get_children():
			if node is Area2D:
				var collision_shape = node.get_node("CollisionShape2D")
				if collision_shape:
					var rect : Rect2 = collision_shape.get_shape().get_rect()
					if rect.has_point(point-collision_shape.global_position):
						# If the point is inside the current Area2D, add it to the path
						var node_name = node.get_name()
						if result_path != "":
							result_path += ":"
						result_path += node_name
						does_intersect = true
						current_node = node
						break
		if !does_intersect:
			break
	
	return result_path

func get_sub_locations(parent_node: Node = layout) -> Array:
	if parent_node == layout:
		return layout.get_children()
		
	var sub_locations = parent_node.get_children()
	
	for i in range(len(sub_locations)-1,-1,-1):
		var node = sub_locations[i]
		if !(node is Area2D) and !(node is StaticBody2D):
			sub_locations.erase(node)
	
	return sub_locations

func get_all_standing_zones() -> Array:
	var all_paths = []
	_add_standing_zones_to_list(all_paths, layout)
	return all_paths

func _add_standing_zones_to_list(list: Array, current_node: Node):
	var new_area_found : bool = false
	for node in current_node.get_children():
		if node is Area2D:
			_add_standing_zones_to_list(list, node)
			new_area_found = true
	
	if !new_area_found and "Standing Zone" in current_node.get_name():
		list.append(current_node)
		return

func get_all_locations() -> Array:
	var all_paths = []
	_add_location_path_to_list(all_paths, layout, "")
	return all_paths

func _add_location_path_to_list(list: Array, current_node: Node, current_path: String):
	if current_node is Area2D and "Standing Zone" not in current_node.get_name():
		if current_path != "":
			current_path += ":"
		current_path += current_node.get_name()
		
	var new_area_found : bool = false
	for node in current_node.get_children():
		if node is Area2D:
			_add_location_path_to_list(list, node, current_path)
			new_area_found = true
	
	if !new_area_found:
		list.append(current_path)
		return

func get_current_datetime_string():
	var datetime = Time.get_datetime_dict_from_unix_time(in_game_time)
	var result = weekday_conversions[datetime.weekday] + ", "
	result += month_conversions[datetime.month] + " " + str(datetime.day) + ", "
	result += Time.get_time_string_from_unix_time(in_game_time)
	return result

func _update_stats():
	var num_mins = (Time.get_unix_time_from_system()-start_time)/60
	var label_text = "Chat Requests: "+str(num_chat_requests)+"    (per min: "+str(round(num_chat_requests/num_mins))+")\n"
	label_text += "Embedding Requests: "+str(num_embedding_requests)+"    (per min: "+str(round(num_embedding_requests/num_mins))+")\n"
	label_text += "Chat Tokens: "+str(round(num_chat_tokens))+"    (per min: "+str(round(num_chat_tokens/num_mins))+")\n"
	request_label.text = label_text

func enter_new_dialogue(agent):
	current_agent = agent
	current_agent.dialogue_setup(player)
	player.velocity = Vector2.ZERO
	dialogue_panel.visible = true
	inv_ui.visible=false
	dialogue_panel.initialize_with_agent(agent)

func set_dialogue_text(new_text):
	dialogue_panel.on_agent_talk(new_text)

func send_dialogue_text(new_text):
	current_agent.receive_dialogue(new_text)

func exit_dialogue ():
	current_agent.end_dialogue()
	current_agent = null
	dialogue_panel.visible = false
	player.as_entity.set_action("idle")

func is_UI_active():
	return dialogue_panel.visible or item_panel.visible

func setup_item_panel(item):
	current_item = item
	item_panel.initialize_with_item(item)

func close_item_panel():
	current_item.as_entity.set_interactable(null)
	current_item = null
	player.as_entity.set_action("idle")

func set_item_action(action):
	current_item.as_entity.set_action(action)
