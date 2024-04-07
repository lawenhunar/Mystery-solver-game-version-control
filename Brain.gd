extends CharacterBody2D

@onready var game_manager : Node = get_node("/root/Main/GameManager")

var icon : Texture
@export var animation_texture : Texture
@onready var animated_sprite_2d = $AnimatedSprite2D

@export var agent_name : String
@export var age : int
@export_enum("he/him", "she/her", "other") var pronouns : String
@export_multiline var traits : String

@export_range(0, 1) var recency_weight : float = 1
@export_range(0, 1) var importance_weight : float = 1
@export_range(0, 1) var relevance_weight : float = 1

@onready var navigation_agent_2d = $NavigationAgent2D
@onready var interaction_zone = $"Interaction Zone"
var acceleration=7
var speed=150
var destination:Node
var previous_destination:Node
var facing_direction : Vector2 = Vector2.DOWN

var agent_summary : String
var memories : Array
var new_observations : Array[Entity]
var dialogue_history : Array
var dialogue_partner : Node2D
var current_plan : String
var all_tasks : Array

var as_entity : Entity

signal callback_signal
var lock : Mutex = Mutex.new()
var responses = []

var can_trigger : bool = false
var time_since_last_trigger : int
var time_since_last_plan : int
var planning_duration : int = 60 # in seconds
var trigger_duration : int = 10 # in seconds

# These variables are used for the relfection process
var recent_importance_threshold : int = 100
var oldest_memory_index : int = 0
var is_reflecting : bool = false
var num_reflection_questions : int = 3
var num_insights_per_reflection_question : int = 5

@onready var conversation_panel = $"Conversation Panel"


func _ready():
	as_entity = Entity.new(self, agent_name, game_manager.get_location(global_position), "wants to talk to somebody", null)
	game_manager.can_record = true
	conversation_panel.visible = false
	
	var existing_memories_prompt = "I have a video game character called "+agent_name+" (pronouns: "+pronouns+", age: "+str(age)+", traits: "+traits+"). "
	existing_memories_prompt += "Write me 10 short sentences that describe "+agent_name+"'s character, history, and current state. Imagine this character lives a pretty routine life. "
	existing_memories_prompt += "Your response should be a single paragraph, with statements separated by semi-colons. Examples of statements are as follows:\nJohn likes to go for walks;\nEmily has three dogs that she adores;\nStacy loves her job at the family restaurant;"
	
	var existing_memories = await game_manager.chat_request(existing_memories_prompt,92,200)
	
	for content in existing_memories.split(";"):
		_add_memory(content.strip_edges())
	
	await _collect_responses(memories.size())
	
	await _generate_agent_summary()
	var current_time = Time.get_datetime_dict_from_unix_time(game_manager.in_game_time)
	await _generate_plan({"hour":str(current_time.hour),"minute":str(current_time.minute)})
	
	can_trigger = true

func _physics_process(delta):
	if !memories.is_empty() && !is_reflecting:
		var total_recent_importance = 0
		for i in range(oldest_memory_index, len(memories)):
			total_recent_importance += memories[i].importance
		
		if total_recent_importance >= recent_importance_threshold:
			_reflect()
	
	var current_time = Time.get_unix_time_from_system()
	if can_trigger && (current_time-time_since_last_trigger) >= trigger_duration:
		_trigger_brain()

	if destination != null and dialogue_partner == null:
		if interaction_zone.overlaps_body(destination):
			_end_navigation()
		else:
			var direction=Vector3()
			navigation_agent_2d.target_position=destination.global_position
			direction=navigation_agent_2d.get_next_path_position()-global_position
			direction=direction.normalized()
			
			var intended_velocity=velocity.lerp(direction*speed,acceleration*delta)
			navigation_agent_2d.set_velocity(intended_velocity)
	
	if navigation_agent_2d.distance_to_target()<3 or destination == null:
		velocity = Vector2.ZERO
	else:
		facing_direction = velocity
		move_and_slide()
	
	as_entity.set_location(game_manager.get_location(global_position))
	_observe()
	
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
		if facing_direction.x < 0:
			animated_sprite_2d.animation = "idle left"
		elif facing_direction.x > 0: 
			animated_sprite_2d.animation = "idle right"	
		elif facing_direction.y < 0:
			animated_sprite_2d.animation = "idle up"
		elif facing_direction.y > 0: 
			animated_sprite_2d.animation = "idle down"

