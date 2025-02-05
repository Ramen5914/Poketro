local load_profile_ref = G.FUNCS.load_profile
function PKTR.load_profile(delete_prof_data)
	load_profile_ref(delete_prof_data)
	PKTR.send.set_username()
end
G.FUNCS.load_profile = PKTR.load_profile

local save_settings_ref = Game.save_settings
function PKTR.save_settings(passed_self)
	save_settings_ref(passed_self)
	PKTR.send.set_username()
end
Game.save_settings = PKTR.save_settings

local can_continue_ref = G.FUNCS.can_continue
function PKTR.can_continue(e)
	if PKTR.is_in_lobby() then
		return nil
	end
	return can_continue_ref(e)
end
G.FUNCS.can_continue = PKTR.can_continue

local key_hold_update_ref = Controller.key_hold_update
function Controller:key_hold_update(key, dt)
	if not PKTR.is_in_lobby() then
		key_hold_update_ref(self, key, dt)
	end
end
