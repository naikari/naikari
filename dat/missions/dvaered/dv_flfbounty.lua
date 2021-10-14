--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Dvaered FLF Bounty">
 <avail>
  <priority>39</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>360</chance>
  <location>Computer</location>
  <faction>Dvaered</faction>
 </avail>
</mission>
--]]
--[[

   Dvaered FLF Bounty

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

   Dvaered-specific dead or alive bounty mission targeting FLF ships.

--]]

local fmt = require "fmt"
require "missions/neutral/pirbounty_dead"
require "pilot/generic"


-- Mission details
misn_title = {}
misn_title[1] = _("DV: Tiny Dead or Alive FLF Bounty in %s")
misn_title[2] = _("DV: Small Dead or Alive FLF Bounty in %s")
misn_title[3] = _("DV: Moderate Dead or Alive FLF Bounty in %s")
misn_title[4] = _("DV: High Dead or Alive FLF Bounty in %s")
misn_desc   = _("The FLF terrorist known as %s was recently seen in the %s system. %s authorities want this terrorist dead or alive.")

fail_kill_text = _("MISSION FAILURE! %s has been killed.")


function create ()
   paying_faction = planet.cur():faction()

   local systems = getsysatdistance(system.cur(), 1, 3,
      function(s)
         local p = s:presences()["FLF"]
         return p ~= nil and p > 0
      end)

   if #systems == 0 then
      -- No FLF pilots nearby
      misn.finish(false)
   end

   missys = systems[rnd.rnd(1, #systems)]
   if not misn.claim(missys) then misn.finish(false) end

   jumps_permitted = system.cur():jumpDist(missys) + rnd.rnd(5)
   if rnd.rnd() < 0.05 then
      jumps_permitted = jumps_permitted - 1
   end

   level = rnd.rnd(1, 4)

   name = pilot_name()
   ship = "Hyena"
   credits = 50000
   reputation = 0
   pirate_faction = faction.get("FLF")
   bounty_setup()

   -- Set mission details
   misn.setTitle(misn_title[level]:format(missys:name()))
   misn.setDesc(misn_desc:format(name, missys:name(), paying_faction:name()))
   misn.setReward(fmt.credits(credits))
   marker = misn.markerAdd(missys, "computer")
end


-- Set up the ship, credits, and reputation based on the level.
function bounty_setup ()
   if level == 1 then
      ship = "Hyena"
      credits = 100000 + rnd.sigma() * 30000
      reputation = 0
   elseif level == 2 then
      ship = "Lancelot"
      credits = 300000 + rnd.sigma() * 100000
      reputation = 1
   elseif level == 3 then
      if rnd.rnd() < 0.95 then
         ship = "Vendetta"
      else
         ship = "Ancestor"
      end
      credits = 800000 + rnd.sigma() * 160000
      reputation = 3
   elseif level == 4 then
      ship = "Pacifier"
      credits = 2000000 + rnd.sigma() * 400000
      reputation = 6
   end
end
