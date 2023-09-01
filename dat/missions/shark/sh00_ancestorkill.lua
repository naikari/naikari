--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="A Shark Bites">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <cond>planet.cur() ~= planet.get("Ulios") and player.numOutfit("Mercenary License") &gt; 0</cond>
  <done>Prince</done>
  <chance>20</chance>
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
  <campaign>Nexus</campaign>
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
local mh = require "misnhelper"
local pilotname = require "pilotname"
require "missions/shark/common"


ask_text = _([[You approach the man and he introduces himself. "Hello! My name is Arnold Smith; I work for Nexus Shipyards. And you would be {player}, correct?" Surprised, you confirm that is indeed you and ask how he knows you. "Ah, my apologies. See, I happened to witness your performance in service of Baron Dovai Sauterfeldt, and I realized you would be the perfect candidate for the job. I've been looking all over for you since then, so I'm glad I've finally caught up with you.

"See, we're seeking the Baron as a potential customer. He has a lot of money, you see, and hasn't invested in a proper army yet. Unfortunately, he just isn't showing interest. I was hoping with your connections to him, you could get us in touch; and with your combat skills, you could use our smallest ship model, the Shark, to put on a show for him. We already know of a particular pirate in the area with a bounty on his head in command of a Pirate Vendetta. You kill the pirate with a Shark, keep the bounty, and Nexus will pay {credits} on top of that. Would you be interested?"]])

yes_text = _([["Great! I knew I could trust you. If you don't know where to get a Shark, I believe they're sold at Vuere in the Gamma Polaris system. You can use either the civilian model Shark or an Empire Shark, but don't use a Pirate Shark; we don't want the Baron associating us with those pirate knock-offs. Once you obtain a Shark, I'll meet you on {planet} in the {system} system."]])

brief_text = _([[You walk into Baron Sauterfeldt speaking to Arnold Smith with an obnoxious level of snobbiness. "…and I'm telling you, I've never heard of any '{player}', so you'd better not be be pulling–" He interrupts himself as he sees you approaching, and he suddenly begins to show a much more polite demeanor. "Ah, it's you! What was it, {shipname} or something? You must be the acquaintance of this man, then." Not wanting to argue with his failure to get your name right yet again, you decide to ignore it. You explain to the Baron that you're here to show him the capabilities of the Shark vessel.

Arnold smith takes the opening. "Yes, as it happens, there's a highly dangerous pirate in the adjacent {system} system, piloting a rather sizable ship. But you see, {player} here has a secret weapon: the trusty Shark! We're going to capture the whole thing in a holovid so you can see."

Baron Sauterfeldt shrugs. "Fine, then, I'll give you a chance. I'm going to return to my ship. Send the holovid when it's ready. I'll consider your offer after I've seen it." The Baron leaves and Arnold Smith wishes you good luck.]])

pay_text = _([[As you step on the ground, Arnold Smith greets you. "That was a great demonstration! Thank you. I'm sure the Baron will be impressed by your great show of skill!" He hands you your pay. "I'll track you down again if I have another mission for you. Cheers!"]])

-- Mission details
misn_title = _("A Shark Bites")
misn_desc = _("Nexus Shipyards has hired you to demonstrate to Baron Sauterfeldt the capabilities of Nexus ship designs.")

-- NPC
npc_desc = {}
bar_desc = {}
npc_desc[1] = _("An honest-looking man")
bar_desc[1] = _("This man looks like a honest citizen. He seems to be trying to get your attention.")

npc_desc[2] = _("Arnold Smith")
bar_desc[2] = _([[Arnold Smith is talking to a seemingly dismissive Baron Dovai Sauterfeldt. You can't make out what they're saying, but you might hear some of it if you get closer.]])

log_text = _([[You helped Nexus Shipyards demonstrate the capabilities of their ships by destroying a Pirate Vendetta.]])


function create()
   mispla, missys = planet.get("Ulios")
   battlesys = system.get("Toaxis")

   -- Must claim battle system since we disable spawning.
   if not misn.claim(battlesys) then
      misn.finish(false)
   end

   stage = 0
   reward = 200000

   misn.setNPC(npc_desc[1], "neutral/unique/arnoldsmith.png", bar_desc[1])
end


function accept()
   if tk.yesno("", fmt.f(ask_text,
         {player=player.name(), credits=fmt.credits(reward)})) then
      misn.accept()
      piratename = pilotname.pirate()
      tk.msg("", fmt.f(yes_text, {planet=mispla:name(), system=missys:name()}))

      local osd_msg = {
         _("Buy a Shark (but not a Pirate Shark)"),
         fmt.f(_("Land on {planet} ({system} system) with a Shark (but not a Pirate Shark) and speak to Arnold Smith"),
            {planet=mispla:name(), system=missys:name()}),
         fmt.f(_("Go to the {system} system and kill the pirate with your Shark"),
            {system=battlesys:name()}),
         fmt.f(_("Land on {planet} ({system} system)"),
            {planet=mispla:name(), system=missys:name()}),
      }

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(reward))
      misn.setDesc(misn_desc)
      misn.osdCreate(misn_title, osd_msg)
      update_osd()

      jumpouthook = hook.jumpout("jumpout")
      landhook = hook.land("land")
      enterhook = hook.enter("enter")
      hook.ship_buy("update_osd")
      hook.ship_sell("update_osd")
   else
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
   end

   if planet.cur() == mispla and stage == 4 then
      tk.msg("", pay_text)
      player.pay(reward)
      shark_addLog(log_text)
      misn.finish(true)
   end
end


function update_osd()
   if stage == 0 then
      misn.markerRm(markeri)
      local curship = player.pilot():ship()
      local shark = ship.get("Shark")
      local em_shark = ship.get("Empire Shark")
      local have_shark = false

      -- Check to see if the current ship is a Shark.
      if curship == shark or curship == em_shark then
         have_shark = true
      end

      -- Check to see if any of the player's owned ships are Sharks.
      if not have_shark then
         for i, s in ipairs(player.ships()) do
            if s.ship == shark or s.ship == em_shark then
               have_shark = true
               break
            end
         end
      end

      if have_shark then
         misn.osdActive(2)
         markeri = misn.markerAdd(missys, "low", mispla)
      else
         misn.osdActive(1)
      end
   end
end


function jumpout()
   if stage == 2 then
      mh.showFailMsg(_("You left the pirate."))
      misn.finish(false)
   end
end


function enter()
   if system.cur() == battlesys and stage == 1 then
      local playershipname = player.pilot():ship():nameRaw()
      if playershipname ~= "Shark" and playershipname ~= "Empire Shark" then
         mh.showFailMsg(_("You were supposed to use a Shark."))
         misn.finish(false)
      end

      stage = 2

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
   tk.msg("", fmt.f(brief_text,
         {player=player.name(), shipname=player.pilot():name(),
            system=battlesys:name()}))

   misn.markerRm(markeri)
   misn.npcRm(smith)
   misn.osdActive(3)
   stage = 1

   marker1 = misn.markerAdd(battlesys, "low")
end


function pirate_jump()
   pilot.toggleSpawn(true)
   mh.showFailMsg(_("The pirate ran away."))
   misn.finish(false)
end


function pirate_dead()
   pilot.toggleSpawn(true)
   player.pilot():setVisible(false)
   stage = 4
   misn.markerRm(marker1)
   marker2 = misn.markerAdd(missys, "low", mispla)
   misn.osdActive(4)
end