func _set_destination(chosen_node):
	previous_destination = destination
	destination = chosen_node

func _end_navigation():
	destination = null
	navigation_agent_2d.set_velocity(Vector2.ZERO)
	navigation_agent_2d.target_position = global_position

func _collect_responses(num_expected_responses):
	var num_responses_recieved = 0
	while num_responses_recieved != num_expected_responses:
		await callback_signal
		num_responses_recieved += 1

func _generate_memory_summary(query):
	var relevant_memories = await _retrieve_memories(query, 5)
	
	var summary_prompt = "Given the following statements, answer the following query: "+query+"\nStatements:\n"
	var current_token_count = 0
	for memory in relevant_memories:
		if current_token_count + memory.token_count < 2040:
			summary_prompt += "- "+memory.content+"\n"
			current_token_count += memory.token_count
	
	summary_prompt += "Be direct and concise, no introduction needed. Use only the statements relevant to the query, and if there are not enough relevant statements to form a logical conclusion, respond with [nothing]"
	
	var response = await game_manager.chat_request(summary_prompt, 0, 400)
	if response.contains("[nothing]"):
		response = ""
	responses.append(response)
	
	lock.lock()
	callback_signal.emit()
	lock.unlock()

func _generate_agent_summary():
	agent_summary = "Name: " + agent_name + " (pronouns: "+pronouns+" | age:" + str(age) + ")\n"
	agent_summary += "Innate traits: " + traits + "\n"
	
	_generate_memory_summary(agent_name + "'s core characteristics")
	_generate_memory_summary(agent_name + "'s current daily occupation")
	_generate_memory_summary(agent_name + "'s feelings about his/her recent progress in life")
	
	await _collect_responses(3)
	for response in responses:
		agent_summary += response
	responses.clear()
	print(agent_summary)

func _get_general_plan_prompt(existing_plan):
	var plan_prompt = agent_summary
	plan_prompt += "\nToday is "+game_manager.get_current_datetime_string()+"."
	
	if existing_plan == "":
		plan_prompt += " "+agent_name+" doesn't have a plan for today."
	else:
		plan_prompt += " Here is "+agent_name+"'s current plan for the day:\n"+existing_plan
	plan_prompt += "\nHere is all the places "+agent_name+" is aware of:\n"
	
	var locations = game_manager.get_all_locations()
	for location in locations:
		plan_prompt += "-"+location+"\n"
	
	plan_prompt += as_entity.description+"\n"
	return plan_prompt

