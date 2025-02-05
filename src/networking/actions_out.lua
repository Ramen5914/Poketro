PKTR.send = {}

PKTR.pending_messages = {}
PKTR.MAX_RETRIES = 5

local cached_username = nil

function PKTR.networking.initialize()
	if not PKTR.networking.NETWORKING_THREAD then
		local SOCKET = load_pktr_file("src/networking/server.lua")
		PKTR.networking.NETWORKING_THREAD = love.thread.newThread(SOCKET)
		PKTR.networking.NETWORKING_THREAD:start(
			SMODS.Mods["Poketro"].config.server_url,
			SMODS.Mods["Poketro"].config.server_port
		)

		PKTR.send.connect()
	end
end

PKTR.retry_event = Event({
	trigger = "after",
	blockable = false,
	blocking = false,
	delay = 3,
	pause_force = true,
	no_delete = true,
	timer = "REAL",
	func = function(t)
		local messages_to_remove = {}

		for msg_id, pending in pairs(PKTR.pending_messages) do
			pending.retries = pending.retries + 1

			if pending.retries >= PKTR.MAX_RETRIES then
				PKTR.send_warn_message("Message " .. pending.action .. " failed after " .. PKTR.MAX_RETRIES .. " retries")
				messages_to_remove[#messages_to_remove + 1] = msg_id

				if PKTR.network_state.lobby then
					PKTR.send.leave_lobby()
				end
			else
				PKTR.send_trace_message(
					"Retrying message " .. pending.action .. " (attempt " .. pending.retries + 1 .. ")"
				)
				PKTR.networking.ui_to_network_channel:push(pending.raw_message)
			end
		end

		for _, msg_id in ipairs(messages_to_remove) do
			PKTR.pending_messages[msg_id] = nil
		end

		PKTR.retry_event.start_timer = false
	end,
})

G.E_MANAGER:add_event(PKTR.retry_event)

function PKTR.send.raw(msg)
	local raw_msg
	if type(msg) == "table" then
		if PKTR.EXPECTED_RESPONSES[msg.action] then
			local msg_id = os.time() .. "_" .. msg.action
			PKTR.pending_messages[msg_id] = {
				action = msg.action,
				retries = 0,
				expected_response = PKTR.EXPECTED_RESPONSES[msg.action],
				raw_message = PKTR.serialize_networking_message(msg),
			}
		end
		raw_msg = PKTR.serialize_networking_message(msg)
	else
		raw_msg = msg
	end

	PKTR.send_trace_message("Sending message: " .. raw_msg)
	PKTR.networking.ui_to_network_channel:push(raw_msg)
end

function PKTR.send.connect()
	PKTR.send.raw("connect")

	cached_username = G.PROFILES[G.SETTINGS.profile].name or "Guest"
	PKTR.send.raw({
		action = "connect",
		username = cached_username,
	})
end

function PKTR.send.open_lobby()
	PKTR.send.raw({
		action = "open_lobby",
	})
end

function PKTR.send.join_lobby(code, checking)
	PKTR.send.raw({
		action = "join_lobby",
		code = code:gsub("[oO]", "0"), -- Replaces the letter O with the number 0 because Balatro has a vendetta against zeros
		checking = checking or false,
	})
end

function PKTR.send.leave_lobby()
	PKTR.send.raw({
		action = "leave_lobby",
	})
	if G.STAGE == G.STAGES.RUN then
		G.FUNCS.go_to_menu()
	end
end
G.FUNCS.pktr_leave_lobby = PKTR.send.leave_lobby

function PKTR.send.return_to_lobby()
	PKTR.send.raw({
		action = "return_to_lobby",
		from = PKTR.network_state.code,
	})
	if G.STAGE == G.STAGES.RUN then
		G.FUNCS.go_to_menu()
	end
end
G.FUNCS.pktr_return_to_lobby = PKTR.send.return_to_lobby

function PKTR.send.set_username()
	local new_username = G.PROFILES[G.SETTINGS.profile].name or "Guest"
	if cached_username == new_username then
		return
	end
	cached_username = new_username
	PKTR.send.raw({
		action = "set_username",
		username = new_username,
	})
end

function PKTR.send.request_lobby_sync()
	PKTR.send.raw({
		action = "request_lobby_sync",
		from = PKTR.network_state.code,
		to = PKTR.network_state.lobby,
	})
end

function PKTR.send.start_run(choices)
	PKTR.game_state.players = PKTR.lobby_state.players
	for i, _ in ipairs(PKTR.game_state.players) do
		PKTR.game_state.players[i].lives = PKTR.lobby_state.config.starting_lives
		PKTR.game_state.players[i].location = "loc_selecting"
		PKTR.game_state.players[i].skips = 0
		PKTR.game_state.players[i].score = 0
		PKTR.game_state.players[i].score_text = "0"
		PKTR.game_state.players[i].hands_left = 4
	end
	PKTR.game_state.lives = PKTR.lobby_state.config.starting_lives
	PKTR.send.raw({
		action = "start_run",
		choices = PKTR.table_to_networking_message(choices),
		game_players = PKTR.table_to_networking_message(PKTR.game_state.players),
		lobby_config = PKTR.table_to_networking_message(PKTR.lobby_state.config),
	})
end

function PKTR.send.request_ante_info()
	PKTR.send.raw({
		action = "request_ante_info",
		from = PKTR.network_state.code,
		to = PKTR.network_state.lobby,
		ante = G.GAME.round_resets.ante,
	})
end

function PKTR.send.ready_blind(e)
	PKTR.game_state.ready_blind_context = e
	local args = {
		action = "ready_blind",
		from = PKTR.network_state.code,
	}
	PKTR.send.raw(args)
	PKTR.networking.funcs.ready_blind(args)
end

function PKTR.send.unready_blind()
	local args = {
		action = "unready_blind",
		from = PKTR.network_state.code,
	}
	PKTR.send.raw(args)
	PKTR.networking.funcs.unready_blind(args)
end

function PKTR.send.play_hand(score, hands_left)
	local args = {
		action = "play_hand",
		score = PKTR.table_to_networking_message(score),
		hands_left = tostring(hands_left),
		from = PKTR.network_state.code,
	}
	PKTR.send.raw(args)
	PKTR.networking.funcs.play_hand(args)
end

function PKTR.send.set_location(loc)
	local args = {
		action = "set_location",
		location = loc,
		from = PKTR.network_state.code,
	}
	PKTR.send.raw(args)
	PKTR.networking.funcs.set_location(args)
end

function PKTR.send.set_skips(skips)
	local args = {
		action = "set_skips",
		skips = tostring(skips),
		from = PKTR.network_state.code,
	}
	PKTR.send.raw(args)
	PKTR.networking.funcs.set_skips(args)
end

function PKTR.send.fail_round()
	PKTR.send.lose_life(PKTR.network_state.code)
end

function PKTR.send.end_pvp()
	PKTR.send.raw({
		action = "end_pvp",
	})
	PKTR.networking.funcs.end_pvp()
end

function PKTR.send.lose_life(to)
	local args = {
		action = "lose_life",
		to = to,
	}
	PKTR.send.raw(args)
	PKTR.networking.funcs.lose_life(args)
end

function PKTR.send.win(to)
	local args = {
		action = "win",
		to = to,
	}
	PKTR.send.raw(args)
	PKTR.networking.funcs.win(args)
end
