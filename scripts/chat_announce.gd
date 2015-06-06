extends TextEdit



func _ready():
	#this text could be set by a http request, very low priority.
	set_text("Welcome to Reines. Please set your name and connect to a server.\n")