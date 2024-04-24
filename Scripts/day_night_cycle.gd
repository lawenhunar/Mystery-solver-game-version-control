extends CanvasModulate

@export var gradient:GradientTexture1D
@onready var game_manager = $"../../GameManager"

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta:float):
	var time1=game_manager.get_current_datetime_string()
	var time2=get_hour_from_time(time1)
	#print(time2)
	# Adjust the time to start from 0 at 8 pm (20:00)
	var adjusted_time = (time2 - 8) % 24  # Ensure the result stays within 0-23
	# Calculate the phase based on adjusted time
	var phase = (adjusted_time / 24.0) * 2 * PI  # Convert time to radians
	var value=(sin(phase)+1.0)/2
	self.color=gradient.gradient.sample(value)

func get_hour_from_time(time_str: String) -> int:
	# Split the time string by colon (:) to separate hours, minutes, and seconds
	var date_parts := time_str.split(",")
	var time_parts :=date_parts[2].split(":")
	# Get the hour part (index 0 after splitting)
	var hour_str := time_parts[0].trim_prefix(" ") # Remove leading/trailing spaces
	# Convert the hour string to an integer
	var hour := hour_str.to_int()
	return hour
