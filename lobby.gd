extends Node

var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 10
var lobby_vote_kick: bool = false

signal lobby_created
signal lobby_invite
signal lobby_joined
signal lobby_match_list


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_request.connect(_on_p2p_session_connect_fail)
		
	Steam.lobby_match_list.connect(func (lobbies: Array):
		print(lobbies)
		lobby_match_list.emit(lobbies)
		pass
	)
	
	Steam.lobby_created.connect(func(connect: int, new_lobby_id: int):
		# Lobby created
		# Adding metadata
		Steam.setLobbyData(new_lobby_id, "name", "Hello World")
		Steam.setLobbyData(new_lobby_id, "mode", "MAKUDO")
		Steam.setLobbyData(new_lobby_id, "game", "MAKUDO")
		
		lobby_id = new_lobby_id;
		# Allow P2P connections to fallback to being relayed through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)
		lobby_created.emit(connect, new_lobby_id)
		pass
	)
	Steam.lobby_invite.connect(func (inviter: int, lobby: int, game: int):
		# received lobby invite
		lobby_invite.emit(inviter, lobby, game)
		pass
	)
	Steam.lobby_joined.connect(func (lobby: int, permissions: int, locked: bool, response: int):
		# lobby join request response
		if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
			# Set this lobby ID as your lobby ID
			lobby_id = lobby
			# Get the lobby members
			get_lobby_members()
			# Make the initial handshake
			make_p2p_handshake()
			lobby_joined.emit(lobby_id, permissions, locked, response)
		pass
	)
	
	Steam.join_requested.connect(func(this_lobby_id: int, friend_id: int):
				# Get the lobby owner's name
		var owner_name: String = Steam.getFriendPersonaName(friend_id)

		print("Joining %s's lobby..." % owner_name)

		# Attempt to join the lobby
		join_lobby(this_lobby_id)
	)
	
	# Check for command line arguments
	check_command_line()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# If the player is connected, read packets
	if lobby_id > 0:
		read_p2p_packet()
	pass


func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()
	
	# There are arguments to process
	if these_arguments.size() > 0:
		# A Steam connection argument exists
		if these_arguments[0] == "+connect_lobby":
			# Lobby invite exists so try to connect to it
			if int(these_arguments[1]) > 0:
				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				print("Command line lobby ID: %s" % these_arguments[1])
				join_lobby(int(these_arguments[1]))

func create_lobby() -> void:
	# Make sure a lobby is not already set
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_INVISIBLE, lobby_members_max)

func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % this_lobby_id)
	# Clear any previous lobby members lists, if you were in a previous lobby
	lobby_members.clear()
	# Make the lobby join request to Steam
	Steam.joinLobby(this_lobby_id)

func _on_p2p_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)

	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)

	# Make the initial handshake
	make_p2p_handshake()

func _on_p2p_session_connect_fail(steam_id: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % steam_id)

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % steam_id)

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % steam_id)

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % steam_id)

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % steam_id)

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % steam_id)

	# Else no known error
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [steam_id, session_error])

func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()

	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)

	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)

		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		# Add them to the list
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})


func leave_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0

		# Close session with all users
		for this_member in lobby_members:
			# Make sure this isn't your Steam ID
			if this_member['steam_id'] != Steamworks.steam_id:
				# Close the P2P session using the Networking class
				Steam.closeP2PSessionWithUser(this_member['steam_id'])

		# Clear the local lobby list
		lobby_members.clear()

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)

	# Else if a player has left the lobby
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)

	# Else if a player has been kicked
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)

	# Else if a player has been banned
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)

	# Else there was some unknown change
	else:
		print("%s did... something." % changer_name)

	# Update the lobby now that a change has occurred
	get_lobby_members()

func make_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")
	send_p2p_packet(0, {"message": "handshake", "from": Steamworks.steam_id})

func _on_open_lobby_list_pressed() -> void:
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	
	Steam.addRequestLobbyListStringFilter("game", "MAKUDO", Steam.LOBBY_COMPARISON_EQUAL)
	
	print("Requesting a lobby list")
	Steam.requestLobbyList()

func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)

	# There is a packet
	if packet_size > 0:
		print("Reading p2p packet")
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)

		if this_packet.is_empty() or this_packet == null:
			print("WARNING: read an empty packet with non-zero size!")

		# Get the remote user's ID
		var packet_sender: int = this_packet['remote_steam_id']

		# Make the packet data readable
		var packet_code: PackedByteArray = this_packet['data']
		var readable_data: Dictionary = bytes_to_var(packet_code)

		# Print the packet to output
		print("Packet: %s" % readable_data)

		# Append logic here to deal with packet data


func send_p2p_packet(this_target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0

	# Create a data array to send the data through
	var this_data: PackedByteArray
	this_data.append_array(var_to_bytes(packet_data))

	# If sending a packet to everyone
	if this_target == 0:
		# If there is more than one user, send packets
		if lobby_members.size() > 1:
			# Loop through all members that aren't you
			for this_member in lobby_members:
				if this_member['steam_id'] != Steamworks.steam_id:
					Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)
	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)
