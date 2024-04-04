extends Node

@onready var time_label = $"../UI/TimePanel/TimeLabel"
@onready var request_label = $"../UI/TimePanel/Request Label"
@onready var time_panel = $"../UI/TimePanel"

@onready var layout = $"../Layout"

@onready var player = get_node("/root/Main/Player")

@onready var dialogue_panel = get_node("/root/Main/UI/Dialogue Panel")
var current_agent

@onready var item_panel = get_node("/root/Main/UI/Item Panel")
var current_item

var num_chat_requests = 0
var num_embedding_requests = 0
var num_chat_tokens = 0

var start_time = 0
var in_game_time
var prev_update_time = 0

var can_record = false;

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

func _process(_delta):
	if can_record && start_time == 0:
		start_time = Time.get_unix_time_from_system()
		prev_update_time = start_time
	
	var current_time = Time.get_unix_time_from_system()
	if current_time - prev_update_time >= 1 && can_record:
		in_game_time += 60
		prev_update_time = current_time
		time_label.text = "Time: " + get_current_datetime_string()

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

func get_all_locations() -> Array:
	var all_paths = []
	_add_location_path_to_list(all_paths, layout, "")
	return all_paths

func get_sub_locations(parent_node: Node = layout) -> Array:
	if parent_node == layout:
		return layout.get_children()
		
	var sub_locations = parent_node.get_children()
	
	for node in sub_locations:
		if !(node is Area2D) and !(node is StaticBody2D):
			sub_locations.erase(node)
			continue
		if node.is_in_group("Item"):
			if node.as_entity.interactable != null:
				sub_locations.erase(node)
	
	return sub_locations

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

func get_token_count(prompt):
	return len(prompt)/4.5
	#return int(await _send_chat_request(prompt, 1, true))

func chat_request(prompt, num_input_tokens=0, num_output_tokens=0):
	if num_input_tokens == 0:
		num_input_tokens = get_token_count(prompt)
	if num_output_tokens == 0:
		num_output_tokens = num_input_tokens
	return await _send_chat_request(prompt, num_input_tokens+num_output_tokens)

func _send_chat_request(prompt, token_count, get_tokens=false):
	var request = HTTPRequest.new()
	add_child(request)
	
	var response = await Chat_API.new(token_count).send_request(prompt, request, get_tokens)
	
	if(can_record):
		num_chat_requests += 1
		num_chat_tokens += response["usage"]["total_tokens"]
		_update_stats()
	request.queue_free()
	return response["choices"][0]["message"]["content"]
	
func embedding_request(input_text):
	var request = HTTPRequest.new()
	add_child(request)
	
	var response = await Embedding_API.new().send_request(input_text, request)
	
	if(can_record):
		num_embedding_requests += 1
		_update_stats()
	request.queue_free()
	return response

func _update_stats():
	var num_mins = (Time.get_unix_time_from_system()-start_time)/60
	var label_text = "Chat Requests: "+str(num_chat_requests)+"    (per min: "+str(round(num_chat_requests/num_mins))+")\n"
	label_text += "Embedding Requests: "+str(num_embedding_requests)+"    (per min: "+str(round(num_embedding_requests/num_mins))+")\n"
	label_text += "Chat Tokens: "+str(round(num_chat_tokens))+"    (per min: "+str(round(num_chat_tokens/num_mins))+")\n"
	request_label.text = label_text

func get_current_datetime_string():
	var datetime = Time.get_datetime_dict_from_unix_time(in_game_time)
	var result = weekday_conversions[datetime.weekday] + ", "
	result += month_conversions[datetime.month] + " " + str(datetime.day) + ", "
	result += Time.get_time_string_from_unix_time(in_game_time)
	return result

func enter_new_dialogue(agent):
	current_agent = agent
	current_agent.dialogue_setup(player)
	dialogue_panel.visible = true
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
	current_item = null
	player.as_entity.set_action("idle")

func set_item_action(action):
	current_item.as_entity.set_action(action)