func _generate_plan(start_time):
	time_since_last_plan = Time.get_unix_time_from_system()
	var memory_header = "Plan made at "+game_manager.get_current_datetime_string()+"\n"
	
	if current_plan == "":
		var broad_level_prompt = _get_general_plan_prompt(current_plan)
		broad_level_prompt += "Generate a new plan for "+agent_name+" starting from "+start_time.hour+":"+start_time.minute+" till 23:59 midnight in broad strokes.\n"
		broad_level_prompt += "The format of each item in the plan should be as follows: [chosen start time]) For [chosen duration in mins], at [chosen location], [chosen task in one sentence].\n"
		broad_level_prompt += "Keep in mind that all time is in 24-hour format. Use only the locations listed and nothing else"
		
		var broad_level = await game_manager.chat_request(broad_level_prompt)
		current_plan = broad_level
		
		var hourly_level_prompt = _get_general_plan_prompt(current_plan)
		hourly_level_prompt += "Update this plan by breaking down each task into hourly subtasks.\n"
		hourly_level_prompt += "The format of each item in the plan should be as follows: [chosen start time]) For [chosen duration in mins], at [chosen location], [chosen task in one sentence].\n"
		hourly_level_prompt += "For each subtask, include the appropraite location. Keep in mind that all time is in 24-hour format. Use only the locations listed and nothing else"

		var hourly_level = await game_manager.chat_request(hourly_level_prompt)
		current_plan = hourly_level

	var fine_level_prompt = _get_general_plan_prompt(current_plan)
	fine_level_prompt += "Update this plan starting from "+start_time.hour+":"+start_time.minute+" till 23:59 midnight by breaking down each task into 5-15 min subtasks.\n"
	fine_level_prompt += "The format of each item in the plan should be as follows: [chosen start time]) For [chosen duration in mins], at [chosen location], [chosen task in one sentence].\n"
	fine_level_prompt += "For each subtask, include the appropraite location. Keep in mind that all time is in 24-hour format. Use only the locations listed and nothing else"
	
	var fine_level = await game_manager.chat_request(fine_level_prompt)
	current_plan = fine_level
	
	all_tasks = current_plan.split("\n")
	for i in len(all_tasks):
		var task = all_tasks[i]
		var task_parts = task.split(",")
		if len(task_parts) != 3:
			all_tasks[i] = {"unix_time": 0, "task": "", "location":""}
			continue
		
		var current_time_string = Time.get_datetime_string_from_unix_time(game_manager.in_game_time)
		var task_time_string = task.split(")")[0]
		var task_time_unix = Time.get_unix_time_from_datetime_string(current_time_string.split("T")[0]+"T"+task_time_string+":00")
		all_tasks[i] = {"unix_time": task_time_unix, "task": task_parts[len(task_parts)-1], "location":task_parts[1]}
		
	current_plan = memory_header+current_plan
	_add_memory(current_plan)

func _print_all_memories():
	for memory in memories:
		_print_memory(memory)

func _print_memory(memory):
	print("Memory <" + memory.content + ">:")
	print("- Time Created: ", memory.time_created)
	print("- Time Last Accessed: ", memory.time_last_accessed)
	print("- Importance: ", memory.importance)
	print("- Embeddings: ", memory.embedding.slice(0,5))
	print()

func _add_memory(content):
	var time = game_manager.in_game_time

	var memory = await Memory.new(time, content, game_manager, callback_signal, lock)
	
	memories.append(memory)

func _retrieve_memories(query, num_top_memories=len(memories)):
	var query_embedding = await game_manager.embedding_request(query)

	var current_time = Time.get_unix_time_from_datetime_string(Time.get_datetime_string_from_system())
	
	var memory_scores = []
	var scaling_values = {"min_recency": 1, "max_recency": 0,
						  "min_importance": 1, "max_importance": 0,
						  "min_relevance": 1, "max_relevance": 0}
	for memory in memories:
		var time_difference = (current_time - memory.time_created) / 3600
		var recency = 1 / exp(0.995 * time_difference)
		var importance = memory.importance/10.0
		var relevance = 0.5
		if len(query_embedding) == len(memory.embedding):
			relevance = _calculate_cosine_similarity(query_embedding, memory.embedding)
		
		scaling_values.min_recency = min(scaling_values.min_recency, recency)
		scaling_values.min_importance = min(scaling_values.min_importance, importance)
		scaling_values.min_relevance = min(scaling_values.min_relevance, relevance)
		scaling_values.max_recency = max(scaling_values.max_recency, recency)
		scaling_values.max_importance = max(scaling_values.max_importance, importance)
		scaling_values.max_relevance = max(scaling_values.max_relevance, relevance)
		
		var score = {"memory": memory, "final_score": 0, "recency": recency, "importance": importance, "relevance": relevance}		
		memory_scores.append(score)
		
	for score_data in memory_scores:
		var recency_mapped = _map(score_data.recency, scaling_values.min_recency, scaling_values.max_recency, 0, 1)
		var importance_mapped = _map(score_data.importance, scaling_values.min_importance, scaling_values.max_importance, 0, 1)
		var relevance_mapped = _map(score_data.relevance, scaling_values.min_relevance, scaling_values.max_relevance, 0, 1)
		
		score_data.final_score = recency_mapped * recency_weight + importance_mapped * importance_weight + relevance_mapped * relevance_weight
	
	memory_scores.sort_custom(func(a, b): return a.final_score > b.final_score)
		
	# Return the top num_top_memories memories
	var top_memories = []
	for i in min(num_top_memories, memory_scores.size()):
		var current_memory = memory_scores[i].memory
		top_memories.append(current_memory)
		current_memory.time_last_accessed = current_time
		
	return top_memories

