PKTR.networking.funcs = {}

PKTR.EXPECTED_RESPONSES = {
	connect = "connect_ack",
	set_username = "set_username_ack",
	open_lobby = "open_lobby_ack",
	join_lobby = "join_lobby_ack",
	request_lobby_sync = "request_lobby_sync_ack",
	request_ante_info = "request_ante_info_ack",
}

function PKTR.networking.handle_network_message(message)
	if message == "action:keep_alive_ack" then
		return
	end

	PKTR.send_trace_message("Received message: " .. message)
	local msg_obj = PKTR.parse_networking_message(message)

	for msg_id, pending in pairs(PKTR.pending_messages) do
		if msg_obj.action == pending.expected_response then
			PKTR.pending_messages[msg_id] = nil
			break
		end
	end

	if msg_obj.action and PKTR.networking.funcs[msg_obj.action] then
		PKTR.networking.funcs[msg_obj.action](msg_obj)
	else
		PKTR.send_warn_message("Received message with unknown action: " .. msg_obj.action)
	end
end

function PKTR.networking.funcs.connect_ack(args)
	if not args or not args.code then
		PKTR.send_warn_message("Got connect_ack with invalid args")
		return
	end

	PKTR.network_state.username = args.username or "Guest"
	PKTR.network_state.connected = true
	PKTR.network_state.code = args.code

	PKTR.draw_lobby_ui()
end

function PKTR.networking.funcs.set_username_ack(args)
	if not args or not args.username then
		PKTR.send_warn_message("Got set_username_ack with invalid args")
		return
	end

	PKTR.network_state.username = args.username
end

function PKTR.networking.funcs.error(args)
	if not args or not args.message then
		PKTR.send_warn_message("Got error with no message")
		return
	end

	PKTR.UI.show_pktr_overlay_message(args.message)
	PKTR.send_warn_message(args.message)
end

function PKTR.networking.funcs.disconnected(args)
	PKTR.network_state.connected = false
	PKTR.network_state.code = nil

	PKTR.networking.funcs.leave_lobby_ack()

	PKTR.send_warn_message("Disconnected from server")
end

function PKTR.networking.funcs.open_lobby_ack(args)
	PKTR.network_state.lobby = PKTR.network_state.code

	PKTR.lobby_state.players[1] = {
		username = PKTR.network_state.username,
		code = PKTR.network_state.code,
	}

	PKTR.draw_lobby_ui()
end

function PKTR.networking.funcs.leave_lobby_ack(args)
	PKTR.network_state.lobby = nil

	PKTR.draw_lobby_ui()
end

function PKTR.networking.funcs.join_lobby_ack(args)
	if not args then
		PKTR.send_warn_message("Got join_lobby_ack with invalid args")
		return
	end

	if not args.code then
		PKTR.UI.create_join_lobby_overlay()
		return
	end

	PKTR.network_state.lobby = args.code

	PKTR.send.request_lobby_sync()

	PKTR.draw_lobby_ui()
end

function PKTR.networking.funcs.player_joined(args)
	if not args or not args.code or not args.username then
		PKTR.send_warn_message("Got player_joined with invalid args")
		return
	end

	PKTR.lobby_state.players[#PKTR.lobby_state.players + 1] = {
		username = args.username,
		code = args.code,
	}
end

function PKTR.networking.funcs.player_left(args)
	if not args or not args.code then
		PKTR.send_warn_message("Got player_joined with invalid args")
		return
	end

	local player_index = PKTR.get_lobby_player_by_code(args.code)

	if player_index == 0 then
		return
	end

	table.remove(PKTR.lobby_state.players, player_index)

	local game_player_index = PKTR.get_game_player_by_code(args.code)

	if game_player_index == 0 or PKTR.game_state.players[game_player_index] == nil then
		return
	end

	PKTR.game_state.players[game_player_index].lives = 0
end

function PKTR.networking.funcs.return_to_lobby(args)
	if not args or not args.from then
		PKTR.send_warn_message("Got return_to_lobby with invalid args")
		return
	end

	local game_player_index = PKTR.get_game_player_by_code(args.code)

	if game_player_index == 0 or PKTR.game_state.players[game_player_index] == nil then
		return
	end

	PKTR.game_state.players[game_player_index].lives = 0
end

function PKTR.networking.funcs.request_lobby_sync(args)
	if not args or not args.from then
		PKTR.send_warn_message("Got request_lobby_sync with invalid args")
		return
	end

	local data = PKTR.deep_copy(PKTR.lobby_state)

	PKTR.send.raw({
		action = "request_lobby_sync_ack",
		from = PKTR.network_state.code,
		to = args.from,
		data = PKTR.table_to_networking_message(data),
	})
end

function PKTR.networking.funcs.request_lobby_sync_ack(args)
	if not args or not args.data then
		PKTR.send_warn_message("Got request_lobby_sync_ack with invalid args")
		return
	end

	local parsed_data = PKTR.networking_message_to_table(args.data)
	PKTR.lobby_state = parsed_data
end

function PKTR.networking.funcs.start_run(args)
	if not args or not args.choices or not args.game_players or not args.lobby_config then
		PKTR.send_warn_message("Got start_run with invalid args")
		return
	end

	local parsed_choices = PKTR.networking_message_to_table(args.choices)
	local parsed_players = PKTR.networking_message_to_table(args.game_players)
	local parsed_lobby_config = PKTR.networking_message_to_table(args.lobby_config)
	PKTR.game_state.players = parsed_players
	PKTR.lobby_state.config = parsed_lobby_config
	PKTR.game_state.lives = PKTR.lobby_state.config.starting_lives
	G.FUNCS.start_run(nil, parsed_choices)
end

