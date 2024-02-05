--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Derelict Event">
 <priority>100</priority>
 <trigger>enter</trigger>
 <chance>505</chance>
</event>
--]]
--[[
   Derelict Event

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

--

   Event which turns random natural pilots into a derelict.

--]]

local fmt = require "fmt"


function create()
   local density, volatility = system.cur():nebula()
   if volatility > 0 then
      -- Nebula volatility will destroy derelicts, which would be a bit
      -- weird, so skip the event if there's any nebula volatility.
      evt.finish()
   end

   hook.jumpout("exit")
   hook.land("exit")

   local all_pilots = pilot.get()

   local class_chances = {
      ["Freighter"] = 0.6,
      ["Armored Transport"] = 0.4,
      ["Corvette"] = 0.2,
      ["Destroyer"] = 0.1,
      ["Cruiser"] = 0.05,
      ["Carrier"] = 0.01,
   }
   local faction_chances = {
      ["Collective"] = 0.01,
      ["Dvaered"] = 0.4,
      ["Empire"] = 0.2,
      ["Proteron"] = 0.1,
      ["Sirius"] = 0.3,
      ["Soromid"] = 0.3,
      ["Thurion"] = 0.5,
      ["Za'lek"] = 0.01,
   }

   local pilots = {}
   for i = 1, #all_pilots do
      local p = all_pilots[i]
      local shipclass = p:ship():class()
      local chance = class_chances[shipclass]
      if chance == nil or rnd.rnd() < chance then
         local fac = p:faction()
         local chance = faction_chances[fac]
         if chance == nil or rnd.rnd() < chance then
            pilots[#pilots + 1] = p
         end
      end
   end

   if #pilots <= 0 then
      evt.finish()
   end

   local p = pilots[rnd.rnd(1, #pilots)]
   if p:exists() and p:memory().natural then
      -- Make sure the pilot isn't too close to a planet or jump.
      local cursys = system.cur()
      local pos = p:pos()
      local planets = cursys:planets()
      for i = 1, #planets do
         local pnt = planets[i]
         if vec2.dist(pos, pnt:pos()) < pnt:radius() * 3 then
            evt.finish()
         end
      end
      local jumps = cursys:jumps()
      for i = 1, #jumps do
         local jmp = jumps[i]
         if vec2.dist(pos, jmp:pos()) < jmp:radius() * 3 then
            evt.finish()
         end
      end

      local mem = p:memory()
      mem.natural = false
      mem.kill_reward = nil
      p:disable()
      p:setHilight()
      p:setLeader(nil)
      p:rename(fmt.f(_("Derelict {pilot}"), {pilot=p:name()}))

      -- Set to a blank faction so there's no reputation shenanigans.
      local f = faction.dynAdd(nil, N_("Derelict"), nil, {ai="idle"})
      p:setFaction(f)

      hook.pilot(p, "board", "pilot_board")

      if rnd.rnd() < 0.99 then
         -- Credits reward is usually very heavily reduced.
         local lost_credits = rnd.uniform(0.9, 1) * p:credits()
         p:pay(-lost_credits)
      elseif rnd.rnd() < 0.01 then
         -- Very rarely, credits reward is inflated. Includes both a
         -- proportional boost portion and a flat boost portion.
         local extra_credits = rnd.uniform(2, 10) * p:credits()
         extra_credits = extra_credits + 600000 + 100000*rnd.threesigma()
         p:pay(extra_credits)
      end

      -- Remove followers so they don't sit there next to the wing of
      -- the empty ship.
      for i, fp in ipairs(p:followers()) do
         fp:setLeader(nil)
      end
   end
end


function pilot_board(p, boarder)
   if boarder ~= player.pilot() then
      return
   end

   -- For the first derelict the player ever boards, ensure that the
   -- credits reward is good. This is to teach the player that boarding
   -- derelicts has a chance of being very rewarding.
   if not var.peek("derelict_boarded") then
      var.push("derelict_boarded", true)
      if p:credits() < 100000 then
         p:pay(100000)
      end
   end

   p:setHilight(false)
   evt.finish()
end


function exit()
   evt.finish()
end
