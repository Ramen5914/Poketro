G.STATES.WAITING_ON_ANTE_INFO = 20
G.STATES.WAITING_ON_PVP_END = 21

function PKTR.update_waiting_on_ante_info(dt)
	if not G.STATE_COMPLETE then
		if not PKTR.game_state.blinds_by_ante[G.GAME.round_resets.ante] then
			if PKTR.is_host() then
				PKTR.generate_blinds_by_ante(G.GAME.round_resets.ante)
			else
				PKTR.send.request_ante_info()
			end
		end
		G.STATE_COMPLETE = true
	end
	if PKTR.game_state.blinds_by_ante[G.GAME.round_resets.ante] then
		local choices = PKTR.game_state.blinds_by_ante[G.GAME.round_resets.ante]
		G.GAME.round_resets.blind_choices.Small = choices[1]
		G.GAME.round_resets.blind_choices.Big = choices[2]
		G.GAME.round_resets.blind_choices.Boss = choices[3]
		G.STATE = G.STATES.BLIND_SELECT
		G.STATE_COMPLETE = false
	end
end

function PKTR.update_waiting_on_pvp_end(dt)
	if not G.STATE_COMPLETE then
		G.STATE_COMPLETE = true
	end

	if PKTR.game_state.end_pvp then
		PKTR.game_state.end_pvp = false
		G.hand:unhighlight_all()
		G.FUNCS.draw_from_hand_to_deck()
		G.FUNCS.draw_from_discard_to_deck()
		G.STATE = G.STATES.NEW_ROUND
		G.STATE_COMPLETE = false
	end
end

function PKTR.generate_blinds_by_ante(ante)
	PKTR.game_state.blinds_by_ante[ante] = {
		"bl_small",
		"bl_big",
		"bl_pktr_horde",
	}
end

function PKTR.game_over()
	G.STATE_COMPLETE = false
	Game:update_game_over()
end
