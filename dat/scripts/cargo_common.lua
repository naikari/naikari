local fmt = require "fmt"
require "jumpdist"
require "nextjump"

-- Don't use hidden jumps by default; set this to true to use hidden jumps.
cargo_use_hidden = false

-- By default, only generate if commodities available. Set to true to always generate.
cargo_always_available = false

-- Find an inhabited planet 0-3 jumps away.
function cargo_selectMissionDistance ()
   local seed = rnd.rnd()

   -- 70% chance of 0-3 jump distance
   if seed < 0.7 then
      missdist = rnd.rnd(0, 3)
   else
      missdist = rnd.rnd(4, 6)
   end

   return missdist
end

-- Build a set of target planets
function cargo_selectPlanets(missdist, routepos)
   local planets = {}
   getsysatdistance(system.cur(), missdist, missdist,
      function(s, dist)
         for i, v in ipairs(s:planets()) do
            if v:services()["inhabited"] and v ~= planet.cur()
                  and not (s == system.cur()
                     and (vec2.dist(v:pos(), routepos) < 2500))
                  and v:canLand() and cargoValidDest(v) then
               table.insert(planets, {v, s, dist})
            end
         end
         return true
      end,
      nil, cargo_use_hidden)

   return planets   
end

-- We have a destination, now we need to calculate how far away it is by simulating the journey there.
-- Assume shortest route with no interruptions.
-- This is used to calculate the reward.
function cargo_calculateDistance(routesys, routepos, destsys, destplanet)
   local traveldist = 0

   jumps = routesys:jumpPath( destsys, cargo_use_hidden )
   if jumps then
      for k, v in ipairs(jumps) do
         -- We're not in the destination system yet.
         -- So, get the next system on the route, and the distance between
         -- our entry point and the jump point to the next system.
         -- Then, set the exit jump point as the next entry point.
         local j, r = jump.get( v:system(), v:dest() )
         traveldist = traveldist + vec2.dist(routepos, j:pos())
         routepos = r:pos()
      end
   end

   -- We ARE in the destination system now, so route from the entry point to the destination planet.
   traveldist = traveldist + vec2.dist(routepos, destplanet:pos())

   return traveldist
end

function cargo_calculateRoute ()
   origin_p, origin_s = planet.cur()
   local routesys = origin_s
   local routepos = origin_p:pos()
   
   -- Select mission tier.
   local tier = rnd.rnd(0, 4)
   
   -- Farther distances have a lower chance of appearing.
   local missdist = cargo_selectMissionDistance()
   local planets = cargo_selectPlanets(missdist, routepos)
   if #planets == 0 then
      return
   end

   local index = rnd.rnd(1, #planets)
   local destplanet = planets[index][1]
   local destsys = planets[index][2]
   local numjumps = planets[index][3]
   
   -- We have a destination, now we need to calculate how far away it is by simulating the journey there.
   -- Assume shortest route with no interruptions.
   -- This is used to calculate the reward.

   local traveldist = cargo_calculateDistance(routesys, routepos, destsys, destplanet)
   
   
   -- Determine amount of piracy along the route
   local exp = 1.5
   local jumps = system.jumpPath(system.cur(), destsys, cargo_use_hidden)
   local risk = system.cur():presence("Pirate") ^ exp
   if jumps then
      for k, v in ipairs(jumps) do
         local travelrisk = v:system():presence("Pirate")
         risk = risk + travelrisk^exp
      end
   end
   local avgrisk = (risk / (numjumps+1)) ^ (1/exp)
   
   -- We now know where. But we don't know what yet. Randomly choose a commodity type.
   local cargo
   local cargoes = difference(
         planet.cur():commoditiesSold(), destplanet:commoditiesSold())
   if #cargoes == 0 then
      if cargo_always_available then
         cargo = nil
      else
         return
      end
   else
      cargo = cargoes[rnd.rnd(1,#cargoes)]:nameRaw()
   end
   

   -- Return lots of stuff
   return destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier
end


-- Calculates the minimum possible time taken for the player to reach a destination.
function cargoGetTransit( timelimit, numjumps, traveldist )
   local pstats   = player.pilot():stats()
   local stuperpx = 1/pstats.speed_max * 650
   local arrivalt = time.get() + time.create(0, 0, traveldist * stuperpx +
         numjumps * pstats.jump_delay + 101800 + 2400 * numjumps)
   return arrivalt
end

function cargoValidDest( targetplanet )
   -- factions which cannot be delivered to by factions other than themselves
   local hidden = {
      faction.get("FLF"),
      faction.get("Pirate"),
      faction.get("Proteron"),
      faction.get("Thurion"),
   }
   for i, f in ipairs(hidden) do
      if targetplanet:faction() == f and planet.cur():faction() ~= f then
         return false
      end
   end

   -- Factions which cannot deliver to factions other than themselves
   local insular = {
      faction.get("Proteron"),
      faction.get("Thurion"),
   }
   for i, f in ipairs(insular) do
      if planet.cur():faction() == f and targetplanet:faction() ~= f then
         return false
      end
   end

   return true
end

--Determines the items in table a that are not in table b.
--Used to determine what cargo is sold at current planet but not at destination planet.
function difference(a, b)
   local ai = {}
   local r = {}
   for k,v in pairs(a) do
      r[k] = v
      ai[v] = true
   end
   for k,v in pairs(b) do 
      if ai[v] ~= nil then
         r[k] = nil
      end
   end
   return r
end

--[[--
Returns a block of mission-description text for the given cargo.

   @tparam string misn_desc Translated title-level description, e.g.
      _("Cargo transport to %s in the %s system."):format(...).
   @tparam string|nil cargo Cargo type as a raw (untranslated) name.
   @tparam number|nil amount Cargo amount in tonnes. May be nil.
   @tparam Planet target Target planet for the delivery.
   @tparam[opt] number numjumps Number of jumps to the target planet.
   @tparam[opt] Time deadline Target delivery time.
   @tparam[opt] string notes Any additional text the user should see on
      its own detail line, such as piracy risk.
--]]
function cargo_setDesc(misn_desc, cargo, amount, target, numjumps, deadline,
      notes)
   local t = {misn_desc, ""};
   if amount ~= nil then
      table.insert(t, fmt.f(_("Cargo: {cargoname} ({amount})"),
            {cargoname=_(cargo), amount=fmt.tonnes(amount)}))
   elseif cargo ~= nil then
      table.insert(t, fmt.f(_("Cargo: {cargoname}"), {cargoname=_(cargo)}))
   end

   if numjumps ~= nil then
      table.insert(t, fmt.f(n_("Jumps: {jumps}", "Jumps: {jumps}", numjumps),
            {jumps=fmt.number(numjumps)}))
   end

   local dist = cargo_calculateDistance(system.cur(), planet.cur():pos(),
         target:system(), target)
   table.insert(t, fmt.f(_("Travel distance: {distance} AU"),
            {distance=fmt.number(dist / 1000)}))

   if notes ~= nil then
      table.insert(t, notes);
   end

   if deadline ~= nil then
      table.insert(t, fmt.f(_("Time limit: {time}"),
            {time=tostring(deadline - time.get())}))
   end

   misn.setDesc(table.concat(t, "\n"));
end
