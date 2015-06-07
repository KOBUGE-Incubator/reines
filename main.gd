
extends Control

var con
var connected = false
var cst
var nick_list = []
var pollthread

func _ready():
	pollthread = Thread.new()
	pollthread.start(self, "poll_thr", self)
	# Initialization here
	pass

func add_to_log(s):
	get_node("ItemList_chat").add_item(s)

func upd_nicks_list():
	var nl = get_node("ItemList_users")
	nl.clear()
	for n in nick_list:
		nl.add_item(n)

func parse_var(v):
	if ((typeof(v) == TYPE_ARRAY) and (v.size() >= 2)):
		var m = v[0]
		if (m == "chat"):
			if (v.size() >= 3):
				add_to_log(str("[", v[1], "] ", v[2]))
		elif (m == "nick"):
			if (v.size() >= 3):
				add_to_log(str("*** ", v[1], " is now called ", v[2]))
				var idx = nick_list.find(v[1])
				nick_list[idx] = v[2]
				upd_nicks_list()
		elif (m == "nicks"):
			nick_list = v[1]
			upd_nicks_list()
		elif (m == "join"):
			add_to_log(str("*** ", v[1], " joined the lobby"))
			nick_list.push_back(v[1])
			upd_nicks_list()
		elif (m == "part"):
			add_to_log(str("*** ", v[1], " left the lobby"))
			var idx = nick_list.find(v[1])
			nick_list.remove(idx)
			upd_nicks_list()

func upd_chat():
	if (connected):
		if (cst.get_available_packet_count() > 0):
			parse_var(cst.get_var())

func poll_thr(v):
	while (true):
		v.call_deferred("upd_chat")
		OS.delay_msec(100)

func _connect_pressed():
	con = StreamPeerTCP.new()
	var addr = get_node("LineEdit_ip").get_text()
	con.connect(addr, 40000)
	connected = con.is_connected()
	cst = PacketPeerStream.new()
	cst.set_stream_peer(con)
	cst.put_var(["nick", get_node("LineEdit_nick").get_text()])

func _send_pressed():
	var n = get_node("LineEdit_text")
	var msg = n.get_text()
	if msg.length() > 0:
		cst.put_var(["chat", msg])
		n.clear()


func _on_LineEdit_text_enter_pressed(text):
	_send_pressed()