func _map(value, in_min, in_max, out_min, out_max):
	if in_min == in_max:
		return out_max
	return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min

func _calculate_cosine_similarity(vector1, vector2):
	var dot_product = 0.0
	var magnitude_vector1 = 0.0
	var magnitude_vector2 = 0.0
	
	for i in len(vector1):
		dot_product += vector1[i] * vector2[i]
		magnitude_vector1 += vector1[i] * vector1[i]
		magnitude_vector2 += vector2[i] * vector2[i]
	
	magnitude_vector1 = sqrt(magnitude_vector1)
	magnitude_vector2 = sqrt(magnitude_vector2)

	# Avoid division by zero
	if magnitude_vector1 == 0.0 or magnitude_vector2 == 0.0:
		return 0
	
	return dot_product / (magnitude_vector1 * magnitude_vector2)

func _trigger_brain():
	can_trigger = false
	time_since_last_trigger = Time.get_unix_time_from_system()
	
	if dialogue_partner != null:
		return
	
	var reaction = await _react()
	
	if dialogue_partner != null:
		return
		
	for entity in new_observations:
		_add_memory(entity.description)
	await _collect_responses(new_observations.size())
	
	if reaction == "Continue":
		can_trigger = true
		return
	
	var reaction_parts = reaction.split("|")
	
	if len(reaction_parts) != 2:
		print("Reaction failed: ", reaction)
		return
		
	as_entity.set_action(reaction_parts[1].strip_edges())
	
	if "Update" in reaction_parts[0].strip_edges():
		as_entity.set_interactable(null)
		await _pick_location()	
	else:
		var index = int(reaction_parts[0])-1
		if index < new_observations.size():
			var entity : Entity = new_observations[index]
			if entity.as_node != previous_destination:
				self.as_entity.set_interactable(entity)
				_set_destination(entity.as_node)
	
	if dialogue_partner != null:
		return
	
	can_trigger = true
	new_observations.clear()
	
	if Time.get_unix_time_from_system() - time_since_last_plan >= planning_duration:
		var current_time = Time.get_datetime_dict_from_unix_time(game_manager.in_game_time)
		_generate_plan({"hour":str(current_time.hour),"minute":str(current_time.minute)})

func _observe():
	# Scan nearby entity nodes
	var space_state = get_world_2d().direct_space_state
	var ray_length = 1000
	var angle = facing_direction.angle() - PI/3
	while angle < facing_direction.angle() + PI/3:
		var direction = Vector2(cos(angle), sin(angle))
		angle += 0.1
		direction *= ray_length
		
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position+direction)
		query.exclude = [self]
		query.collision_mask = 3
		var result = space_state.intersect_ray(query)
		
		# If we haven't detected anything with this ray, move onto the next one
		if result.is_empty():
			continue
		
		# If the current ray didn't hit an entity, move onto the next ray
		if !result.collider.is_in_group("Entity"):
			continue
		
		var new_entity : Entity = result.collider.as_entity
		var already_exists : bool = false
		for existing_observation in new_observations:
			if new_entity.matches(existing_observation):
				already_exists = true
				break
		
		# If this is not a new observation, move onto the next ray
		if already_exists:
			continue
			
		# Add the new observation to the list
		new_observations.append(new_entity.copy())

