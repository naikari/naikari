--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Unfair Competition">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <done>Sharkman Is Back</done>
  <chance>10</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
 <notes>
  <campaign>Nexus show their teeth</campaign>
 </notes>
</mission>
--]]
--[[

   This is the third mission of the Shark's teeth campaign. The player has to take illegal holophone recordings in his ship.

   Stages :
   0) Way to Sirius world
   1) Way to Darkshed

--]]

local fmt = require "fmt"
require "missions/shark/common"


ask_text = _([[You sit at Smith's table and ask him if he has a job for you. "Of course," he answers. "But this time, it's… well…

"Listen, I need to explain some background. As you know, Nexus designs are used far and wide not only by the Empire military, but by smaller militaries and mercenaries as well. Aerosys dug into a lot of the Fighter market with their Hyena design, but we were successful in convincing them to join a partnership with us, bundling the ships with Nexus engines and paying us a royalty for each sale. On the other hand, our former dominance in the Cruiser market was shattered by the sudden appearance of Krain Industries, who produced a lighter and cheaper Cruiser, and rather than accepting our deal to bundle our engines, they developed their own Remige Engines. We still sell Hawkings, of course, but pirates have taken a liking to Krain's design and we just no longer make as much money in that market as we used to.

"Recently, we have discovered that another small start-up has cropped up in Sirius space, planning to launch test markets in Frontier space. When we reached out to them, they refused a partnership with us. They're turning into another Krain Industries, and we cannot have that. Nexus dominance in the Fighter market must be sustained.

"So we've conducted a bit of espionage. We have an agent who has recorded some hopefully revealing conversations between a sales manager of the new startup and representatives of the Frontier. All we need you to do is meet with the agent, get the recordings, and bring them back to me on {planet} in the {system} system. It's not exactly legal. That being said, you're just doïng the delivery, so you almost certainly won't be implicated. What do you say? Is this something you can do?"]])

refusetext = _([["OK, sorry to bother you."]])

accept_text = _([["I'm glad to hear it. Go meet our agent on {planet} in the {system} system. Oh, yes, and I suppose I should mention that I'm known as 'James Neptune' to the agent. Good luck!"]])

meet_text = _([[You approach the agent and obtain the package without issue. Before you leave, he suggests that you stay vigilant. "They might come after you," he says.]])

pay_text = _([[The Nexus employee greets you as you reach the ground. "Excellent! This should help us put an end to the new startup and retain our dominance. You have been of great service to Nexus Shipyards. Thank you."]])


-- Mission details
misn_title = _("Corporate Espionage")
misn_desc = _("Nexus Shipyards has tasked you with delivering a package that will enable them to sabotage a new startup seeking to get into the Fighter market.")

-- NPC
arnold_name = _("Arnold Smith")
arnold_desc = _([[Arnold Smith looks at you and motions you over.]])
agent_name = _("Nexus's agent")
agent_desc = _([[This guy seems to be the agent Arnold Smith was talking about.]])

-- OSD
osd_title = _("Corporate Espionage")

log_text = _([[You helped Nexus Shipyards gather information in an attempt to sabotage competition from a new startup.]])


function create()
   -- Note: this mission makes no system claims.
   mispla, missys = planet.getLandable(faction.get("Sirius"))

   if not mispla:services()["bar"] then
      misn.finish(false)
   end

   pplname = "Darkshed"
   psyname = "Alteris"
   paypla, paysys = planet.get("Darkshed")

   misn.setNPC(arnold_name, "neutral/unique/arnoldsmith.png", arnold_desc)
end


function accept()

   stage = 0
   reward = 600000

   if tk.yesno("", fmt.f(ask_text,
            {planet=paypla:name(), system=paysys:name()})) then
      misn.accept()
      tk.msg("", fmt.f(accept_text,
            {planet=mispla:name(), system=missys:name()}))

      local osd_msg = {
         fmt.f(_("Land on {planet} ({system} system) and speak with the Nexus agent at the bar"),
            {planet=mispla:name(), system=missys:name()}),
         fmt.f(_("Land on {planet} ({system} system)"),
            {planet=paypla:name(), system=paysys:name()}),
      }

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(reward))
      misn.setDesc(misn_desc)
      misn.osdCreate(osd_title, osd_msg)
      misn.osdActive(1)

      marker = misn.markerAdd(missys, "low")

      landhook = hook.land("land")
   else
      tk.msg("", refusetext)
      misn.finish()
   end
end


function land()
   --The player is landing on the mission planet to get the box
   if stage == 0 and planet.cur() == mispla then
      agent = misn.npcAdd("beginrun", agent_name,
            "neutral/unique/nexus_agent.png", agent_desc)
   end

   --Job is done
   if stage == 1 and planet.cur() == paypla then
      if misn.cargoRm(records) then
         tk.msg("", pay_text)
         player.pay(reward)
         shark_addLog(log_text)
         misn.finish(true)
      end
   end
end


function beginrun()
   tk.msg("", meet_text)
   local c = misn.cargoNew(N_("Recordings"),
         N_("Recordings obtained by a Nexus agent in an act of corporate espionage."))
   records = misn.cargoAdd(c, 0)
   stage = 1
   misn.osdActive(2)
   misn.markerRm(marker)
   marker2 = misn.markerAdd(paysys, "high")

   --remove the spy
   misn.npcRm(agent)

   -- Add a hook to make mercenaries chase the player.
   hook.custom("merc_spawn", "merc_spawn")
end


function merc_spawn(p)
   if rnd.rnd() < 0.7 then
      p:memory().bounty = player.pilot()
   end
end
