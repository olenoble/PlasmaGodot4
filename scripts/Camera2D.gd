extends Camera2D

var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_parent().get_node('Player')
	

func _process(_delta):
	position = player.position