func _react():
	var reaction_prompt = agent_summary + "\n"
	reaction_prompt += "It is "+game_manager.get_current_datetime_string()+"\n"
	reaction_prompt += agent_name+"'s current action: " + as_entity.description + "\n"
	for task in all_tasks:
		if task.unix_time >= game_manager.in_game_time:
			reaction_prompt += agent_name+"'s current plan:"+task.task+"\n"
			break
	
	reaction_prompt += "Observations (sorted from oldest to newest): \n"
	for i in len(new_observations):
		reaction_prompt += str(i+1)+") "+new_observations[i].description+"\n"
	
	for entity in new_observations:
		_generate_memory_summary("What does "+agent_name+" know about "+entity.entity_name+"?")
	await _collect_responses(new_observations.size())
	
	var response_string = ""
	for response in responses:
		response_string += response + " "
	responses.clear()
	
	if response_string.strip_edges() == "":
		reaction_prompt += agent_name+" has no relevant memories about the given observations.\n"
	else:
		reaction_prompt += "Summary of relevant context about each observation: \n"+response_string

	reaction_prompt += "Should "+agent_name+" continue with their current action, update their action to match the plan, or react to one of the observations?\n"
	reaction_prompt += "Respond only in the following format: [Continue/Update/(ID of observation to ineract with)]|[the immediate action to take]\n"
	reaction_prompt += "Examples:\n"
	reaction_prompt += "Update|going for a walk\n"
	reaction_prompt += "Continue\n"
	reaction_prompt += "Update|taking a shower\n"
	reaction_prompt += "2|talking to Stacy\n"
	reaction_prompt += "1|turning off the oven\n"
	reaction_prompt += "Continue"
	
	var reaction = await game_manager.chat_request(reaction_prompt, 0, 40)
	return reaction

func _pick_location():
	var chosen_node : Node = null
	
	var available_locations: Array = game_manager.get_sub_locations()
	while !available_locations.is_empty():
		var location_prompt = agent_summary + "\n"
		location_prompt += agent_name+" is currently located at "+as_entity.location+"\n"
		location_prompt += agent_name+" knows of the following locations:\n"
		
		for i in len(available_locations):
			location_prompt += str(i+1)+") "+available_locations[i].get_name()+"\n"
		
		location_prompt += agent_name+" is currently planning to "+as_entity.action+"\n"
		location_prompt += "Which area should "+agent_name+" go to? Respond only with the index of the given locations, nothing else. For example:\n1\n5\n3"
	
		var chosen_index = int(await game_manager.chat_request(location_prompt, 0, 2))-1
		if chosen_index >= len(available_locations):
			break
			
		chosen_node = available_locations[chosen_index]
		available_locations = game_manager.get_sub_locations(chosen_node)
	
	if chosen_node == null || chosen_node == previous_destination:
		return
	_set_destination(chosen_node)	

func _reflect():
	is_reflecting = true
	var questions_prompt : String = "Consider the following memories:\n"
	
	var current_token_count : int = 0
	for i in range(len(memories)-1, oldest_memory_index, -1):
		var memory : Memory = memories[i]
		if current_token_count + memory.token_count < 2040:
			questions_prompt += "- "+memory.content+"\n"
			current_token_count += memory.token_count
	
	questions_prompt += "Given only the information above, what are "+str(num_reflection_questions)+" most salient highlevel questions we can ask about the subjects in the statements. "
	questions_prompt += "Respond with only the questions, each on a new line starting with a dash (-) and then the question itself"
	
	var questions = (await game_manager.chat_request(questions_prompt, 0, 150)).split("\n")
	for question in questions:
		if question.strip_edges() == "":
			continue
		_reflection_coroutine(question)
	
	await _collect_responses(num_reflection_questions * num_insights_per_reflection_question)
	
	oldest_memory_index = len(memories)
	is_reflecting = false

func _reflection_coroutine(question):
	var relevant_memories = await _retrieve_memories(question, 10)
	
	var insights_prompt = "Statements about "+agent_name+"\n"
	for memory in relevant_memories:
		insights_prompt += "- "+memory.content+"\n"
	insights_prompt += "What are "+str(num_insights_per_reflection_question)+" high level insights you can infer from the above statements? "
	insights_prompt += "Respond only with the insights, each on a new line starting with a dash (-) and then the insight itself"

	var insights = (await game_manager.chat_request(insights_prompt, 0, 150)).split("\n")
	for insight in insights:
		if insight.strip_edges() == "":
			continue
		_add_memory(insight)
		callback_signal.emit()

func dialogue_setup(partner):
	dialogue_history.clear()
	dialogue_partner = partner
	can_trigger = false
	as_entity.set_action("busy talking with "+partner.as_entity.entity_name)
	_end_navigation()

