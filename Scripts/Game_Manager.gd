extends Node
class_name Game_Manager

var num_chat_requests = 0
var num_embedding_requests = 0
var num_chat_tokens = 0

var start_time = 0
var prev_update_time = 0

var can_record = false;

func _process(_delta):
	if can_record && start_time == 0:
		start_time = Time.get_unix_time_from_system()
		prev_update_time = start_time
	
	if Time.get_unix_time_from_system() - prev_update_time >= 1 && can_record:
		_update_time()

func _update_time():
	prev_update_time = Time.get_unix_time_from_system()

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
	
	var response : Dictionary = await Chat_API.new(token_count).send_request(prompt, request, get_tokens)
	if !response.has("usage"):
		print("Chat GPT API failed: ", response)
		return "[Ignore this text]"
	
	if(can_record):
		num_chat_requests += 1
		num_chat_tokens += response["usage"]["total_tokens"]
		_update_time()
	request.queue_free()
	return response["choices"][0]["message"]["content"]

func embedding_request(input_text):
	var request = HTTPRequest.new()
	add_child(request)
	
	var response = await Embedding_API.new().send_request(input_text, request)
	
	if(can_record):
		num_embedding_requests += 1
		_update_time()
	request.queue_free()
	return response
