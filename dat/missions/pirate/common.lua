--[[
-- Common Pirate Mission framework
--
-- This framework allows to keep consistency and abstracts around commonly used
--  Pirate mission functions.
--]]


function pir_addMiscLog( text )
   shiplog.create("pir_misc", p_("log", "Piracy"))
   shiplog.append("pir_misc", text)
end