func initiate_dialogue(partner):
	dialogue_setup(partner)
	
	var first_dialogue_prompt = agent_summary+"\n"
	first_dialogue_prompt += "It is "+game_manager.get_current_datetime_string()+"\n"
	first_dialogue_prompt += "Observation: "+dialogue_partner.as_entity.description+"\n"
	
	first_dialogue_prompt += "Summary of relevant context from "+agent_name+"’s memory:\n"
	await _generate_memory_summary("What is "+agent_name+"'s relationship with "+ dialogue_partner.as_entity.entity_name)
	first_dialogue_prompt += responses[0]
	responses.clear()
	first_dialogue_prompt += "\n"+as_entity.description+"\n. What would "+agent_name+" say to "+dialogue_partner.as_entity.entity_name+"?\n"
	first_dialogue_prompt += "Respond only with the dialogue as if you are in character. Don't start with \""+agent_name+":\" or anything. "
	first_dialogue_prompt += "Don't be overly formal, you have to be in character. Remember "+agent_name+" is "+traits
	
	var first_dialogue = await game_manager.chat_request(first_dialogue_prompt)
	
	conversation_panel.find_child("Label").text += agent_name+": "+first_dialogue+"\n\n"
	
	dialogue_history.append({"agent":agent_name, "statement":first_dialogue})
	if dialogue_partner.is_in_group("Agent"):
		dialogue_partner.receive_dialogue(first_dialogue)
	else:
		game_manager.set_dialogue_text(first_dialogue)

func receive_dialogue(partner_statement):
	dialogue_history.append({"agent":dialogue_partner.agent_name, "statement":partner_statement})
	
	if partner_statement.contains("[end]"):
		self.end_dialogue()
		return
	
	conversation_panel.find_child("Label").text += dialogue_partner.agent_name+": "+partner_statement+"\n\n"
	
	var next_dialogue_prompt = agent_summary+"\n"
	next_dialogue_prompt += "It is "+game_manager.get_current_datetime_string()+"\n"
	next_dialogue_prompt += "Observation: "+dialogue_partner.as_entity.description+"\n"

	next_dialogue_prompt += "Summary of relevant context from "+agent_name+"’s memory:\n"
	_generate_memory_summary("What is " + agent_name + "'s relationship with "+ dialogue_partner.as_entity.entity_name)
	_generate_memory_summary(partner_statement)
	await _collect_responses(2)
	
	if dialogue_partner == null:
		end_dialogue()
		return
	
	for response in responses:
		next_dialogue_prompt += response + " "
	responses.clear()
	
	if partner_statement == "" and len(dialogue_history) == 1:
		next_dialogue_prompt += dialogue_partner.agent_name+" came over to initiate a conversation with "+agent_name+".\n"
	else:
		next_dialogue_prompt += "\nHere is the dialogue history:\n"
		for line in dialogue_history:
			next_dialogue_prompt += line["agent"] + ": " + line["statement"]+"\n"
	
	next_dialogue_prompt += "How would "+agent_name+" respond to "+dialogue_partner.agent_name+"? Give only the response and nothing else\n"
	next_dialogue_prompt += "Respond only with the dialogue as if you are in character. Don't start with \""+agent_name+":\" or anything.\n"
	next_dialogue_prompt += "Don't be overly formal, you have to be in character. Remember "+agent_name+" is "+traits
	
	if !dialogue_partner.is_in_group("Player"):
		next_dialogue_prompt += "If the conversation is nearing its end or becoming repetitive, say one final remark and include the closing tag [end]. For example:\n Okay bye then. [end]"
	
	var next_dialogue = await game_manager.chat_request(next_dialogue_prompt)
	
	conversation_panel.find_child("Label").text += agent_name+": "+next_dialogue+"\n\n"
	
	if dialogue_partner == null:
		end_dialogue()
		return
	
	dialogue_history.append({"agent":agent_name, "statement":next_dialogue})
	
	if dialogue_partner.is_in_group("Agent"):
		dialogue_partner.receive_dialogue(next_dialogue)
		if next_dialogue.contains("[end]"):
			self.end_dialogue()
	else:
		game_manager.set_dialogue_text(next_dialogue)

