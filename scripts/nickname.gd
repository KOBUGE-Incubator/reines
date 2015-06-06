extends LineEdit

func _ready():
	randomize()
	set_text("Guest_"+str(randi()%999))