--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Diversion from Doranthex">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <chance>60</chance>
  <done>Disrupt a Dvaered Patrol</done>
  <location>Bar</location>
  <faction>FLF</faction>
  <cond>faction.playerStanding("FLF") &gt;= 10</cond>
 </avail>
 <notes>
  <campaign>Save the Frontier</campaign>
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


approach_text = _([[Benito smiles as you approach her. "Hello again, {player}!" she says. "I have another mission for you, should you choose to accept it. We're trying to evacuate some of ours stranded in Doranthex, a Dvaered-owned system. Security is tight and we just can't find an opening. I need someone to distract the Dvaered forces so we can give them more of a fighting chance. You'll basically need to travel to the {system} system and wreak havoc there so that the Dvaereds go after you and not the soldiers trying to escape Doranthex.

"Of course, this will be a highly dangerous mission, and I can't guarantee any backup for you. You will be paid substantially, however, and this will surely earn you more respect among our ranks. Would you be interested?"]])

yes_text = _([["Great! The rescue team will await an opening from a safe location in the vicinity of Doranthex. I will message you when they succeed in rescuing the stranded soldiers. I would recommend a very small fighter for this mission so that you can outrun any ships the Dvaereds throw at you. Good luck, and try not to get yourself killed!" She winks, and you laugh both nervously and in amusement at the same time. Now to cause some mayhem.…]])

no_text = _([["OK, then. Feel free to come back later if you change your mind."]])

success_text = {}
success_text[1] = _([[You receive a transmission. It's from Benito. "Operation successful!" she says. "You should get back to the base now before you get killed! I'll be waiting for you there."]])

pay_text = {}
pay_text[1] = _([[As you dock the station, Benito approaches you with a smile. "Thank you for your help," she says. "The mission was a rousing success! All of our stranded soldiers have been successfully evacuated." She hands you a credit chip. "That's your payment. Until next time!" Benito sees herself out as some of the soldiers you helped rescue personally come up to thank you for risking your life to save theirs.]])

misn_title = _("Diversion from Doranthex")
misn_desc = _("You have been tasked with creating mayhem for Dvaered ships in the {system} system to distract the Dvaereds while an FLF rescue team helps some trapped soldiers escape from Doranthex.")
misn_reward = _("Substantial pay and a great amount of respect")

npc_name = _("Benito")
npc_desc = _("Benito seems to want to speak with you.")

log_text = _([[You helped the FLF rescue stranded soldiers from Doranthex by by distracting the Dvaereds in another system.]])


function create ()
   missys = system.get("Tuoladis")
   if not misn.claim(missys) then misn.finish(false) end

   dv_attention_target = 20
   credits = 250000
   reputation = 2

   misn.setNPC(npc_name, "flf/unique/benito.png", npc_desc)
end


function accept ()
   if tk.yesno("", fmt.f(approach_text,
            {player=player.name(), system=missys:name()})) then
      tk.msg("", yes_text)

      misn.accept()

      osd_desc[1] = osd_desc[1]:format(missys:name())
      misn.osdCreate(osd_title, osd_desc)
      misn.setTitle(misn_title)
      misn.setDesc(fmt.f(misn_desc, {system=missys:name()}))
      marker = misn.markerAdd(missys, "plot")
      misn.setReward(misn_reward)

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


function land ()
   if planet.cur():faction() == faction.get("FLF") then
      tk.msg("", pay_text[rnd.rnd(1, #pay_text)])
      player.pay(credits)
      flf_modCap(5)
      faction.get("FLF"):modPlayer(reputation)
      flf_addLog(log_text)
      misn.finish(true)
   end
end
