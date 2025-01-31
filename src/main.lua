Poketro = SMODS.current_mod

G.FUNCS.change_joker_spaces = function(args)
    Poketro.config['joker_spaces'] = args.to_val

    SMODS.save_mod_config(Poketro)
end

G.FUNCS.change_buy_in_amount = function(args)
    Poketro.config['buy_in_amount'] = args.to_key

    SMODS.save_mod_config(Poketro)
end

G.FUNCS.change_rebuy_limit = function(args)
    Poketro.config['rebuy_limit'] = args.to_val

    SMODS.save_mod_config(Poketro)
end

G.FUNCS.toggle_share_jokers = function()
    Poketro.config['share_jokers'] = not Poketro.config['share_jokers']

    SMODS.save_mod_config(Poketro)
end

G.FUNCS.toggle_share_hand_levels = function()
    Poketro.config['share_hand_levels'] = not Poketro.config['share_hand_levels']

    SMODS.save_mod_config(Poketro)
end

SMODS.Atlas {
    key = "CardBacks",
    path = "CardBacks.png",
    px = 71,
    py = 95
}

SMODS.current_mod.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { r = 0.1, minw = 8, minh = 6, align = "tm", padding = 0.2, colour = G.C.BLACK },
        nodes = {
            {
                n = G.UIT.C,
                config = { minw = 4, minh = 4, colour = G.C.CLEAR, align = "tm", padding = 0.15 },
                nodes = {
                    create_option_cycle({
                        label = localize('b_pktr_joker_spaces'),
                        scale = 0.8,
                        options = { 0, 1, 2, 3, 4, 5 },
                        opt_callback = 'change_joker_spaces',
                        current_option = (Poketro.config['joker_spaces'] + 1)
                    }),
                    {
                        n = G.UIT.R,
                        config = { minw = 2, minh = 1, align = "tm", padding = 0.15 },
                        nodes = {
                            {
                                n = G.UIT.C,
                                config = {},
                                nodes = {
                                    create_option_cycle({
                                        label = localize('b_pktr_buy_in'),
                                        scale = 0.8,
                                        options = localize('ml_pktr_buy_in_opt'),
                                        opt_callback = 'change_buy_in_amount',
                                        current_option = Poketro.config['buy_in_amount']
                                    })
                                }
                            },
                            {
                                n = G.UIT.C,
                                config = {},
                                nodes = {
                                    create_option_cycle({
                                        label = localize('b_pktr_rebuy_limit'),
                                        scale = 0.8,
                                        options = { 0, 1, 2, 3 },
                                        opt_callback = 'change_rebuy_limit',
                                        current_option = (Poketro.config['rebuy_limit'] + 1)
                                    })
                                }
                            }
                        }
                    },
                    create_toggle({
                        label = localize('b_pktr_share_jokers'),
                        toggle_callback = G.FUNCS.toggle_share_jokers,
                        ref_table = Poketro.config,
                        ref_value = 'share_jokers',
                        config = { align = "tm" }
                    }),
                    create_toggle({
                        label = localize('b_pktr_share_hand_levels'),
                        toggle_callback = G.FUNCS.toggle_share_hand_levels,
                        ref_table = Poketro.config,
                        ref_value = 'share_hand_levels'
                    })
                }
            }
        }
    }
end

SMODS.Back {
    key = 'poker',
    atlas = 'CardBacks',
    pos = {
        x = 0,
        y = 0
    },
    unlocked = true,
    discovered = true,
    omit = true
}

function G.UIDEF.poketro()
    return (
        create_UIBox_generic_options({
            contents = {
                UIBox_button({
                    label = { G.localization.misc.dictionary["singleplayer"] or "Singleplayer" },
                    colour = G.C.BLUE,
                    button = "setup_run",
                    minw = 5,
                }),
                true and UIBox_button({
                    label = { G.localization.misc.dictionary["create_lobby"] or "Create Lobby" },
                    colour = G.C.GREEN,
                    button = "create_lobby",
                    minw = 5,
                }) or nil,
                true and UIBox_button({
                    label = { G.localization.misc.dictionary["join_lobby"] or "Join Lobby" },
                    colour = G.C.RED,
                    button = "join_lobby",
                    minw = 5,
                }) or nil,
                not true and UIBox_button({
                    label = { G.localization.misc.dictionary["reconnect"] or "Reconnect" },
                    colour = G.C.RED,
                    button = "reconnect",
                    minw = 5,
                }) or nil,
            },
        })
    )
end