extends CanvasModulate

var time:float=0.0
@export var gradient:GradientTexture1D

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta:float):
	time+=delta
	var value=(sin(time -PI/2)+1.0)/2
	self.color=gradient.gradient.sample(value)
