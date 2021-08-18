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

require "numstring"
require "missions/soromid/common"


text = {}

ask_text = _([[Chelsea smiles and waves as she sees you approaching. "Hi, %s! It's been a while!" You sit down and start a friendly conversation with her. She mentions that her parents seem to be supportive of her decision to transition and her mother in particular apparently has been very helpful.

Chelsea perks up a little. "So, remember I said I had ambitions of a pilot? Well, I have my piloting license now!" You congratulate her and she thanks you before grimacing slightly. "I, uh, can't manage to get a ship here though." You ask if there's anything you can do to help. "Oh!" she responds. "That's very kind of you!

"Well, I've done some research and I think I should start at %s in the %s system. Would you be able to take me there? I'll pay you for the transportation, of course."]])

yes_text = _([["Thank you so much! I really appreciate it, %s. I've got %s for you when we get there. I can't wait to start!"]])

no_text = _([["Oh, okay. Let me know later on if you're able to!"]])

ask_again_text = _([["Oh, %s! Are you able to help me out now?"]])

landtext = _([[As you dock you can barely stop Chelsea from jumping out of your ship and hurting herself. She seems to know exactly where to go and before you even know what's going on, she's purchased a Llama from the shipyard which is considerably damaged and rusty, but in working order nonetheless. You express concern about the condition of the ship, but she assures you that she will fix it up as she gets enough money to do so. She gives you a friendly hug, thanks you, and hands you a credit chip. "Catch up with me again sometime, okay? I'll be hanging out in Soromid space doing my first missions as a pilot!" As you walk away, you see her getting her first close-up look at the mission computer with a look of excitement in her eyes.]])

misn_title = _("Coming of Age")
misn_desc = _("Chelsea needs you to take her to %s so she can buy her first ship and kick off her piloting career.")

npc_name = _("Chelsea")
npc_desc = _("She seems to just be idly reading the news. It's been a while; maybe you should say hi?")

osd_desc    = {}
osd_desc[1] = _("Land on %s (%s system)")

log_text = _([[You helped transport Chelsea to Crow, where she was able to buy her first ship, a Llama which is damaged and rusty, but working. As she went on to start her career as a freelance pilot, she asked you to catch up with her again sometime. She expects that she'll be sticking to Soromid space for the time being.]])


function create ()
   -- Note: This mission does not make system claims
   misplanet, missys = planet.get("Crow")

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

   if tk.yesno("", txt) then
      tk.msg("", yes_text:format(player.name(), creditstring(credits)))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setDesc(misn_desc:format(misplanet:name()))
      misn.setReward(creditstring(credits))
      marker = misn.markerAdd(missys, "low")

      osd_desc[1] = osd_desc[1]:format(misplanet:name(), missys:name())
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

      srm_addComingOutLog(log_text)

      misn.finish(true)
   end
end
