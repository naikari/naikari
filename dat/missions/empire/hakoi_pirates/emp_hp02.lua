--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Hakoi's Hidden Jumps">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>
   faction.playerStanding("Empire") &gt;= 10
   and faction.playerStanding("Dvaered") &gt;= 0
  </cond>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Emperor's Fist</planet>
  <done>Undercover in Hakoi</done>
 </avail>
 <notes>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</mission>
--]]
--[[

   Hakoi's Hidden Jumps

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

   MISSION: Hakoi's Hidden Jumps
   DESCRIPTION:
      The Empire believes the pirates have hidden jumps in Hakoi and
      tasks the player with observing pirates as they jump into the
      system to gather data.

--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "missions/empire/common"


ask_text = _([["Hello again, {player}. It's good to see you. We have another mission for you in {system}. This one will be a bit more dangerous than the last one, but we will pay a substantial sum of credits, {credits}. Are you up to the challenge?"]])

accept_text = _([["I am happy to hear that, {player}! I knew we could count on you. According to the civilian you questioned, pirates seem to be approaching from the direction of the asteroid field. We have reason to believe there must be a hidden jump point somewhere around there which the pirates are jumping into the system thru.

"We want you to go to the area of the {system} asteroid field and test this theory. You won't be able to see the jump point itself, but by observing the area, you should be able to catch pirates jumping into the system.

"I would recommend equipping a Sensor Array or two to extend your radar range; you should be able to find those at the outfitter here. Once you have completed your objective, meet with me here on {startplanet}. Good luck!"]])

decline_text = _([["That is quite understandable. Take as much time as you need to prepare and talk to me again when you change your mind."]])

finish_text = _([[You notice that Commander Soldner is already waiting for you as docking procedures begin. He greets you as you exit your craft. "Good work, {player}," he says. "With this data you have gathered, we should be able to get a much better idea of where those pirates are coming from. My subordinates are already downloading the data from your ship as we speak, and your payment has been deposited into your account.

"Now we must wait for the analysis of the data you have collected. I'm sure we will have a need to enlist your services again before long. I'll see you again at the bar here on {planet} when I have another mission for you. In the meantime, I would recommend purchasing a Mercenary License, if you haven't already, and giving some basic combat missions a try. I'm sure the experience will prove to be invaluable as we take on this pirate menace."]])

misn_title = _("Hakoi's Hidden Jumps")
misn_desc = _("Commander Soldner has sent you to the {system} system to scout the area and watch as pirates jump in. He said that he expects the pirates are jumping in thru a hidden jump point near the asteroid field.")

log_text = _([[You did some observation in the {destsys} system for Commander Soldner, watching as pirates jumped into the system. He suggested getting yourself a Mercenary License and trying some combat missions before returning to {startplanet} ({startsys} system) for another mission.]])


function create()
   missys = system.get("Hakoi")
   startpla, startsys = planet.cur()
   if not misn.claim(missys) then
      misn.finish(false)
   end

   credits = 400000
   jumps_witnessed = 0
   jumps_needed = 5

   misn.setNPC(_("Soldner"), "empire/unique/soldner.png",
         _("You see Commander Soldner at the bar. He said he would have another mission for you."))
end


function accept()
   if tk.yesno("", fmt.f(ask_text,
         {player=player.name(), system=missys:name(),
            credits=fmt.credits(credits)})) then
      tk.msg("", fmt.f(accept_text,
            {player=player.name(), credits=fmt.credits(credits),
               system=missys:name(), startplanet=startpla:name()}))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(credits))
      misn.setDesc(fmt.f(misn_desc, {system=missys:name()}))

      marker = misn.markerAdd(missys, "plot")

      update_osd()

      hook.enter("enter")
      hook.land("land")
   else
      tk.msg("", decline_text)
      misn.finish()
   end
end


function inList(x, t)
   for i, item in ipairs(t) do
      if item == x then
         return true
      end
   end
   return false
end


function update_osd()
   local osd_desc = {
      fmt.f(_("Wait in the area around the asteroid field in Hakoi until you witness pirates jumping in ({witnessed}/{needed})"),
            {witnessed=jumps_witnessed, needed=jumps_needed}),
      fmt.f(_("Land on {planet} ({system} system)"),
            {planet=startpla:name(), system=startsys:name()}),
   }
   misn.osdCreate(misn_title, osd_desc)

   if jumps_witnessed >= jumps_needed then
      misn.osdActive(2)
      misn.markerMove(marker, startsys, startpla)
      hook.rm(update_hook)
   end
end


function enter()
   witnessed_pilots = {}
   hook.rm(update_hook)

   if system.cur() == missys then
      update_hook = hook.update("update")
   end
end


function update()
   for i, p in ipairs(player.pilot():getVisible()) do
      if p:faction() == faction.get("Pirate") and p:flags().hyperspace_end
            and not inList(p, witnessed_pilots) then
         jumps_witnessed = jumps_witnessed + 1
         table.insert(witnessed_pilots, p)
         player.msg(fmt.f(_("Witnessed {pilot} jumping in."), {pilot=p:name()}))
      end
   end

   update_osd()
end


function land()
   hook.rm(update_hook)

   if planet.cur() == startpla and jumps_witnessed >= jumps_needed then
      tk.msg("", fmt.f(finish_text,
            {player=player.name(), planet=startpla:name()}))

      player.pay(credits)
      faction.modPlayer("Empire", 3)
      emp_addShippingLog(fmt.f(log_text,
            {destsys=missys:name(), startplanet=startpla:name(),
               startsys=startsys:name()}))
      misn.finish(true)
   end
end
