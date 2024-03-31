extends Panel

@onready var game_manager = get_node("/root/Main/GameManager")

@onready var dialogue_text = $"Dialogue Text"
@onready var agent_icon = $"Agent Icon"
@onready var agent_name = $"Agent Name"
@onready var player_input_box = $"Player Input Box"
@onready var talk_button = $"Talk Button"
@onready var leave_button = $"Leave Button"

func initialize_with_agent(agent):
	agent_icon.texture = agent.icon
	agent_name.text = agent.agent_name
	dialogue_text.text = "..."
	talk_button.disabled = true


func _on_talk_button_pressed():
	game_manager.send_dialogue_text(player_input_box.text)
	player_input_box.text = ""
	dialogue_text.text = "..."
	talk_button.disabled = true


func _on_leave_button_pressed():
	game_manager.exit_dialogue()
	
func on_agent_talk(agent_dialogue):
	dialogue_text.text = agent_dialogue
	talk_button.disabled = false
	