func end_dialogue():
	conversation_panel.visible = false
	as_entity.set_action("idle")
	
	if dialogue_partner == null:
		print("The following conversation crashed:\n")
		for text in dialogue_history:
			print(text)
		return
		
	var full_dialogue = "Dialogue between "+agent_name+" and "+dialogue_partner.agent_name+" on "+game_manager.get_current_datetime_string()+"\n"
	for line in dialogue_history:
		full_dialogue += line["agent"] + ": " + line["statement"]+"\n"
		
	var reaction_prompt = agent_summary + "\n"
	reaction_prompt += "It is "+game_manager.get_current_datetime_string()+"\n"
	reaction_prompt += agent_name+"'s current action: "+as_entity.description+"\n"
	reaction_prompt += full_dialogue
	reaction_prompt += "Considering the conversation above, should "+agent_name+" react in a certain way or continue with the current action?\n"
	reaction_prompt += "If "+agent_name+" should continue, respond only with \"Continue\".\n" 
	reaction_prompt += "If "+agent_name+" should react, respond only in the following format: React|[new action to take]. For example:\nContinue\nReact|turning off the oven\nContinue\nReact|looking for John"
	
	var reaction : String = await game_manager.chat_request(reaction_prompt, 0, 40)
	
	destination = null
	as_entity.set_interactable(null)
	if "React" in reaction:
		as_entity.set_action(reaction.split("|")[1].strip_edges())
		
		var current_time = Time.get_datetime_dict_from_unix_time(game_manager.in_game_time)
		_generate_plan({"hour":str(current_time.hour),"minute":str(current_time.minute)})
		await _pick_location()	
	else:
		as_entity.set_action("idle")
	
	_add_memory(full_dialogue)
	dialogue_history.clear()
	dialogue_partner = null
	can_trigger = true

func _on_interaction_zone_body_entered(body):
	if destination != body:
		return
	
	facing_direction = body.global_position - global_position
	facing_direction.normalized()
	
	if body.is_in_group("Player"):
		game_manager.enter_new_dialogue(self)
		initiate_dialogue(body)	
	
	elif body.is_in_group("Agent"):
		body.dialogue_setup(self)
		initiate_dialogue(body)
		conversation_panel.visible = true
		conversation_panel.find_child("Label").text = ""
	
	elif body.is_in_group("Item"):
		var item_entity : Entity = body.as_entity
		
		# If someone was already interacting with the destination item, find a similar item to interact with
		if item_entity.interactable != null and item_entity.interactable != as_entity:
			_end_navigation()
			
			# The name of the target item without the number
			var destination_name : String = " ".join(body.get_name().split(" ").slice(0, -1))
			
			# All the items in the target room
			var sibling_nodes : Array = game_manager.get_sub_locations(body.get_parent())
			for node in sibling_nodes:
				# If the current node is not one of the other items in the room, leave
				if node == body or !node.is_in_group("Item"):
					continue
				
				# If the current item is interacting with somebody
				if node.as_entity.interactable != null:
					continue
				
				# If the names of the node and the destination match, set it as the new destination
				var node_name = " ".join(node.get_name().split(" ").slice(0, -1))
				if node_name == destination_name:
					_set_destination(node)
					break
			return
		
		item_entity.set_interactable(as_entity)
		as_entity.set_interactable(item_entity)
		
		var status_update_prompt = "If someone is "+as_entity.action+" and wants to interact with "+item_entity.entity_name+", what would be the new status of "+item_entity.entity_name+"?\n"
		status_update_prompt += "For example, if John wants to make some coffee and he's interacting with a coffee mixer, the mixer's new status should be \"mixing coffee\"."
		status_update_prompt += "Respond only with the status, for example:\nbaking a pie\nburning some wood\nopen"
		var status_update = await game_manager.chat_request(status_update_prompt, 0, 30)
		
		item_entity.set_action(status_update)
	
	_end_navigation()
	
func _on_interaction_zone_body_exited(body):
	if body.is_in_group("Item"):
		var item_entity : Entity = body.as_entity
		
		if item_entity.interactable == as_entity:
			item_entity.set_interactable(null)

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

