--[[
   @brief Increases the reputation limit of the player.
--]]
function dv_modReputation( increment )
   local cur = var.peek("_fcap_dvaered") or 30
   var.push("_fcap_dvaered", math.min(cur+increment, 100) )
end


function dv_addAntiFLFLog( text )
   shiplog.create("dv_antiflf", p_("log", "Dvaered Anti-FLF Campaign"))
   shiplog.append("dv_antiflf", text)
end
