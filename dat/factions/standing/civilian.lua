require "factions/standing/skel"


_fdelta_distress = {-1, 0} -- Maximum change constraints
_fdelta_kill = {-10, 0} -- Maximum change constraints


-- List of possible proxy factions for a given civilian.
local proxy_factions = {
   "Coälition",
   "Empire",
   "Frontier",
}


function faction_hit(current, amount, source, secondary, fac)
   if secondary then
      -- Ignore secondary hits.
      return current
   end

   -- Loop thru all proxy factions and perform a manual secondary
   -- faction hit on each proxy faction which is present in the current
   -- system.
   local presences = system.cur():presences()
   for i = 1, #proxy_factions do
      local f = proxy_factions[i]
      if presences[f] then
         local proxy_faction = faction.get(f)
         local new = default_hit(proxy_faction:playerStanding(), amount,
               source, true, proxy_faction)
         proxy_faction:setPlayerStanding(new)
      end
   end

   -- Don't change the actual civilian faction's standing.
   return current
end
