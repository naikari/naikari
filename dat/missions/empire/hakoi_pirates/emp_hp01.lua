--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Undercover in Hakoi">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>
   faction.playerStanding("Empire") &gt;= 10
   and faction.playerStanding("Dvaered") &gt;= 0
   and var.peek("es_misn") ~= nil
   and var.peek("es_misn") &gt;= 3
  </cond>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Emperor's Fist</planet>
  <done>Empire Recruitment</done>
 </avail>
 <notes>
  <requires name="Completed 3 or more ES deliveries"/>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</mission>
--]]
--[[

   Undercover in Hakoi

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

   MISSION: Undercover in Hakoi
   DESCRIPTION:
      The Empire tasks the player with talking to civilians in Hakoi in
      an effort to find out where the pirates in the area came from.

--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "missions/empire/common"


ask_text = _([[You approach and salute the Imperial Commander. He smiles and offers his hand, which you shake. "I'm pleased to finally meet you, {player}. I'm Commander Soldner. I've heard good things about you and your commitment to the Empire, and if you are willing, I would like to recruit you on a more prestigious mission than those simple deliveries.

"I believe you are a native of {system}, yes? And we are aware that you ran into some trouble there while assisting an acquaintance of yours, Mr. Ian Structure. Of course, {system} used to be peaceful, but as you yourself experienced, pirates showed up in the system out of nowhere recently. We've been able to contain them for now, but we must find out where they came from.

"That's where you come in, {player}. As a native of {system}, I'm sure civilians will be more willing to talk to you than officers in uniform. Your assignment, then, will be to use your connections to question civilians. You will secretly wear a recording device so we can capture the full extent of your conversations and pick up on anything you may have missed. Well, {player}? Are you ready to perform this important duty in service of the Empire?"]])

ask_again_text = _([["Hello again, {player}. Are you ready to assist the Empire in finding out what's going on with the pirates in {system}?"]])

accept_text = _([[Commander Soldner smiles. "We appreciate your service, {player}. I assure you that this will take you on the path to greatness. You will of course also be paid for your efforts. Your reward will be {credits}." He hands you a tiny, plain-looking pin . "This is a listening device. You will wear it as you question the civilians. Do not draw attention to it and I assure you that no one will think anything of it.

"Well, then, {player}, I must be off now. I trust this mission is in good hands. Of course, keep a lookout for pirates while in Hakoi. We can't afford to draw attention to you, so you will not have an Imperial escort and will have to rely on your own guns and the protection of the local police. That said, good luck!"]])

decline_text = _([["I can of course understand your reservations. Please take some time to think about it. If you change your mind, return to me and let me know. I promise it will be worth your while."]])

approach_text = _([[This civilian, who is taking a lunch break, turns out to be quite openly talkative about the pirate situation. You stretch out a long, polite conversation to gather as much information as possible until eventually, the civilian notices the time and leaves to return to work.

It seems you have gathered enough information and can return to {planet}.]])

finish_text = _([[You locate Commander Soldner and hand him the listening device. "Great job, {player}," he says with a smile. "I'm sure the data you've gathered will be of great help to us in our investigation. The promised payment has already been deposited into your account.

"I will now begin to plan our next course of action. Meet me at the bar soon. I believe I will have another mission for you, if you are willing to be of service to the Empire again."]])

misn_desc = _("You have been tasked by Commander Soldner with going on an undercover mission in {system} to try to find information on where the pirates there came from.")

log_text = _([[You assisted the Empire in an undercover operation to try to find out where the pirates in {destsys} came from. Commander Soldner, who gave you the mission, said you should meet him again soon on {startplanet} ({startsys} system) for another mission.]])


function create()
   -- Note: This mission makes no system claims.
   misplanet, missys = planet.getLandable("Em 1")
   startpla, startsys = planet.cur()
   if misplanet == nil then
      misn.finish(false)
   end

   credits = 250000
   talked = false

   misn.setNPC(_("Commander"), "empire/unique/soldner.png",
         _("You see an Imperial Commander. He seems to take interest in you."))
end


function accept()
   local text
   if talked then
      text = fmt.f(ask_again_text,
            {player=player.name(), system=missys:name()})
   else
      text = fmt.f(ask_text,
            {player=player.name(), system=missys:name()})
      talked = true
   end

   if tk.yesno("", text) then
      tk.msg("", fmt.f(accept_text,
            {player=player.name(), credits=fmt.credits(credits)}))

      misn.accept()

      misn.setTitle(_("Undercover in Hakoi"))
      misn.setReward(fmt.credits(credits))
      misn.setDesc(fmt.f(misn_desc,
            {planet=misplanet:name(), system=missys:name()}))

      marker = misn.markerAdd(missys, "plot", misplanet)

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system) and speak to civilians at the bar"),
               {planet=misplanet:name(), system=missys:name()}),
         fmt.f(_("Land on {planet} ({system} system)"),
               {planet=startpla:name(), system=startsys:name()}),
      }
      misn.osdCreate(_("Undercover in Hakoi"), osd_desc)

      job_done = false

      hook.land("land")
   else
      tk.msg("", decline_text)
      misn.finish()
   end
end


function land()
   if planet.cur() == misplanet and not job_done then
      misn.npcAdd("approach", _("Civilian"), portrait.get(),
            _("You see an exhausted civilian sipping a drink while grumbling about the Empire and pirates."),
            100)
   elseif planet.cur() == startpla and job_done then
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


function approach(npc_id)
   tk.msg("", fmt.f(approach_text, {planet=startpla:name()}))
   misn.npcRm(npc_id)
   job_done = true
   misn.markerMove(marker, startsys, startpla)
   misn.osdActive(2)
end
