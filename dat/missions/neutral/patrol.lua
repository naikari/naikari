--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Patrol">
 <avail>
  <priority>48</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>560</chance>
  <location>Computer</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Proteron</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[

   Patrol

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

   Generalized replacement for Dvaered patrol mission. Can work with any
   faction.

--]]

local fmt = require "fmt"
local mh = require "misnhelper"
require "jumpdist"


abandon_text = {
   _("You are sent a message informing you that landing in the middle of a patrol mission is considered to be abandonment. As such, your contract is void and you will not receive payment."),
}

-- Mission details
misn_title = _("Patrol: {faction} territory ({system} system)")
misn_desc = _("Local {faction} police are enlisting qualified mercenaries to assist in patrolling the {system} system. For this mission, you will have to patrol specified points in the system, eliminating any hostiles you encounter. Upon entering, you must remain in the system until the patrol is completed, and you are not permitted to land during the patrol, or else the contract is void and you will not be paid.")

-- Messages
secure_msg = _("Point secure.")
hostiles_msg = _("Hostiles detected. Engage hostiles.")
continue_msg = _("Hostiles eliminated.")
pay_msg = _("{credits} awarded for keeping {faction} space safe.")

osd_title = _("Patrol")
osd_msg = {}
osd_msg[1] = _("Fly to the {system} system")
osd_msg[2] = "(null)"
osd_msg[3] = _("Eliminate hostiles")
osd_msg["__save"] = true

mark_name = _("Patrol Point")


use_hidden_jumps = false


-- Get the number of enemies in a particular system
function get_enemies(sys)
   local enemies = 0
   for i, f in ipairs(paying_faction:enemies()) do
      enemies = enemies + sys:presence(f)
   end
   return enemies
end


function create()
   paying_faction = planet.cur():faction()

   local systems = getsysatdistance(system.cur(), 0, 2,
      function(s)
         local this_faction = s:presence(paying_faction)
         local enemies = get_enemies(s)
         return enemies > 0 and enemies <= this_faction
      end, nil, use_hidden_jumps)

   if #systems <= 0 then
      misn.finish(false)
   end

   missys = systems[rnd.rnd(1, #systems)]

   local planets = missys:planets()
   local numpoints = math.min(rnd.rnd(2, 5), #planets)
   points = {}
   points.__save = true
   while numpoints > 0 and #planets > 0 do
      local p = rnd.rnd(1, #planets)
      points[#points + 1] = planets[p]
      numpoints = numpoints - 1

      local new_planets = {}
      for i, j in ipairs(planets) do
         if i ~= p then
            new_planets[#new_planets + 1] = j
         end
      end
      planets = new_planets
   end
   if #points < 2 then
      misn.finish(false)
   end

   hostiles = {}
   hostiles.__save = true
   hostiles_encountered = false

   local n_enemies = get_enemies(missys)
   if n_enemies == 0 then
      misn.finish(false)
   end
   credits = n_enemies * 2000
   credits = credits + rnd.sigma() * (credits / 3)
   reputation = math.floor(n_enemies / 75)

   -- Set mission details
   misn.setTitle(fmt.f(misn_title,
         {faction=paying_faction:name(), system=missys:name()}))
   misn.setDesc(fmt.f(misn_desc,
         {faction=paying_faction:name(), system=missys:name()}))
   misn.setReward(fmt.credits(credits))
   marker = misn.markerAdd(missys, "computer")
end


function accept()
   misn.accept()

   osd_msg[1] = fmt.f(osd_msg[1], {system=missys:name()})
   osd_msg[2] = string.format(n_(
         "Go to point indicated on overlay map (%d remaining)",
         "Go to point indicated on overlay map (%d remaining)", #points),
      #points)
   misn.osdCreate(osd_title, osd_msg)

   hook.enter("enter")
   hook.jumpout("jumpout")
   hook.land("land")
end


function enter()
   if system.cur() == missys then
      timer()
   end
end


function jumpout()
   mark = nil
   local last_sys = system.cur()
   if last_sys == missys then
      mh.showFailMsg(fmt.f(_("You have left the {system} system."),
            {system=last_sys:name()}))
      misn.finish(false)
   end
end


function land()
   mark = nil
   if system.cur() == missys then
      local txt = abandon_text[rnd.rnd(1, #abandon_text)]
      tk.msg("", txt)
      misn.finish(false)
   end
end


function pilot_leave(del_pilot)
   local new_hostiles = {}
   for i = 1, #hostiles do
      local p = hostiles[i]
      if p ~= del_pilot and p:exists() then
         new_hostiles[#new_hostiles + 1] = p
      end
   end

   hostiles = new_hostiles
end


function timer ()
   hook.rm(timer_hook)

   local player_pos = player.pos()
   local enemies = pilot.get(paying_faction:enemies())

   for i = 1, #enemies do
      local p = enemies[i]
      local mem = p:memory()
      if p:exists() and mem.natural then
         local already_in = false
         for j = 1, #hostiles do
            if p == hostiles[j] then
               already_in = true
            end
         end
         if not already_in then
            local fuzzy_vissible, visible = player.pilot():inrange(p)
            if visible and player_pos:dist(p:pos()) < 7500 then
               p:setVisplayer(true)
               p:setHilight(true)
               p:setHostile(true)
               mem.norun = true
               mem.natural = false
               hook.pilot(p, "death", "pilot_leave")
               hook.pilot(p, "jump", "pilot_leave")
               hook.pilot(p, "land", "pilot_leave")
               hostiles[#hostiles + 1] = p
            end
         end
      end
   end

   if #hostiles > 0 then
      if not hostiles_encountered then
         player.msg(hostiles_msg)
         hostiles_encountered = true
      end
      misn.osdActive(3)
   elseif #points > 0 then
      if hostiles_encountered then
         player.msg(continue_msg)
         hostiles_encountered = false
      end
      misn.osdActive(2)

      local point_pos = points[1]:pos()

      if mark == nil then
         mark = system.mrkAdd(mark_name, point_pos)
      end

      if player_pos:dist(point_pos) < 500 then
         table.remove(points, 1)

         player.msg(secure_msg)
         osd_msg[2] = string.format(n_(
               "Go to point indicated on overlay map (%d remaining)",
               "Go to point indicated on overlay map (%d remaining)",
               #points),
            #points)
         misn.osdCreate(osd_title, osd_msg)
         misn.osdActive(2)
         system.mrkRm(mark)
         mark = nil
      end
   else
      mh.showWinMsg(fmt.f(pay_msg,
            {credits=fmt.credits(credits), faction=paying_faction:name()}))

      player.pay(credits)
      paying_faction:modPlayer(reputation)
      misn.finish(true)
   end

   timer_hook = hook.timer(0.05, "timer")
end


function abort()
   system.mrkRm(mark)
end
