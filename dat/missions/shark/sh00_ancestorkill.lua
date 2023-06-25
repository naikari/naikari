--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="A Shark Bites">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <cond>planet.cur() ~= planet.get("Ulios") and player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>10</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
 <notes>
  <campaign>Nexus show their teeth</campaign>
 </notes>
</mission>
--]]
--[[

   This is the first mission of the Shark's teeth campaign. The player has to kill a pirate vendetta with a shark.

   Stages :
   0) Way to Ulios in Ingot
   1) Taking off from Ulios and going to Toaxis
   2) Fight in Toaxis
   3) Pirate ran away
   4) Pirate was killed

--]]

local fmt = require "fmt"
require "pilot/pirate"
require "missions/shark/common"


ask_text = _([[You approach the man and he introduces himself. "Hello, my name is Arnold Smith; I work for Nexus Shipyards. I'm looking for a talented pilot to make a demonstration to one of our potential customers.

"Pretty simple, really: we want someone to show how great Nexus ship designs are by destroying a Pirate Vendetta with just one of our smallest ship model, the Shark. Of course, the pilot of the Vendetta has a bounty on his head, so it won't be illegal. You will take the bounty as usual, and Nexus will add a little extra on top of that. Would you be interested?"]])

refusetext = _([["That's your choice," the man says. "Don't hesitate to tell me if you change your mind."]])

yes_text = _([["Great! I knew I could trust you. I'll meet you on {planet} in the {system} system. I'll be with my boss and our customer, Baron Sauterfeldt."]])

brief_text = _([["Nice to see you again," he says with a smile. "I hope you are ready to kick that pirate's ass! Please follow me. I will introduce you to my boss, the sales manager of Nexus Shipyards. Oh, and the Baron, too."

Arnold Smith guides you to some kind of control room where you see some important-looking people. After introducing you to some of them, he goes over the mission, rather over-emphasizing the threat involved; it's just one pirate, after all. Nonetheless, the Baron is intrigued.

Arnold Smith gets a call. After answering, he turns to you. "Perfect timing! The pirate has just arrived at {system}. Now go show them what your ship can do!" Time to head back to the ship, then.]])

pay_text = _([[As you step on the ground, Arnold Smith greets you. "That was a great demonstration! Thank you. I haven't been able to speak to the Baron about the results yet, but I am confident he will be impressed." He hands you your pay. "I may have another mission for you later. Be sure to check back!"]])

-- Mission details
misn_title = _("A Shark Bites")
misn_desc = _("Nexus Shipyards has hired you to demonstrate to Baron Sauterfeldt the capabilities of Nexus ship designs.")

-- NPC
npc_desc = {}
bar_desc = {}
npc_desc[1] = _("An honest-looking man")
bar_desc[1] = _("This man looks like a honest citizen. He glances in your direction.")

npc_desc[2] = _("Arnold Smith")
bar_desc[2] = _([[The Nexus employee who recruited you for a very special demo of the "Shark" fighter.]])

-- OSD
osd_title = _("A Shark Bites")
osd_msg = {}
osd_msg[1] = _("Land on {planet} ({system} system) with a Shark (but not a Pirate Shark) and speak to Arnold Smith")
osd_msg[2] = _("Go to the {system} system and kill the pirate with your Shark")
osd_msg[3] = _("Land on {planet} ({system} system)")

leave_msg = _("MISSION FAILED: You left the pirate.")
piratejump_msg = _("MISSION FAILED: The pirate ran away.")
noshark_msg = _("MISSION FAILED: You were supposed to use a Shark.")

log_text = _([[You helped Nexus Shipyards demonstrate the capabilities of their ships by destroying a Pirate Vendetta.]])


function create()
   mispla, missys = planet.get("Ulios")
   battlesys = system.get("Toaxis")

   if not misn.claim(battlesys) then
      misn.finish(false)
   end

   stage = 0
   reward = 400000

   misn.setNPC(npc_desc[1], "neutral/unique/arnoldsmith.png", bar_desc[1])
end


function accept()
   if tk.yesno("", ask_text) then
      misn.accept()
      piratename = pirate_name()
      tk.msg("", fmt.f(yes_text, {planet=mispla:name(), system=missys:name()}))

      osd_msg[1] = fmt.f(osd_msg[1],
            {planet=mispla:name(), system=missys:name()})
      osd_msg[2] = fmt.f(osd_msg[2], {system=battlesys:name()})
      osd_msg[3] = fmt.f(osd_msg[3],
            {planet=mispla:name(), system=missys:name()})

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(reward))
      misn.setDesc(misn_desc)
      misn.osdCreate(osd_title, osd_msg)
      misn.osdActive(1)

      markeri = misn.markerAdd(missys, "low")

      jumpouthook = hook.jumpout("jumpout")
      landhook = hook.land("land")
      enterhook = hook.enter("enter")
   else
      tk.msg("", refusetext)
      misn.finish()
   end
end


function land()
   local playershipname = player.pilot():ship():nameRaw()
   if planet.cur() == mispla and stage == 0
         and (playershipname == "Shark"
            or playershipname == "Empire Shark") then
      smith = misn.npcAdd("beginbattle", npc_desc[2],
            "neutral/unique/arnoldsmith.png", bar_desc[2])
      var.push(string.format("_escort_disable_%s", battlesys:nameRaw()), true)
   end

   if planet.cur() == mispla and stage == 4 then
      tk.msg("", pay_text)
      player.pay(reward)
      shark_addLog(log_text)
      misn.finish(true)
   end
end


function jumpout()
   if stage == 2 then
      player.msg("#r" .. leave_msg .. "#0")
      misn.finish(false)
   end
end


function enter()
   if system.cur() == battlesys and stage == 1 then
      local playershipname = player.pilot():ship():nameRaw()
      if playershipname ~= "Shark" and playershipname ~= "Empire Shark" then
         player.msg("#r" .. noshark_msg .. "#0")
         misn.finish(false)
      end

      pilot.clear()
      pilot.toggleSpawn(false)

      badboy = pilot.add("Pirate Vendetta", "Pirate", system.get("Raelid"))
      badboy:rename(piratename)
      badboy:setHostile()
      badboy:setVisplayer()
      badboy:setHilight()

      player.pilot():setVisible()

      hook.pilot(badboy, "death", "pirate_dead")
      hook.pilot(badboy, "jump", "pirate_jump")
   end
end


function beginbattle()
   tk.msg("", fmt.f(brief_text, {system=battlesys:name()}))

   misn.markerRm(markeri)
   misn.npcRm(smith)
   misn.osdActive(2)
   stage = 1

   marker1 = misn.markerAdd(battlesys, "low")
end


function pirate_jump()
   pilot.toggleSpawn(true)
   player.msg("#r" .. piratejump_msg .. "#0")
   misn.finish(false)
end


function pirate_dead()
   pilot.toggleSpawn(true)
   player.pilot():setVisible(false)
   stage = 4
   misn.markerRm(marker1)
   marker2 = misn.markerAdd(missys, "low")
   misn.osdActive(3)
end
