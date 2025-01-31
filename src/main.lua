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
        config = {
            align = "cm",
            padding = 0.05,
            colour = G.C.CLEAR
        },
        nodes = {
            create_option_cycle({
                label = localize('b_pktr_joker_spaces'),
                scale = 0.8,
                options = { 0, 1, 2, 3, 4, 5 },
                opt_callback = 'change_joker_spaces',
                current_option = (Poketro.config['joker_spaces'] + 1)
            }),
            create_option_cycle({
                label = localize('b_pktr_buy_in'),
                scale = 0.8,
                options = localize('ml_pktr_buy_in_opt'),
                opt_callback = 'change_buy_in_amount',
                current_option = Poketro.config['buy_in_amount']
            }),
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
