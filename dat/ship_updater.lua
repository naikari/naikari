--[[
   Script to update outfits and ships from a saved game in the case they don't exist.
--]]

--[[
   The format is ["oldname"] = newvalue where newvalue can either take a string
   for the new name of the outfit (if there is a direct equivalent) or a number
   value indicating the amount of credits to refund the player.
--]]
local outfit_list = {
   ["Improved Refrigeration Cycle"] = 35000,
}
--[[--
   Takes an outfit name and should return either a new outfit name or the amount of credits to give back to the player.
--]]
function outfit(name)
   return outfit_list[name]
end

local license_list = {
}
--[[--
   Takes a license name and should return either a new license name or the amount of credits to give back to the player.
--]]
function license(name)
   return license_list[name]
end
