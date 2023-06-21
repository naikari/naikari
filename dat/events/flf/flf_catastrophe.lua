--[[
<?xml version='1.0' encoding='utf8'?>
<event name="FLF Catastrophe">
 <trigger>enter</trigger>
 <chance>70</chance>
 <cond>
   system.cur() == system.get("Sigur")
   and faction.get("FLF"):playerStanding() &gt;= 100
   and diff.isApplied("flf_vs_empire")
   and player.misnDone("FLF Pirate Alliance")
   and false
 </cond>
 <notes>
  <campaign>Save the Frontier</campaign>
 </notes>
</event>
--]]
--[[

   The FLF Catastrophe

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
local fleet = require "fleet"
local mh = require "misnhelper"
require "missions/flf/flf_common"


function create ()
   if not evt.claim(system.cur()) then
      evt.finish(false)
   end

   emp_srcsys = system.get("Arcanis")
   emp_shipnums = {1, 1, 1, 3, 7, 3}
   emp_shptypes = {
      "Empire Peacemaker", "Empire Hawking", "Empire Pacifier",
      "Empire Admonisher", "Empire Lancelot", "Empire Shark",
   }
   emp_minsize = 6
   found_thurion = false
   player_attacks = 0

   bar_hook = hook.land("enter_bar", "bar")
   abort_hook = hook.enter("takeoff_abort")
end


function enter_bar ()
   local flf_missions = {
      "FLF Commodity Run", "Eliminate a Dvaered Patrol",
      "Divert the Dvaered Forces", "Eliminate an Empire Patrol",
      "FLF Pirate Disturbance", "Rogue FLF" }
   if not mh.anyMissionActive(flf_missions) then
      hook.rm(bar_hook)
      hook.rm(abort_hook)
      music.stop()
      music.load("tension")
      music.play()
      var.push("music_off", true)
      var.pop("music_off")

      takeoff_hook = hook.enter("takeoff")
      player.takeoff()
   end
end


function takeoff_abort ()
   evt.finish(false)
end


function takeoff ()
   hook.rm(takeoff_hook)

   pilot.toggleSpawn(false)
   pilot.clear()

   local ss, s

   ss, s = planet.get("Sindbad")

   flf_base = pilot.add("Sindbad", "FLF", ss:pos(), nil, {ai="flf_norun"})
   flf_base:setVisible()
   flf_base:setHilight()
   hook.pilot(flf_base, "attacked", "pilot_attacked_sindbad")
   hook.pilot(flf_base, "death", "pilot_death_sindbad")

   -- Spawn FLF ships
   flf_ships = fleet.add({5, 10, 10, 4},
         {"Pacifier", "Vendetta", "Lancelot", "Hyena"}, "FLF", ss:pos(),
         {_("FLF Pacifier"), _("FLF Vendetta"), _("FLF Lancelot"),
            _("FLF Hyena")}, {ai="flf_norun"})
   for i, j in ipairs(flf_ships) do
      j:setVisible()
      j:memory("aggressive", true)
   end

   -- Spawn Empire ships
   emp_ships = fleet.add(emp_shpnums, emp_shptypes, "Empire", emp_srcsys, nil,
         {ai="empire_norun"})
   for i, j in ipairs(emp_ships) do
      j:setHostile()
      j:setVisible()
      hook.pilot(j, "death", "pilot_death_emp")
      if rnd.rnd() < 0.5 then
         j:control()
         j:attack(flf_base)
      end
   end

   -- Spawn Dvaered ships
   dv_ships = fleet.add({1, 2, 2, 3, 4},
         {"Dvaered Goddard", "Dvaered Vigilance", "Dvaered Phalanx",
            "Dvaered Ancestor", "Dvaered Vendetta"},
         "Dvaered", emp_srcsys, nil, {ai="dvaered_norun"})
   for i, j in ipairs(dv_ships) do
      j:setHostile()
      j:setVisible()
   end

   diff.apply("flf_dead")
   player.pilot():setNoJump(true)
end


function pilot_death_emp(pilot, attacker, arg)
   local emp_alive = {}
   for i, j in ipairs(emp_ships) do
      if j:exists() then
         emp_alive[ #emp_alive + 1 ] = j
      end
   end

   if #emp_alive < emp_minsize or rnd.rnd() < 0.1 then
      emp_ships = emp_alive
      local nf = fleet.add(emp_shpnums, emp_shptypes, "Empire", emp_srcsys,
            nil, {ai="empire_norun"})
      for i, j in ipairs(nf) do
         j:setHostile()
         j:setVisible()
         hook.pilot(j, "death", "pilot_death_emp")
         if rnd.rnd() < 0.5 then
            j:control()
            if flf_base:exists() then
               j:attack(flf_base)
            end
         end
         emp_ships[ #emp_ships + 1 ] = j
      end
   end
end


function pilot_attacked_sindbad(pilot, attacker, arg)
   if (attacker == player.pilot() or attacker:leader() == player.pilot())
         and faction.get("FLF"):playerStanding() > -100 then
      -- Punish the player with a faction hit every time they attack
      faction.get("FLF"):modPlayerSingle(-10)
   end
end


function pilot_death_sindbad(pilot, attacker, arg)
   player.pilot():setNoJump(false)
   pilot.toggleSpawn(true)

   if diff.isApplied("flf_pirate_ally") then
      diff.remove("flf_pirate_ally")
   end

   for i, j in ipairs(emp_ships) do
      if j:exists() then
         j:control(false)
         j:changeAI("empire")
         j:setVisible(false)
      end
   end
   for i, j in ipairs(dv_ships) do
      if j:exists() then
         j:changeAI("dvaered")
         j:setVisible(false)
      end
   end

   if attacker == player.pilot() or attacker:leader() == player.pilot()
         or faction.get("FLF"):playerStanding() < 0 then
      -- Player decided to help destroy Sindbad for some reason. Set FLF
      -- reputation to "enemy", add a log entry, and finish the event
      -- without giving the usual rewards.
      faction.get("FLF"):setPlayerStanding(-100)
      flf_addLog(log_text_betrayal)
      evt.finish(true)
   end

   music.stop()
   music.load("machina")
   music.play()
   var.push("music_wait", true)

   player.pilot():setInvincible()
   player.cinematics()
   camera.set(flf_base)

   flf_setReputation(100)
   faction.get("FLF"):setPlayerStanding(100)
   flf_addLog(log_text_flf)
   player.outfitAdd("Map: Inner Nebula Secret Jump")
   hook.jumpin("jumpin")
   hook.land("land")
   hook.timer(8, "timer_plcontrol")
end


function timer_plcontrol ()
   camera.set(player.pilot())
   player.cinematics(false)
   hook.timer(2, "timer_end")
end


function timer_end ()
   player.pilot():setInvincible(false)
end


function jumpin ()
   if not found_thurion and system.cur() == system.get("Oriantis") then
      music.stop()
      music.load("intro")
      music.play()
      var.push("music_wait", true)
      hook.timer(5, "timer_thurion")
   elseif found_thurion and system.cur() == system.get("Metsys") then
      diff.apply("Thurion_found")
   end
end


function timer_thurion ()
   found_thurion = true
   player.refuel()
end


function land ()
   if planet.cur():faction() == faction.get("Thurion") then
      faction.get("Thurion"):setKnown(true)
      flf_addLog(log_text_thurion)
   elseif diff.isApplied("Thurion_found") then
      diff.remove("Thurion_found")
   end
   var.pop("music_wait")
   evt.finish(true)
end
