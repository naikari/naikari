--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Hakoi and Salvador">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>
   faction.playerStanding("Empire") &gt;= 10
   and faction.playerStanding("Dvaered") &gt;= 0
   and player.numOutfit("Mercenary License") &gt; 0
   and player.misnDone("The macho teenager")
  </cond>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Emperor's Fist</planet>
  <done>Hakoi's Hidden Jumps</done>
 </avail>
 <notes>
  <done_misn name="The macho teenager"/>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</mission>
--]]
--[[

   Salvador, the Safe Harbor

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

   MISSION: Salvador, the Safe Harbor
   DESCRIPTION:
      The Empire has traced the source of pirates to the independent
      Salvador system, but is being stopped by local resistence to
      intrusion on the system's independence. The Empire, therefore,
      tasks you with a capture mission to find out what exactly is 
      going on there.

--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "missions/empire/common"


ask_text = _([["Ah, yes, {player}! I've been waiting for you. Thank you for coming.

"The truth is, we have a troubling situation, and we need you help once again. See, we traced the origin of the pirates to the nearby {system} system, which is an independent system that has declined permission for Imperial forces to investigate there. We can't afford a diplomatic incident right now, so our hands are tied. But you, on the other hand, would still be considered an independent mercenary, and I understand you have acquired some experience with ship capture. If you would be of service to the Empire again and capture just one pirate for us, we will reward you with {credits}. What do you say?"]])

accept_text = _([["I'm relieved, {player}. Truthfully, of all the independent contractors we could work with, there are none who I would rather entrust this mission to than you.

"All you need to do is disable and board any pirate ship in the {system} system, retrieve their flight logs, and take them to me here on {startplanet}. Don't forget to equip some non-lethal weaponry for the job. Good luck, {player}!"]])

decline_text = _([["That is very unfortunate, but the offer remains open. Please let me know if you change your mind. We need you, {player}."]])

board_text = _([[You successfully board the {pilot_name} and download its flight logs. It seems to have exactly what Commander Soldner needs.

You consider that you might as well loot the ship while you're here. They're wanted criminals anyway, so it's not as if you would be breaking the law.]])

land_text = _([[You search around for Commander Soldner, but you don't see him in the immediate vicinity. Perhaps you should check at the bar.]])

approach_text = _([[As you approach, you greet Commander Soldner and salute the Imperial Commodore. The Commodore speaks up with a relaxed smile that somehow feels firm at the same time. "Ah, you must be {player}! I'm Commodore Keer. Pleased to make your acquaintance." She offers her hand, which you cautiously shake. "Commander Soldner has told me great things about you. Perhaps we will work together at some point in the future.

"In any case, I must go now. Thank you for the report, Commander. It sounds like the Hakoi situation is in good hands." Commodore Keer stands and excuses herself, presumably to attend to other matters.]])

finish_text = _([[Commander Soldner smiles as Commodore Keer leaves. "Apologies, {player}. It seems the Hakoi situation is serious enough that she wanted to check on the Hakoi situation personally. With the Empire's resources stretched so thin, I can't imagine how difficult the Commodore's job must be. It's largely because of you that we have the Hakoi situation under control, and I think it's clear that the Commodore recognizes that. You should be proud, {player}.

"In any case, I presume you must have those flight logs now." You nod affirmatively and hand Commander Soldner the data chip with the flight logs on it. "Good work, {player}!" he says as he simultaneously takes the data chip from you and hands you a credit chip with the promised payment. "You've done an excellent job. Let me take a look at what we've got here so we can determine our next course of action."]])

misn_title = _("The Safe Harbor")
misn_desc = _("Commander Soldner has tasked you with capturing a pirate ship in the {system} system and retrieving its flight logs.")

log_text = _([[You infiltrated a pirate ship in the {destsys} system so you could obtain its flight logs to help Commander Soldner investigate the Hakoi situation further. He should have another mission for you at {startplanet} ({startsys} system).]])


function create()
   missys = system.get("Salvador")
   startpla, startsys = planet.cur()
   if not misn.claim(missys) then
      misn.finish(false)
   end

   credits = 400000
   job_done = false

   misn.setNPC(_("Soldner"), "empire/unique/soldner.png",
         _("Commander Soldner sees you and motions for you to come over. This might be important."))
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

      local osd_desc = {
         fmt.f(_("Fly to the {system} system"), {system=missys:name()}),
         _("Disable and board any pirate"),
         fmt.f(_("Land on {planet} ({system} system)"),
            {planet=startpla:name(), system=startsys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)

      enter_hook = hook.enter("enter")
      board_hook = hook.board("player_board")
      hook.land("land")
   else
      tk.msg("", fmt.f(decline_text, {player=player.name()}))
      misn.finish()
   end
end


function enter()
   if job_done then
      return
   end

   if system.cur() == missys then
      misn.osdActive(2)
   else
      misn.osdActive(1)
   end
end


function player_board(p)
   if job_done or system.cur() ~= missys then
      return
   end
   if p:faction() ~= faction.get("Pirate") then
      return
   end

   tk.msg("", fmt.f(board_text, {pilot_name=p:name()}))
   job_done = true
   misn.osdActive(3)
   misn.markerMove(marker, startsys, startpla)

   hook.rm(enter_hook)
   hook.rm(board_hook)
end


function land()
   if planet.cur() == startpla and job_done then
      tk.msg("", land_text)

      soldner = misn.npcAdd("approach", _("Soldner"),
            "empire/unique/soldner.png",
            _("You see Commander Soldner deep in conversation with another Imperial officer."),
            10)
      keer = misn.npcAdd("approach", _("Imperial Commodore"),
            "empire/unique/keer.png",
            _("Judging by the emblem on her uniform, this officer appears to be a Commodore."),
            10)
   end
end


function approach()
   tk.msg("", fmt.f(approach_text, {player=player.name()}))
   misn.npcRm(keer)

   tk.msg("", fmt.f(finish_text,
         {player=player.name(), planet=startpla:name()}))

   player.pay(credits)
   faction.modPlayer("Empire", 3)
   emp_addShippingLog(fmt.f(log_text,
         {destsys=missys:name(), startplanet=startpla:name(),
            startsys=startsys:name()}))

   naev.missionStart("Hakoi Needs House Dvaered")

   misn.finish(true)
end
