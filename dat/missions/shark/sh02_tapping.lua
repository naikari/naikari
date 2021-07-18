--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Unfair Competition">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>3</priority>
  <cond>diff.isApplied("collective_dead")</cond>
  <done>Sharkman Is Back</done>
  <chance>3</chance>
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
  <requires name="The Collective is dead and no one will miss them"/>
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

require "numstring"
require "missions/shark/common"


text = {}
osd_msg = {}
npc_desc = {}
bar_desc = {}

text[1] = _([[You sit at Smith's table and ask him if he has a job for you. "Of course," he answers. "But this time, it's... well...

"Listen, I need to explain some background. As you know, Nexus designs are used far and wide in smaller militaries. The Empire is definitely our biggest customer, but the Frontier also notably makes heavy use of our Lancelot design, as do many independent systems. Still, competition is stiff; House Dvaered's Vendetta design, for instance, is quite popular with the FLF, ironically enough.

"But matters just got a little worse for us: it seems that House Sirius is looking to get in on the shipbuilding business as well, and the Frontier are prime targets. If they succeed, the Lancelot design could be completely pushed out of Frontier space, and we would be crushed in that market between House Dvaered and House Sirius. Sure, the FLF would still be using a few Pacifiers, but it would be a token business at best, and not to mention the authorities would start associating us with terrorism.

"So we've conducted a bit of espionage. We have an agent who has recorded some hopefully revealing conversations between a House Sirius sales manager and representatives of the Frontier. All we need you to do is meet with the agent, get the recordings, and bring them back to me on %s in the %s system." You raise an eyebrow.

"It's not exactly legal. That being said, you're just doing the delivery, so you almost certainly won't be implicated. What do you say? Is this something you can do?"]])

refusetext = _([["OK, sorry to bother you."]])

text[2] = _([["I'm glad to hear it. Go meet our agent on %s in the %s system. Oh, yes, and I suppose I should mention that I'm known as 'James Neptune' to the agent. Good luck!"]])

text[3] = _([[The Nexus employee greets you as you reach the ground. "Excellent! I will just need to spend a few hectoseconds analyzing these recordings. See if you can find me in the bar soon; I might have another job for you."]])

text[4] = _([[You approach the agent and obtain the package without issue. Before you leave, he suggests that you stay vigilant. "They might come after you," he says.]])


-- Mission details
misn_title = _("Unfair Competition")
misn_desc = _("Nexus Shipyards is in competition with House Sirius.")

-- NPC
npc_desc[1] = _("Arnold Smith")
bar_desc[1] = _([[Arnold Smith is here. Perhaps he might have another job for you.]])
npc_desc[2] = _("Nexus's agent")
bar_desc[2] = _([[This guy seems to be the agent Arnold Smith was talking about.]])

-- OSD
osd_title = _("Unfair Competition")
osd_msg[1] = _("Land on %s (%s system) and meet the Nexus agent")
osd_msg[2] = _("Land on %s (%s system)")

log_text = _([[You helped Nexus Shipyards gather information in an attempt to sabotage competition from House Sirius. Arnold Smith said to meet him in the bar soon; he may have another job for you.]])


function create ()
   mispla, missys = planet.getLandable(faction.get("Sirius"))

   if not misn.claim(missys) or not mispla:services()["bar"] then
      misn.finish(false)
   end

   pplname = "Darkshed"
   psyname = "Alteris"
   paysys = system.get(psyname)
   paypla = planet.get(pplname)

   misn.setNPC(npc_desc[1], "neutral/unique/arnoldsmith.png", bar_desc[1])
end


function accept()

   stage = 0
   reward = 750000
   proba = 0.3  --the chances you have to get an ambush

   if tk.yesno("", text[1]:format(pplname, psyname)) then
      misn.accept()
      tk.msg("", text[2]:format(mispla:name(), missys:name()))

      osd_msg[1] = osd_msg[1]:format(mispla:name(), missys:name())
      osd_msg[2] = osd_msg[2]:format(pplname, psyname)

      misn.setTitle(misn_title)
      misn.setReward(creditstring(reward))
      misn.setDesc(misn_desc)
      osd = misn.osdCreate(osd_title, osd_msg)
      misn.osdActive(1)

      marker = misn.markerAdd(missys, "low")

      landhook = hook.land("land")
      enterhook = hook.enter("enter")
   else
      tk.msg("", refusetext)
      misn.finish(false)
   end
end


function land()
   --The player is landing on the mission planet to get the box
   if stage == 0 and planet.cur() == mispla then
      agent = misn.npcAdd("beginrun", npc_desc[2],
            "neutral/unique/nexus_agent.png", bar_desc[2])
   end

   --Job is done
   if stage == 1 and planet.cur() == paypla then
      if misn.cargoRm(records) then
         tk.msg("", text[3])
         player.pay(reward)
         misn.osdDestroy(osd)
         hook.rm(enterhook)
         hook.rm(landhook)
         shark_addLog(log_text)
         misn.finish(true)
      end
   end
end


function enter()
   -- Ambush !
   if stage == 1 and rnd.rnd() < proba then
      hook.timer(2000, "ambush")
      proba = proba - 0.2
   elseif stage == 1 then
      --the probability of an ambush goes up when you cross a system without meeting any ennemy
      proba = proba + 0.1
   end
end


function beginrun()
   tk.msg("", text[4])
   records = misn.cargoAdd("Box", 0)  --Adding the cargo
   stage = 1
   misn.osdActive(2)
   misn.markerRm(marker)
   marker2 = misn.markerAdd(paysys, "low")

   --remove the spy
   misn.npcRm(agent)
end


function ambush()
   badguys = {}
   ship_choices = {
      "Hyena", "Shark", "Lancelot", "Vendetta", "Ancestor", "Admonisher",
      "Phalanx", "Kestrel", "Hawking"}

   for i=1,4 do
      local choice = ship_choices[rnd.rnd(1, #ship_choices)]
      badguys[i] = pilot.add(choice, "Mercenary", nil, string.format(
               _("Mercenary %s"), choice))
   end

   --and a Llama for variety :
   if rnd.rnd() < 0.5 then
      add_llama()
   end
end
