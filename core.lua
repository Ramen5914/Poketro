PKTR = {
  id = SMODS.current_mod["id"],
  name = SMODS.current_mod["name"],
  display_name = SMODS.current_mod["display_name"],
  author = SMODS.current_mod["author"],
  description = SMODS.current_mod["description"],
  prefix = SMODS.current_mod["prefix"],
  priority = SMODS.current_mod["priority"],
  badge_colour = SMODS.current_mod["badge_colour"],
  badge_text_colour = SMODS.current_mod["badge_text_colour"],
  version = SMODS.current_mod["version"],
  dependencies = SMODS.current_mod["dependencies"],
  conflicts = SMODS.current_mod["conflicts"],
}

PKTR.network_state = {
  connected = false,
  code = nil,
  username = "Guest",
  lobby = nil,
}

PKTR.lobby_state = {
  players = {},
  config = {
    different_seeds = false,
    starting_money = 50,
    joker_spaces = 5,
    buy_in_amount = 2,
    rebuy_limit = 1,
    share_jokers = false,
    share_hand_levels = true,
    gamemode = "poketro",
    custom_seed = "random",
  }
}

PKTR.game_state = {}

function PKTR.reset_game_state()
  PKTR.game_state = {
    initialized = false,
    seed = nil,
    current_hand = nil,
    round = 1,
    players_ready = 0,
    players = {},
  }
end

PKTR.reset_game_state()

G.E_MANAGER:add_event(Event({
  trigger = "immediate",
  blockable = false,
  blocking = false,
  func = function()
    if SMODS.booted then
      PKTR.reset_game_state()
      return true
    end
    return false
  end
}))

PKTR.temp_vals = {
  code = ""
}

PKTR.cards = {}

PKTR.blinds = {}

PKTR.networking = {}

PKTR.networking.NETWORKING_THREAD = nil
PKTR.networking.network_to_ui_channel = love.thread.getChannel("networkToUi")
PKTR.networking.ui_to_network_channel = love.thread.getChannel("uiToNetwork")

function load_pktr_file(file)
  local chunk, err = SMODS.load_file(file, "Poketro")
  if chunk then
    local ok, func = pcall(chunk)
    if ok then
      return func
    else
      sendWarnMessage("Failed to process file: " .. func, "POKETRO")
    end
  else
    sendWarnMessage("Failed to find or compile file: " .. tostring(err), "POKETRO")
  end

  return nil
end

SMODS.Atlas({
  key = "modicon",
  path = "modicon.png",
  px = 29,
  py = 29
})

load_pktr_file("src/ui/smods.lua")
load_pktr_file("src/utils.lua")
load_pktr_file("src/mod_hash.lua")
load_pktr_file("src/networking/actions_in.lua")
load_pktr_file("src/networking/actions_out.lua")
load_pktr_file("src/misc.lua")
load_pktr_file("src/game.lua")
load_pktr_file("src/ui/utils.lua")
load_pktr_file("src/ui/lobby_buttons.lua")
load_pktr_file("src/ui/blind_select.lua")
load_pktr_file("src/ui/game_hud.lua")
load_pktr_file("src/ui/end_game_overlay.lua")
load_pktr_file("src/ui/cards.lua")
load_pktr_file("src/editions.lua")
load_pktr_file("src/stickers.lua")
load_pktr_file("src/tags.lua")
load_pktr_file("src/consumables/asteroid.lua")
load_pktr_file("src/jokers/player.lua")
load_pktr_file("src/jokers/defensive_joker.lua")
load_pktr_file("src/jokers/hanging_bad.lua")
load_pktr_file("src/jokers/lets_go_gambling.lua")
load_pktr_file("src/jokers/skip_off.lua")
load_pktr_file("src/jokers/speedrun.lua")
load_pktr_file("src/ui/galdur_lobby_page.lua")
load_pktr_file("src/blinds/horde.lua")
load_pktr_file("src/blinds/nemesis.lua")
load_pktr_file("src/blinds/truce.lua")

G.E_MANAGER:add_event(Event({
  trigger = "immediate",
  blockable = false,
  blocking = false,
  no_delete = true,
  func = function()
    repeat
      local msg = PKTR.networking.network_to_ui_channel:pop()

      if msg then
        PKTR.networking.handle_network_message(msg)
      end
    until not msg

    return false
  end
}))

PKTR.networking.initialize()
