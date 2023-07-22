--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Derelict Event">
 <priority>100</priority>
 <trigger>enter</trigger>
 <chance>520</chance>
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
   hook.safe("safe_disable")
end


function safe_disable()
   local pilots = pilot.get()
   local p = pilots[rnd.rnd(1, #pilots)]
   if p:exists() and p:memory().natural then
      p:memory().natural = false
      p:disable()
      p:setLeader(nil)
      p:rename(fmt.f(_("Derelict {pilot}"), {pilot=p:name()}))

      -- Reduce credits (the credits amount is based on the effort it
      -- takes to disable them, and the player doesn't have to go thru
      -- that effort in the case of this event).
      if rnd.rnd() < 0.95 then
         local credits = rnd.uniform(0.5, 0.8) * p:credits()
         p:pay(-credits)
      end

      -- Remove followers so they don't sit there next to the wing of
      -- the empty ship.
      for i, fp in ipairs(p:followers()) do
         fp:setLeader(nil)
      end
   end

   evt.finish()
end
