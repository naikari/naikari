--[[
-- Common Pirate Mission framework
--
-- This framework allows to keep consistency and abstracts around commonly used
--  Pirate mission functions.
--]]


--[[
   @brief Increases the reputation limit of the player.
--]]
function pir_modReputation( increment )
   local cur = var.peek("_fcap_pirate") or 30
   var.push( "_fcap_pirate", math.min(cur+increment, 100) )
end


function pir_addMiscLog( text )
   shiplog.create("pir_misc", p_("log", "Piracy"))
   shiplog.append("pir_misc", text)
end
