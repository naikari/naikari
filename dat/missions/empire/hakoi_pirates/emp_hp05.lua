--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Hakoi Iceberg">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>faction.playerStanding("Empire") &gt;= 10</cond>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Emperor's Fist</planet>
  <done>Empire Recruitment</done>
 </avail>
 <notes>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</mission>
--]]
--[[

   MISSION: Tip of the Iceberg
   DESCRIPTION:
      Ian Structure volunteers additional information: the situation in
      Hakoi may be just the tip of the iceberg.

--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "missions/empire/common"


ask_text = _([[Since you don't see Commander Soldner around, you decide to approach Ian Structure and see what he wants. He greets you and sits you down. "I've heard about what you've been working on for the Empire," he begins. "Look, I… I want to help, and I think I might be able to. I just need you to keep it a secret; if they find out I helped you… I don't want to th-think about what c-could happen." He nervously straightens his necktie.

"I don't know if you've ever been to {planet} in the {system} system."]])

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
   misplanet, missys = planet.getLandable("Darkshed")
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
      hook.load("land")
   else
      tk.msg("", decline_text)
      misn.finish()
   end
end


function land()
   if planet.cur() == misplanet and not job_done then
      misn.npcAdd("approach", _("Imperial Civilian"), portrait.get(),
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
