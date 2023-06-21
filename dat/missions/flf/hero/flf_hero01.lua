--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Diversion from Doranthex">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <chance>30</chance>
  <done>Disrupt a Dvaered Patrol</done>
  <location>Bar</location>
  <faction>FLF</faction>
  <faction>Frontier</faction>
  <cond>faction.playerStanding("FLF") &gt;= 10</cond>
 </avail>
 <notes>
  <campaign>FLF Hero</campaign>
 </notes>
</mission>
--]]
--[[

   Diversion from Doranthex

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
require "missions/flf/flf_diversion"
require "missions/flf/flf_common"


approach_text = _([[You approach Flint and he looks at you with faint surprise. "Oh, {player}! I see you've made the right choice. I heard about your antics with those Dvaereds that ambushed you. Good on you for making the right call! We of course would've obliterated you like the rest of them if you'd taken the Dvaereds' side." He grins and winks, prompting you to laugh somewhat nervously.

Flint's expression becomes more serious. "{player}, since you've proven yourself, maybe I can count on you for an important mission. See, some of my comrades are stranded in the Doranthex system. We're trying to assemble a rescue party, but the place is just crawling with Dvaereds. If we could creäte a distraction by wreaking havok in the nearby {system} system, maybe that would give us just the opening that we need! That's where you come in. I can't guarantee any backup for you, and of course this will be a highly dangerous mission, but if you do this, I can guarantee you that we'll never forget your bravery. How about it, {player}? Are you in?"]])

yes_text = _([[Flint's expression relaxes into one of relief. "Thank you so much! The rescue team will await an opening from a safe location in the vicinity of Doranthex. I will message you when we succeed in rescuing the stranded soldiers, and we can regroup at Sindbad.

"I would recommend a very small fighter that can outrun any ships the Dvaereds throw at you. Beïng able to dodge their volleys of bullets and stay alive is a lot more important than actually destroying them, after all. Just keep harassing them by shooting whatever weapons you have and I'm sure the Dvaereds will get angry and send reënforcements in. Also, I know I said I couldn't guarantee backup, but I'll try to see if I can find others to join you. Your act of bravery might be contagious, you know? In any case, good luck, comrade!" Your mouth instinctively opens in surprise as you hear him refer to you as "comrade", then you smile and nod. Now to cause some mayhem.…]])

no_text = _([["OK, then. I understand. Let me know if you change your mind, OK?"]])

success_text = {}
success_text[1] = _([[You receive a transmission. It's from Flint. "We got 'em out!" he exclaims. "Nice work! The Dvaereds were all thinned out thanks you you! We're all set, comrade; we'll meet you back at the base!"]])

pay_text = {}
pay_text[1] = _([[You find Flint among a crowd and when he sees you, he approaches you with a warm smile and gives you a high-five. "We did it! We rescued all of them! You did a fantastic job. I can't possibly thank you enough." As the fact that you led the efforts to distract the Dvaereds becomes clear to the crowd, several voices speak up as the comrades you rescued thank you. After a celebration, you part ways as Flint wishes you good luck on your next mission.]])

misn_title = _("Diversion from Doranthex")
misn_desc = _("You have been tasked with creäting mayhem for Dvaered ships in the {system} system to distract the Dvaereds while an FLF rescue team helps some trapped soldiers escape from Doranthex.")

npc_name = _("Flint")
npc_desc = _("You see Flint and remember you never got a chance to thank him for teaching you about the Frontier's struggle. Perhaps you should do so.")

log_text = _([[You helped Flint rescue stranded soldiers from Doranthex by by distracting the Dvaereds in another system.]])


function create()
   missys = system.get("Tuoladis")
   if not misn.claim(missys) then
      misn.finish(false)
   end

   dv_attention_target = 10
   credits = 250000
   reputation = 5

   misn.setNPC(npc_name, "flf/unique/flint.png", npc_desc)
end


function accept()
   if tk.yesno("", fmt.f(approach_text,
            {player=player.name(), system=missys:name()})) then
      tk.msg("", yes_text)

      misn.accept()

      osd_desc[1] = osd_desc[1]:format(missys:name())
      misn.osdCreate(osd_title, osd_desc)
      misn.setTitle(misn_title)
      misn.setDesc(fmt.f(misn_desc, {system=missys:name()}))
      marker = misn.markerAdd(missys, "plot")
      misn.setReward(fmt.credits(credits))

      dv_attention = 0
      job_done = false

      hook.enter("enter")
      hook.jumpout("leave")
      hook.land("leave")
   else
      tk.msg("", no_text)
      misn.finish()
   end
end


function land()
   if planet.cur():faction() == faction.get("FLF") then
      tk.msg("", pay_text[rnd.rnd(1, #pay_text)])
      player.pay(credits)
      faction.get("FLF"):modPlayer(reputation)
      flf_addLog(log_text)
      misn.finish(true)
   end
end
