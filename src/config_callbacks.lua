G.FUNCS.change_joker_spaces = function(args)
    Poketro.config['joker_spaces'] = args.to_val

    SMODS.save_mod_config(Poketro)
end

G.FUNCS.change_buy_in_amount = function(args)
    Poketro.config['buy_in_amount'] = args.to_key

    SMODS.save_mod_config(Poketro)
end
