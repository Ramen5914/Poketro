function PKTR.UI.BTN.open_lobby(e)
	PKTR.send.open_lobby()
end
G.FUNCS.pktr_open_lobby = PKTR.UI.BTN.open_lobby

function PKTR.UI.BTN.join_lobby(e)
	local clip = PKTR.get_from_clipboard()

	if type(clip) == "string" and clip ~= "" then
		local trimmed = clip:match("^%s*(.-)%s*$")
		if trimmed:match("^[%w][%w][%w][%w][%w][%w]$") ~= nil then
			PKTR.send.join_lobby(trimmed, true)
			return
		end
	end

	PKTR.UI.create_join_lobby_overlay()
end
G.FUNCS.pktr_join_lobby = PKTR.UI.BTN.join_lobby

function PKTR.UI.BTN.reconnect(e)
	PKTR.send.connect()
end
G.FUNCS.pktr_reconnect = PKTR.UI.BTN.reconnect

function PKTR.UI.BTN.copy_code(e)
	e.config.colour = G.C.GREEN
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		blockable = false,
		blocking = false,
		timer = "REAL",
		delay = 1,
		func = function(t)
			e.config.colour = G.C.BLUE
			return true
		end,
	}))
	PKTR.copy_to_clipboard(PKTR.network_state.lobby)
end
G.FUNCS.pktr_copy_code = PKTR.UI.BTN.copy_code

local set_main_menu_UI_ref = set_main_menu_UI
function PKTR.UI.set_main_menu_UI()
	set_main_menu_UI_ref()

	PKTR.draw_lobby_ui()
end
set_main_menu_UI = PKTR.UI.set_main_menu_UI

function PKTR.draw_lobby_ui()
	if PKTR.LOBBY_UI then
		PKTR.LOBBY_UI:remove()
	end

	if G.MAIN_MENU_UI then
		PKTR.LOBBY_UI = UIBox({
			definition = PKTR.create_UIBox_lobby(),
			config = { align = "tl", offset = { x = 1.5, y = -10 }, major = G.ROOM_ATTACH, bond = "Weak" },
		})
		PKTR.LOBBY_UI.alignment.offset.y = PKTR.network_state.connected and 3 or 2.2
		PKTR.LOBBY_UI:align_to_major()
	end
end

function PKTR.UI.create_join_lobby_overlay()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			padding = 0,
			contents = {
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0, draw_layer = 1, minw = 4 },
					nodes = {
						create_tabs({
							tabs = {
								{
									label = "Join Via Code",
									chosen = true,
									tab_definition_function = PKTR.UI.DEF.join_lobby_overlay,
								},
								{
									label = "Quick Play",
									tab_definition_function = PKTR.UI.DEF.quick_play_overlay,
								},
							},
							snap_to_nav = true,
						}),
					},
				},
			},
		}),
	})
end

function PKTR.create_UIBox_lobby()
	local text_scale = 0.45

	local lobby_ui_btns = {
		{
			n = G.UIT.R,
			config = { align = "tm" },
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = PKTR.version,
						shadow = true,
						scale = text_scale * 0.65,
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		},
		{
			n = G.UIT.B,
			config = { align = "tm", minw = 1, minh = 1 },
		},
	}

	if PKTR.is_in_lobby() then
		table.insert(
			lobby_ui_btns,
			UIBox_button({
				id = "main_menu_copy_code",
				button = "pktr_copy_code",
				colour = G.C.BLUE,
				minw = 2,
				minh = 1,
				label = { localize("b_copy_code") },
				scale = text_scale,
			})
		)
		table.insert(
			lobby_ui_btns,
			UIBox_button({
				id = "main_menu_leave_lobby",
				button = "pktr_leave_lobby",
				colour = G.C.RED,
				minw = 2,
				minh = 1,
				label = { localize("b_leave_lobby") },
				scale = text_scale,
			})
		)
	elseif PKTR.network_state.connected then
		table.insert(
			lobby_ui_btns,
			UIBox_button({
				id = "main_menu_open_lobby",
				button = "pktr_open_lobby",
				colour = PKTR.badge_colour,
				minw = 2,
				minh = 1,
				label = { localize("b_open_lobby") },
				scale = text_scale,
			})
		)
		table.insert(
			lobby_ui_btns,
			UIBox_button({
				id = "main_menu_join_lobby",
				button = "pktr_join_lobby",
				colour = G.C.PURPLE,
				minw = 2,
				minh = 1,
				label = { localize("b_join_lobby") },
				scale = text_scale,
			})
		)
	else
		table.insert(lobby_ui_btns, {
			n = G.UIT.R,
			config = { align = "tm" },
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = localize("not_connected"),
						shadow = true,
						scale = text_scale * 0.5,
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		})
		table.insert(
			lobby_ui_btns,
			UIBox_button({
				id = "main_menu_reconnect",
				button = "pktr_reconnect",
				colour = G.C.PURPLE,
				minw = 2,
				minh = 1,
				label = { localize("b_reconnect") },
				scale = text_scale,
			})
		)
	end

	local t = {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "bm" },
				nodes = {
					{
						n = G.UIT.C,
						config = {
							align = "cm",
							padding = 0.2,
							r = 0.1,
							emboss = 0.1,
							colour = G.C.L_BLACK,
							mid = true,
						},
						nodes = lobby_ui_btns,
					},
				},
			},
		},
	}
	return t
end

function PKTR.UI.DEF.join_lobby_overlay()
	local t = {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.1, minh = 0.8 },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							create_text_input({
								w = 4,
								max_length = 6,
								prompt_text = localize("k_enter_code"),
								ref_table = PKTR.temp_vals,
								ref_value = "code",
								all_caps = true,
								callback = function()
									if G.OVERLAY_MENU then
										G.FUNCS:exit_overlay_menu()
									end
									PKTR.send.join_lobby(PKTR.temp_vals.code, false)
									G.E_MANAGER:add_event(Event({
										trigger = "after",
										blockable = false,
										blocking = false,
										timer = "REAL",
										delay = 1,
										func = function(t)
											PKTR.temp_vals.code = ""
											return true
										end,
									}))
								end,
							}),
						},
					},
				},
			},
		},
	}

	return t
end

function PKTR.UI.DEF.quick_play_overlay()
	local t = {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.1, minh = 0.8 },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "Coming soon!",
									shadow = true,
									scale = 0.5,
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					},
				},
			},
		},
	}

	return t
end
