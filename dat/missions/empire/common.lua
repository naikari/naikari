--[[
-- Common Empire Mission framework
--
-- This framework allows to keep consistency and abstracts around commonly used
--  empire mission functions.
--]]


--[[
   @brief Increases the reputation limit of the player.
--]]
function emp_modReputation( increment )
   local cur = var.peek("_fcap_empire") or 30
   var.push( "_fcap_empire", math.min(cur+increment, 100) )
end


function emp_addShippingLog( text )
   shiplog.create("empire_shipping", p_("log", "Empire Shipping"))
   shiplog.append("empire_shipping", text)
end


function emp_addCollectiveLog( text )
   shiplog.create("empire_collective", p_("log", "Empire Collective Campaign"))
   shiplog.append("empire_collective", text)
end
