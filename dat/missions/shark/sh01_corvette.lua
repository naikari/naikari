--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Sharkman Is Back">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <done>A Shark Bites</done>
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
  <campaign>Nexus</campaign>
 </notes>
</mission>
--]]
--[[

   This is the second mission of the Shark's teeth campaign. The player has to take part to a fake battle.

   Stages :
   0) Way to Toaxis
   1) Battle
   2) Going to Darkshed

--]]

local fmt = require "fmt"
require "missions/shark/common"


ask_text = _([["I have another job for you. The Baron was unfortunately not as impressed as we hoped. So we need a better demonstration, and we think we know what to do: we're going to demonstrate that the Lancelot, our higher-end Fighter design, is more than capable of defeating Destroyer class ships.

"Now, one small problem we face is that pirates almost never use Destroyer class ships; they tend to stick to Fighters, Corvettes, and Cruisers. More importantly, actually sending a fighter after a Destroyer is exceedingly dangerous, even if we could find a pirate piloting one. So we have another plan: we want someone to pilot a destroyer class ship and just let another pilot disable them with ion cannons.

"What do you say? Are you interested?"]])

accept_text = _([["Great! Go and meet our pilot in the {destsys} system. After the job is done, meet me at {payplanet} in the {paysys} system."]])

pay_text = _([[As you land, you see Arnold Smith waiting for you. He explains that the Baron was so impressed by the battle that he signed an updated contract with Nexus Shipyards, solidifying Nexus as the primary supplier of ships for his fleet. As a reward, they give you twice the sum of credits they promised to you.]])

-- Mission details
misn_title = _("Nexus False Flag")
misn_desc = _("Nexus Shipyards wants you to fake a loss against a Lancelot while piloting a Destroyer class ship.")

-- NPC
npc_desc = _("Arnold Smith")
bar_desc = _([[The Nexus employee seems to be looking for pilots. Maybe he has an other task for you.]])

-- OSD
osd_msg = {}
osd_msg[1] = _("Fly to {system} with a Destroyer-class ship and let the Lancelot disable you")
osd_msg[2] = _("Land on {planet} ({system} system) to collect your pay")

msg_run = _("MISSION FAILED: You ran away.")
msg_destroyed = _("MISSION FAILED: You destroyed the Lancelot.")

log_text = _([[You helped Nexus Shipyards fake a demonstration by allowing a Lancelot to disable your Destroyer-class ship.]])


function create ()
   battlesys = system.get("Toaxis")
   paypla, paysys = planet.get("Darkshed")
   escapesys = system.get("Ingot")

   if not misn.claim(battlesys) then
      misn.finish(false)
   end

   misn.setNPC(npc_desc, "neutral/unique/arnoldsmith.png", bar_desc)
end

function accept()

   stage = 0
   reward = 300000

   if tk.yesno("", ask_text:format(battlesys:name(), fmt.credits(reward/2))) then
      misn.accept()
      tk.msg("", fmt.f(accept_text,
            {destsys=battlesys:name(), payplanet=paypla:name(),
               paysys=paysys:name()}))

      osd_msg[1] = fmt.f(osd_msg[1], {system=battlesys:name()})
      osd_msg[2] = fmt.f(osd_msg[2],
            {planet=paypla:name(), system=paysys:name()})

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(reward/2))
      misn.setDesc(misn_desc)
      osd = misn.osdCreate(misn_title, osd_msg)
      misn.osdActive(1)

      marker = misn.markerAdd(battlesys, "low")

      jumpouthook = hook.jumpout("jumpout")
      landhook = hook.land("land")
      enterhook = hook.enter("enter")
   else
      misn.finish()
   end
end

function jumpout()
   if stage == 0 then
      local vname = string.format("_escort_disable_%s", battlesys:nameRaw())
      if player.pilot():ship():class() == "Destroyer" then
         var.push(vname, true)
      else
         var.pop(vname)
      end
   elseif stage == 1 then --player trying to escape
      player.msg("#r" .. msg_run .. "#0")
      misn.finish(false)
   end
end

function land()
   if stage == 1 then --player trying to escape
      player.msg("#r" .. msg_run .. "#0")
      misn.finish(false)
   end
   if stage == 2 and planet.cur() == paypla then
      tk.msg("", pay_text)
      player.pay(reward)
      misn.osdDestroy(osd)
      hook.rm(enterhook)
      hook.rm(landhook)
      hook.rm(jumpouthook)
      shark_addLog(log_text)
      misn.finish(true)
   end
end

function enter()

   local playerclass = player.pilot():ship():class()
   --Jumping in Toaxis for the battle with a destroyer class ship
   if system.cur() == battlesys and stage == 0 and playerclass == "Destroyer" then
      pilot.clear()
      pilot.toggleSpawn(false)
      pilot.setVisible(player.pilot())

      hook.timer(2.0,"lets_go")
   end
end

function lets_go()
   -- spawns the Shark
   sharkboy = pilot.add("Lancelot", "Mercenary", system.get("Raelid"), nil, {ai="baddie_norun"})
   sharkboy:setHostile()
   sharkboy:setHilight()

   --The shark becomes nice outfits
   sharkboy:outfitRm("all")
   sharkboy:outfitRm("cores")

   sharkboy:outfitAdd("S&K Light Stealth Plating")
   sharkboy:outfitAdd("Milspec Aegis 3601 Core System")
   sharkboy:outfitAdd("Tricon Zephyr II Engine")

   sharkboy:outfitAdd("Reactor Class I", 2)
   sharkboy:outfitAdd("Small Shield Booster")
   sharkboy:outfitAdd("Engine Reroute", 2)

   sharkboy:outfitAdd("TeraCom Medusa Launcher")
   sharkboy:outfitAdd("Ion Cannon", 3)

   sharkboy:setHealth(100,100)
   sharkboy:setEnergy(100)
   sharkboy:setFuel(true)
   stage = 1

   shark_dead_hook = hook.pilot(sharkboy, "death", "shark_dead")
   disabled_hook = hook.pilot(player.pilot(), "disable", "disabled")
end

function shark_dead()  --you killed the shark
   player.msg("#r" .. msg_destroyed .. "#0")
   misn.finish(false)
end

function disabled(pilot, attacker)
   if attacker == sharkboy then
      stage = 2
      misn.osdActive(2)
      misn.markerRm(marker)
      marker2 = misn.markerAdd(paysys, "low", paypla)
      pilot.toggleSpawn(true)
   end
   sharkboy:control()
   --making sure the shark doesn't continue attacking the player
   sharkboy:hyperspace(escapesys)
   sharkboy:setNoDeath()
   sharkboy:setNoDisable()

   -- Clean up now unneeded hooks
   hook.rm(shark_dead_hook)
   hook.rm(disabled_hook)
end
