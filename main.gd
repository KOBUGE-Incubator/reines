
extends Control

var con
var connected = false
var cst
# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	# Initialization here
	pass

func add_to_log(s):
	# TODO @alket connect this to gui, not console output
	print(s)

func parse_var(v):
	if ((typeof(v) == TYPE_ARRAY) and (v.size() >= 2)):
		var m = v[0]
		if (m == "chat"):
			if (v.size() >= 3):
				add_to_log(str("[", v[1], "] ", v[2]))
		elif (m == "nick"):
			if (v.size() >= 3):
				add_to_log(str("*** ", v[1], " is now called ", v[2]))
		elif (m == "join"):
			add_to_log(str("*** ", v[1], " joined the lobby"))
		elif (m == "part"):
			add_to_log(str("*** ", v[1], " left the lobby"))

func upd_chat():
	if (connected):
		if (cst.get_available_packet_count() > 0):
			parse_var(cst.get_var())


func _connect_pressed():
	con = StreamPeerTCP.new()
	var addr = get_node("LineEdit_ip").get_text()
	con.connect(addr, 40000)
	connected = con.is_connected()
	cst = PacketPeerStream.new()
	cst.set_stream_peer(con)
	cst.put_var(["nick", get_node("LineEdit_nick").get_text()])

func _send_pressed():
	upd_chat()
	cst.put_var(["chat", get_node("LineEdit_text").get_text()])
	upd_chat()