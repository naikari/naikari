--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Moving Up">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>25</priority>
  <done>Waste Collector</done>
  <chance>30</chance>
  <location>Bar</location>
  <faction>Soromid</faction>
  <cond>var.peek("comingout_time") == nil or time.get() &gt;= time.fromnumber(var.peek("comingout_time")) + time.create(0, 20, 0)</cond>
 </avail>
 <notes>
  <campaign>Coming Out</campaign>
 </notes>
</mission>
--]]
--[[

   Moving Up

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

require "numstring"
require "jumpdist"
require "pilot/pirate"
require "missions/soromid/common"


text = {}

text[1] = _([[You greet Chelsea as usual and have a friendly chat with them. You learn that they had a close call recently with another group of gangsters, but they managed to shake them off with their new ship.

"I'm making a lot more money than before. The work is tough though. I've been picking off small pirates with bounties on their heads, doing system patrols, that sort of thing. I'm supposed to be getting a better ship soon, but it's going to be difficult." You ask them why that is. "Well, I came across someone who's offering me a bargain on a new ship! Well, not new exactly. It's used, but in pretty good condition. Supposedly this guy used to be a bounty hunter and is offering me his old Vigilance if I just take care of this one pirate known as %s. Trouble is they're piloting a ship that's stronger than my own.…"

Chelsea pauses in contemplation for a moment. "Say, do you think you could help me out on this one? I just need you to help me kill the pirate in %s. I'll give you %s for the trouble. How about it?"]])

text[2] = _([["Fantastic! Thank you for the help! I'll meet you in %s and we can take the pirate out. Let's do this!"]])

text[3] = _([["Ah, you're busy, eh? Oh well. Let me know if you change your mind, OK?"]])

text[4] = _([["Hey, %s! Any chance you could reconsider? I could use your help."]])

text[5] = _([[Chelsea pops up on your viewscreen and grins. "We did it!" they say. "Thanks for all the help, %s. I've transferred the money into your account. See you next time with my new ship!" You say your goodbyes and go back to your own adventures.]])

misn_title = _("Moving Up")
misn_desc = _("Chelsea needs you help them kill a wanted pirate in %s.")

npc_name = _("Chelsea")
npc_desc = _("Oh, it's Chelsea! You feel an urge to say hello.")

chelkill_msg = _("MISSION FAILED: A rift in the space-time continuum causes you to have never met Chelsea in that bar.")
chelflee_msg = _("MISSION FAILED: Chelsea has abandoned the mission.")
plflee_msg = _("MISSION FAILED: You have abandoned the mission.")

log_text = _([[You helped Chelsea hunt down a wanted pirate, earning a bounty for both of you and allowing Chelsea to acquire a retired Dvaered warlord's old Vigilance.]])


function create ()
   local systems = getsysatdistance(system.cur(), 1, 3,
      function(s)
         local p = s:presences()["Pirate"]
         return p ~= nil and p > 0
      end)

   if #systems == 0 then
      -- No pirates nearby
      misn.finish(false)
   end

   missys = systems[rnd.rnd(1, #systems)]
   if not misn.claim(missys) then misn.finish(false) end

   pirname = pirate_name()
   credits = 300000
   started = false

   misn.setNPC(npc_name, "soromid/unique/chelsea.png", npc_desc)
end


function accept ()
   local txt
   if started then
      txt = text[4]:format(player.name())
   else
      txt = text[1]:format(pirname, missys:name(), creditstring(credits))
   end
   started = true

   if tk.yesno("", txt) then
      tk.msg("", text[2]:format(missys:name()))
      misn.accept()

      misn.setTitle(misn_title)
      misn.setDesc(misn_desc:format(missys:name()))
      misn.setReward(creditstring(credits))

      local osd_desc = {}
      osd_desc[1] = string.format(_("Fly to the %s system"), missys)
      osd_desc[2] = string.format(
            _("Protect Chelsea and help them kill %s"), pirname)
      misn.osdCreate(misn_title, osd_desc)

      marker = misn.markerAdd(missys, "high")

      hook.enter("enter")
      hook.jumpout("leave")
      hook.land("leave")
   else
      tk.msg("", text[3])
      misn.finish()
   end
end


function enter ()
   if system.cur() == missys then
      spawn()
   end
end


function spawn ()
   pilot.clear()
   pilot.toggleSpawn(false)
   player.pilot():setVisible(true)

   -- Spawn pirate
   local r = system.cur():radius()
   local x = rnd.rnd(-r, r)
   local y = rnd.rnd(-r, r)
   local p = pilot.add("Pirate Phalanx", "Pirate", vec2.new(x, y))

   hook.pilot(p, "death", "pirate_death")
   p:setHostile()
   p:setVisible(true)
   p:setHilight(true)

   -- Spawn Chelsea
   chelsea = pilot.add("Vendetta", "Comingout_associates", lastsys,
         _("Chelsea"), {naked=true})
   chelsea:outfitAdd("Milspec Aegis 3601 Core System")
   chelsea:outfitAdd("S&K Light Stealth Plating")
   chelsea:outfitAdd("Unicorp Hawk 300 Engine")
   chelsea:outfitAdd("Unicorp Mace Launcher", 2)
   chelsea:outfitAdd("Plasma Blaster MK2", 3)
   chelsea:outfitAdd("Unicorp Mace Launcher")
   chelsea:outfitAdd("Power Regulation Override")
   chelsea:outfitAdd("Steering Thrusters")

   chelsea:setHealth(100, 100)
   chelsea:setEnergy(100)
   chelsea:setTemp(0)
   chelsea:setFuel(true)
   chelsea:fillAmmo()

   chelsea:setFriendly()
   chelsea:setHilight()
   chelsea:setVisible()
   chelsea:setInvincPlayer()

   chelsea:control()
   chelsea:attack(p)

   hook.pilot(chelsea, "death", "chelsea_death")
   hook.pilot(chelsea, "jump", "chelsea_leave")
   hook.pilot(chelsea, "land", "chelsea_leave")
end


function leave ()
   lastsys = system.cur()
   if lastsys == missys then
      fail(plflee_msg)
   end
end


function chelsea_death ()
   fail(chelkill_msg)
end


function chelsea_leave ()
   fail(chelflee_msg)
end


function pirate_death ()
   chelsea:setNoDeath(true)
   pilot.toggleSpawn(true)
   hook.timer(1, "win_timer")
end


function win_timer ()
   tk.msg("", text[5]:format(player.name()))
   player.pay(credits)

   local t = time.get():tonumber()
   var.push("comingout_time", t)

   srm_addComingOutLog(log_text)

   misn.finish(true)
end


-- Fail the mission, showing message to the player.
function fail(message)
   if message ~= nil then
      -- Pre-colourized, do nothing.
      if message:find("#") then
         player.msg(message)
      -- Colourize in red.
      else
         player.msg("#r" .. message .. "#0")
      end
   end
   misn.finish(false)
end
