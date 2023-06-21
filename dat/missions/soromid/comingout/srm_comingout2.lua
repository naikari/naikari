--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Coming of Age">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>29</priority>
  <done>Coming Out</done>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Durea</planet>
  <cond>var.peek("comingout_time") == nil or time.get() &gt;= time.fromnumber(var.peek("comingout_time")) + time.create(0, 20, 0)</cond>
 </avail>
 <notes>
  <campaign>Coming Out</campaign>
 </notes>
</mission>
--]]
--[[

   Coming of Age

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
require "missions/soromid/common"


ask_text = _([[Chelsea looks up and smiles as she sees you approaching. "{player}! It's good to see you again. It's been a while!" You sit down and ask about how coming out to her parents went. "It went well!" she answers. "They both seem to be supportive. They keep accidentally using the wrong name and pronouns, but they're trying at least.

"I finally got my pilot's license, by the way! I'm really excited to get started. Just have to get my first ship. Say, could you help me with that? See, I found a ship for a bargain at {planet} in the {system} system, but I need a transport to get there. I could pay you {credits} to take me there. Well? What do you say?"]])

yes_text = _([["Thank you so much! I really appreciate it, {player}, especially because I know you're not going to treat me like shit on the way. I can't wait to start piloting for real!"]])

no_text = _([["Oh, okay. Let me know if you change your mind!"]])

ask_again_text = _([["Oh, {player}! Are you able to help me out now? Just a transport to {planet} in the {system} system is all I need, for {credits}."]])

landtext = _([[As you dock you can barely stop Chelsea from jumping out of your ship and hurting herself. She seems to know exactly where to go and before you even know what's going on, she's purchased a Llama from the shipyard which is considerably damaged and rusty, but in working order nonetheless. You express concern about the condition of the ship, but she assures you that she will fix it up as she gets enough money to do so. She gives you a friendly hug, thanks you, and hands you a credit chip. "Catch up with me again sometime, okay? I'll be hanging out in Soromid space doing my first missions as a pilot!" As you walk away, you see her getting her first close-up look at the mission computer with a look of excitement in her eyes.]])

misn_title = _("Coming of Age")
misn_desc = _("Chelsea needs you to take her to {planet} ({system} system) so she can buy her first ship and kick off her piloting career.")

npc_name = _("Chelsea")
npc_desc = _("She seems to just be idly reading the news. It's been a while; maybe you should say hi?")

log_text = _([[You helped transport Chelsea to {planet}, where she was able to buy her first ship, a Llama which is damaged and rusty, but working. As she went on to start her career as a freelance pilot, she asked you to catch up with her again sometime. She expects that she'll be sticking to Soromid space for the time beïng.]])


function create ()
   -- Note: This mission does not make system claims
   misplanet, missys = planet.getLandable("Crow")
   if misplanet == nil then
      misn.finish(false)
   end

   credits = 200000
   started = false

   misn.setNPC(npc_name, "soromid/unique/chelsea.png", npc_desc)
end


function accept ()
   local txt
   if started then
      txt = ask_again_text:format(player.name())
   else
      txt = ask_text:format(player.name(), misplanet:name(), missys:name())
   end
   started = true

   if tk.yesno("", fmt.f(txt,
         {player=player.name(), planet=misplanet:name(),
            system=missys:name(), credits=fmt.credits(credits)})) then
      tk.msg("", fmt.f(yes_text, {player=player.name()}))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setDesc(fmt.f(misn_desc,
            {planet=misplanet:name(), system=missys:name()}))
      misn.setReward(fmt.credits(credits))
      marker = misn.markerAdd(missys, "low")

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system)"),
               {planet=misplanet:name(), system=missys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)

      hook.land("land")
   else
      tk.msg("", no_text)
      misn.finish()
   end
end


function land ()
   if planet.cur() == misplanet then
      tk.msg("", landtext)
      player.pay(credits)

      local t = time.get():tonumber()
      var.push("comingout_time", t)

      srm_addComingOutLog(fmt.f(log_text, {planet=misplanet:name()}))

      misn.finish(true)
   end
end
