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
signal lobby_kicked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		
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
			
			lobby_joined.emit(lobby_id, permissions, locked, response)
		pass
	)
	
	Steam.lobby_kicked.connect(func (lobby_id: int, admin_id: int, due_to_disconnect: int):
		lobby_id = 0
		lobby_kicked.emit(lobby_id, admin_id, due_to_disconnect)
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


func _on_open_lobby_list_pressed() -> void:
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	
	Steam.addRequestLobbyListStringFilter("game", "MAKUDO", Steam.LOBBY_COMPARISON_EQUAL)
	
	print("Requesting a lobby list")
	Steam.requestLobbyList()
