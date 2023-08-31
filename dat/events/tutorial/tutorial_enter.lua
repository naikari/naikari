--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Enter Tutorial Event">
 <trigger>enter</trigger>
 <chance>100</chance>
 <priority>0</priority>
 <flags>
  <unique />
 </flags>
</event>
--]]
--[[
   Enter Tutorial Event

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
--]]

local fmt = require "fmt"
require "events/tutorial/tutorial_common"


nofuel_text = _([[Soon after you realize to your horror that you are out of fuel in a system with no planets to land on that you can find, you are hailed by another pilot and decide to answer her hail. "Hi, any chance that I could get a fuel transfer from you?" she asks. You explain, defeated, that you are out of fuel yourself. "Dang," she responds. "Oh well. I guess you should ask around for fuel, too. Do you know how to do it? It's pretty easy.

"Hail any other pilot either by #bdouble-clicking#0 on them, or by targeting them with {target_next_key} and pressing {hail_key}. You can request a refuel from there.

"Anyway, I'm going to continue my search. Good luck on yours!"]])


function create()
   hook.jumpout("exit")
   hook.land("exit")

   local presences = system.cur():presences()
   if not var.peek("tutorial_nofuel") and player.jumps() == 0 then
      local sys = system.cur()
      local landable_planets = false
      for i, pl in ipairs(sys:planets()) do
         local landable, bribable = pl:canLand()
         if landable or bribable then
            landable_planets = true
            break
         end
      end

      if not landable_planets then
         local shiptype, fac, pilotname
         if presences["Civilian"] then
            shiptype = "Gawain"
            fac = "Civilian"
            pilotname = _("Civilian Gawain")
         elseif presences["Independent"] then
            shiptype = "Hyena"
            fac = "Independent"
            pilotname = _("Independent Hyena")
         elseif presences["Trader"] then
            shiptype = "Quicksilver"
            fac = "Trader"
            pilotname = _("Trader Quicksilver")
         elseif presences["Miner"] then
            shiptype = "Koäla"
            fac = "Miner"
            pilotname = _("Miner Koäla")
         else
            -- No compatible presences, so we skip the event.
            evt.finish()
         end

         local offset = vec2.new(rnd.uniform(-1000, 1000),
               rnd.uniform(-1000, 1000))
         local pos = player.pilot():pos() + offset
         local p = pilot.add(shiptype, fac, pos, pilotname)
         p:setFuel(100)
         p:setVisplayer()
         p:setNoClear()
         timer_hook = hook.timer(3, "timer_nofuel", p)

         return
      end
   end

   evt.finish()
end


function timer_nofuel(p)
   hook.rm(timer_hook)
   if not p:exists() then
      evt.finish()
   end
   p:hailPlayer()
   hook.pilot(p, "hail", "pilot_hail_nofuel")
end


function pilot_hail_nofuel(p)
   tk.msg("", fmt.f(nofuel_text,
            {target_next_key=tutGetKey("target_next"),
               hail_key=tutGetKey("hail")}))
   var.push("tutorial_nofuel", true)
   p:setVisplayer(false)
   evt.finish()
end


function exit()
   -- In the unlikely event that a player leaves the system too quickly
   -- to see a message before jumping out, this prevents it from showing
   -- the message to prevent weirdness of looking like it's referring to
   -- a system that it isn't.
   evt.finish()
end

