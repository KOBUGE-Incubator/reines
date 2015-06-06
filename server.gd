# the server part. currently only implements chat
# execute this using godot -s httpd.gd

extends SceneTree

var srv = TCP_Server.new()
var csts = []
var cst_mt = Mutex.new()

func add_cst(cst):
	cst_mt.lock()
	csts.push_back(cst)
	cst_mt.unlock()

func rem_cst(cst):
	cst_mt.lock()
	var idx = csts.find(cst)
	if (idx >= 0):
		csts.remove(idx)
	cst_mt.unlock()

func send_to_all(content):
	cst_mt.lock()
	print(str("send: ", content))
	for cst in csts:
		# TODO add connected check here, we might get a msg from sb right after one closed connection, and before the cst got removed
		cst.put_var(content)
	cst_mt.unlock()

func nick_is_valid(nick):
	for c in nick:
		if (not(("a" < c < "z") or ("A" < c < "Z") or ("0" < c < "9"))):
			return false
	return true

func run_thrd(params):
	var con = params.con
	#if (con.is_connected()):
	#	print("connection is connected")
	#else:
	#	print("connection is NOT connected")
	var cst = PacketPeerStream.new()
	cst.set_stream_peer(con)
	add_cst(cst)
	var first = true
	var nick = "Guest_" + str(randi() % 999)
	# TODO think of message to send to user "sorry you sent no nick, or your nick was invalid, your nick is now: ABC"

	var closecon
	while (con.is_connected()):
		while (cst.get_available_packet_count() == 0 and con.is_connected()): # TODO replace this with actual blocking
			OS.delay_msec(100)
		if (not con.is_connected()):
			break
		var v = cst.get_var()
		if ((typeof(v) == TYPE_ARRAY) and (v.size() >= 2)):
			var m = v[0]
			if (m == "chat"):
				send_to_all(["chat", nick, v[1]])
			elif (m == "nick"):
				if (first):
					nick = v[1]
				else:
					var newnick = v[1]
					send_to_all(["nick", nick, newnick])
					nick = newnick
			else:
				print(str("client sent unsupported msg '", m, "'!"))
				pass
		if (first):
			first = false
			send_to_all(["join", nick])

	rem_cst(cst)
	send_to_all(["part", nick])
	con.disconnect()

	# hack to free the thread reference after it has exited
	# godot has no native protection here, and can
	# free a running thread if all references are lost
	# The call below saves the reference until the method
	# can be called, and gives additional safety by calling
	# wait_to_finish and not some arbitrary method, to account for
	# the engine or the OS doing other tasks on the thread
	# before actually declaring a thread to be "finished"
	params.thread.call_deferred("wait_to_finish")

func _init():
	var port = 40000
	srv.listen(port)
	print(str("Server listening at port ", port))

	while (true):
		while (!srv.is_connection_available()): # TODO replace this with actual blocking
			OS.delay_msec(100)
		var cn = srv.take_connection()
		var thread = Thread.new()
		thread.start(self, "run_thrd", {con=cn, thread=thread})
	quit() 
