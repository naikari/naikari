--[[
Script to update outfits and ships from a saved game in the case they
don't exist.
--]]

--[[
The format is ["oldname"] = newvalue where newvalue can either take a
string for the new name of the outfit (if there is a direct equivalent)
or a number value indicating the amount of credits to refund the player.
Note that opting for a refund may leave the player stranded (requiring
them to be rescued by rescue.lua), so replacement is generally preferred
where applicable.
--]]
local outfit_list = {
   ["Improved Refrigeration Cycle"] = 35000,
}
--[[--
Takes an outfit name and should return either a valid new outfit name or
the amount of credits to give back to the player.
--]]
function outfit(name)
   return outfit_list[name]
end


--[[
The format is ["oldname"] = "newname". "newname" must be a valid ship
which can be substituted for the outdated ship (in general, this should
be the new name of the same ship that was renamed).
--]]
local ship_list = {
   ["Koala"] = "Koäla",
}
--[[--
Takes a ship name and must return a valid ship name to give to the
player.
--]]
function ship(name)
   if ship_list[name] ~= nil then
      return ship_list[name]
   end
   return "Llama"
end