function PKTR.networking.funcs.request_ante_info(args)
	if not args or not args.ante or not args.from then
		PKTR.send_warn_message("Got request_ante_info with invalid args")
		return
	end

	local ante_num = tonumber(args.ante)

	if ante_num == nil then
		PKTR.send_warn_message("Got request_ante_info with non-number ante")
		return
	end

	if not PKTR.game_state.blinds_by_ante[ante_num] then
		PKTR.generate_blinds_by_ante(ante_num)
	end

	PKTR.send.raw({
		action = "request_ante_info_ack",
		from = PKTR.network_state.code,
		to = args.from,
		data = PKTR.table_to_networking_message(PKTR.game_state.blinds_by_ante[ante_num]),
		ante = args.ante,
	})
end

function PKTR.networking.funcs.request_ante_info_ack(args)
	if not args or not args.data or not args.ante then
		PKTR.send_warn_message("Got request_ante_info_ack with invalid args")
		return
	end

	local ante_num = tonumber(args.ante)

	if ante_num == nil then
		PKTR.send_warn_message("Got request_ante_info_ack with non-number ante")
		return
	end

	local parsed_data = PKTR.networking_message_to_table(args.data)

	PKTR.game_state.blinds_by_ante[ante_num] = parsed_data
end

PKTR.ready_blind_event_started = false
PKTR.ready_blind_event = Event({
	trigger = "immediate",
	blockable = false,
	blocking = false,
	func = function()
		if PKTR.game_state.players_ready >= #PKTR.get_alive_players() then
			PKTR.send.raw({
				action = "start_blind",
			})
			PKTR.networking.funcs.start_blind()
			PKTR.game_state.players_ready = 0
			PKTR.ready_blind_event_started = false
			return true
		end
		return false
	end,
})

function PKTR.networking.funcs.ready_blind(args)
	PKTR.game_state.players_ready = PKTR.game_state.players_ready + 1
	if PKTR.is_host() and not PKTR.ready_blind_event_started then
		PKTR.ready_blind_event_started = true
		G.E_MANAGER:add_event(PKTR.ready_blind_event)
	end
end

function PKTR.networking.funcs.unready_blind(args)
	PKTR.game_state.players_ready = PKTR.game_state.players_ready - 1
end

function PKTR.networking.funcs.start_blind(args)
	if PKTR.game_state.ready_blind_context then
		G.FUNCS.select_blind(PKTR.game_state.ready_blind_context)
	end
end

function PKTR.networking.funcs.host_migration(args)
	if not args or not args.code then
		PKTR.send_warn_message("Got host_migration with invalid args")
		return
	end

	PKTR.network_state.lobby = args.code

	if PKTR.is_host() then
		PKTR.UI.show_pktr_overlay_message(localize("new_host"))
	end
end

function PKTR.networking.funcs.play_hand(args)
	if not args or not args.from or not args.score or not args.hands_left then
		PKTR.send_warn_message("Got play_hand with invalid args")
		return
	end

	local score = PKTR.networking_message_to_table(args.score)
	local player_index = PKTR.get_game_player_by_code(args.from)

	if player_index == 0 or PKTR.game_state.players[player_index] == nil then
		return
	end

	PKTR.game_state.players[player_index].score = PKTR.readd_talisman_metavalues(score)
	PKTR.game_state.players[player_index].hands_left = tonumber(args.hands_left)

	PKTR.UI.update_blind_HUD(false)
end

function PKTR.networking.funcs.set_location(args)
	if not args or not args.from or not args.location then
		PKTR.send_warn_message("Got set_location with invalid args")
		return
	end

	local player_index = PKTR.get_game_player_by_code(args.from)

	if player_index == 0 or PKTR.game_state.players[player_index] == nil then
		return
	end

	PKTR.game_state.players[player_index].location = args.location
end

function PKTR.networking.funcs.set_skips(args)
	if not args or not args.from or not args.skips then
		PKTR.send_warn_message("Got set_skips with invalid args")
		return
	end

	local player_index = PKTR.get_game_player_by_code(args.from)

	if player_index == 0 or PKTR.game_state.players[player_index] == nil then
		return
	end

	PKTR.game_state.players[player_index].skips = tonumber(args.skips)
end

function PKTR.networking.funcs.end_pvp(args)
	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		blockable = false,
		blocking = false,
		func = function()
			if G.STATE_COMPLETE then
				G.STATE_COMPLETE = false
				G.STATE = G.STATES.WAITING_ON_PVP_END
				PKTR.game_state.end_pvp = true
				return true
			end
			return false
		end,
	}))
end

function PKTR.networking.funcs.lose_life(args)
	if not args or not args.to then
		PKTR.send_warn_message("Got lose_life with invalid args")
		return
	end

	local player_index = PKTR.get_game_player_by_code(args.to)

	if player_index == 0 or PKTR.game_state.players[player_index] == nil then
		return
	end

	PKTR.game_state.players[player_index].lives = PKTR.game_state.players[player_index].lives - 1

	if PKTR.network_state.code == args.to then
		PKTR.game_state.comeback_bonus_given = false
		PKTR.game_state.comeback_bonus = PKTR.game_state.comeback_bonus + 1
		PKTR.game_state.lives = PKTR.game_state.players[player_index].lives
		ease_lives(-1)
		PKTR.game_state.failed = true
		if PKTR.game_state.lives == 0 then
			PKTR.game_over()
		end
	end

	if PKTR.is_host() then
		local alive_players = PKTR.get_alive_players()
		if #alive_players == 1 then
			PKTR.send.win(alive_players[1].code)
		end
	end
end

function PKTR.networking.funcs.win(args)
	if not args or not args.to then
		PKTR.send_warn_message("Got win with invalid args")
		return
	end

	if PKTR.network_state.code == args.to then
		win_game()
		G.GAME.won = true
	end
end
