Poketro = SMODS.current_mod

require 'config_callbacks'

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

