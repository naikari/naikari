--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Tutorial Part 4">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>1</priority>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Em 5</planet>
  <done>Tutorial Part 3</done>
 </avail>
</mission>
--]]
--[[

   Tutorial Part 4

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

   MISSION: Tutorial Part 4
   DESCRIPTION: Player mines ore from asteroids, then takes it to Em 5.

--]]

local fmt = require "fmt"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"


ask_text = _([["Ah, {player}! I was just thinking about you. I have one last job for you, if you would be willing. This one is simple: I just need a transport. Are you willing to do it?"]])

accept_text = _([["Thank you very much. I'll be at your ship when you're ready for me. I'll show you where we need to go once we're in space."]])

starmap_text = _([["Alright, {player}, let me show you where we need to go. Could you open your starmap by pressing {starmapkey}, please?"]])

jump_text = _([["Thank you. As you can see, I've marked the {system} system on your starmap. That's the system we need to go to. Luckily, it seems you already know the jump point to get there, so if you just select {system} with the mouse and click the Autonav button, we should be there in no time!"]])

target_nearest_text = _([[As you enter {system}, you see an icon indicating another ship on your radar. However, something seems off. Sirens blare as you realize that the ship is hostile!

Seeing this, Albert's face goes pale. "N-no way! This is supposed to be the safe part of Empire space! Quick, {player}! Press {target_hostile_key} so you can aim your weapons at whatever that ship is!"]])

fight_text = _([[You engage the control indicated by Albert and see that it automatically sets your designated target to the nearest hostile ship, which is the one you noticed on your radar. With the ship targeted, you can see what it is now: a Pirate Hyena. The sight makes Albert hyperventilate despite your best efforts to calm him down.

Finally, Albert speaks again. "P-please, whatever you do, don't let that pirate kill us! Shoot them down or something!"]])

dest_text = _([[With the pirate now defeated, you see Albert visibly relax, though he continues to sweat nervously. "Th-thank you," he stutters.

"OK. I'm OK. Um, we need to get to {planet}. I don't know where it is exactly, but if you have enough talent to take out a p-pirate all by yourself, I'm sure you can manage. I know it's somewhere in this system, so you could either look around the system yourself or buy a map. You can use either…" Albert passes out from exhaustion before he can finish his sentence, and you decide to let him rest while you search for his destination.]])

pay_text = _([[As you finish the landing procedures and arrive on the surface of {planet}, you gently wake Albert. He flinches in surprise, but when he sees it's just you, he immediately relaxes. You tell him that you've arrived at his destination and in hearing this, he breathes a sigh of relief and follows you out of your ship. Once both of you enter the spaceport, he exhales and hands you a credit chip.

"Thank you," Albert says. "You've outperformed my expectations, saving me from certain death like that. I can't possibly thank you enough. As a token of my appreciation, I'm giving you double the fee I originally agreed to pay you." You take your payment and thank him for his kind words.

"Good luck on your travels, {player}, and I hope to meet you again some day!" Albert offers his hand, which you shake before he walks off.]])

misn_desc = _("Albert needs you to give him transport to another planet.")
misn_log = _([[You helped transport Albert to another planet in another system, fighting off an unexpected pirate along the way. Albert thanked you for your service and said he hopes to meet you again in the future.]])


function create()
   misplanet, missys = planet.get("Shiarta")
   credits = 20000

   if not misn.claim(missys) then
      misn.finish(false)
   end

   misn.setNPC(_("Albert"),
         "neutral/unique/youngbusinessman.png",
         _("You see Albert waiting for you at the bar again."))
end


function accept()
   if tk.yesno("", fmt.f(ask_text, {player=player.name()})) then
      tk.msg("", fmt.f(accept_text, {player=player.name()}))

      misn.accept()

      misn.setTitle(_("Albert's Transport"))
      misn.setReward(fmt.credits(credits))
      misn.setDesc(misn_desc)

      local osd_desc = {
         _("Fly into space"),
         fmt.f(_("Press {starmapkey} to open your starmap"),
            {starmapkey=naev.keyGet("starmap")}),
         fmt.f(_("Select {system} by clicking on it in your starmap, then click \"Autonav\" and wait for Autonav to fly you there"),
            {system=missys:name()}),
         fmt.f(_("Press {target_hostile_key} to target the hostile ship"),
            {target_hostile_key=naev.keyGet("target_hostile")}),
         _("Destroy the Pirate Hyena"),
         fmt.f(_("Land on {planet} ({system} system)"),
            {planet=misplanet:name(), system=missys:name()}),
      }
      misn.osdCreate(_("Albert's Transport"), osd_desc)

      enter_hook = hook.enter("enter_start")
   else
      misn.finish()
   end
end


function enter_start()
   hook.rm(enter_hook)
   hook.timer(1, "timer_enter_start")
   enter_hook = hook.enter("enter_ambush")
end


function timer_enter_start()
   tk.msg("", fmt.f(starmap_text,
            {player=player.name(), starmapkey=tutGetKey("starmap")}))

   misn.osdActive(2)

   input_hook = hook.input("input", "starmap")
end


function input(inputname, inputpress, arg)
   if not inputpress then
      return
   end

   if inputname ~= arg then
      return
   end

   misn.markerAdd(missys)

   safe_hook = hook.safe(string.format("safe_%s", arg))
   hook.rm(input_hook)
end


function safe_starmap()
   tk.msg("", fmt.f(jump_text, {system=missys}))
   misn.osdActive(3)
end


function enter_ambush()
   if system.cur() ~= missys then
      return
   end

   hook.rm(input_hook)
   hook.rm(safe_hook)
   hook.rm(enter_hook)

   player.allowLand(false)
   player.pilot():setNoJump(true)
   player.pilot():setVisible()
   pilot.toggleSpawn(false)
   pilot.clear()

   local pos = jump.get("Eneguoz", "Hakoi"):pos() + vec2.new(1000, 1500)
   local pirate = pilot.add("Hyena", "Pirate", pos, _("Pirate Hyena"),
         {ai="pirate_norun", naked=true})

   pirate:outfitAdd("Previous Generation Small Systems")
   pirate:outfitAdd("Beat Up Small Engine")
   pirate:outfitAdd("Patchwork Light Plating")
   pirate:outfitAdd("Jump Scanner") -- Lowers energy regeneration
   pirate:outfitAdd("Laser Cannon MK1")

   pirate:setHealth(100, 100)
   pirate:setEnergy(100)
   pirate:setVisible()
   pirate:setHostile()

   hook.pilot(pirate, "death", "pirate_death")
   hook.pilot(pirate, "jump", "pirate_death")
   hook.pilot(pirate, "land", "pirate_land")

   hook.timer(2, "timer_enter_ambush", pirate)
   input_hook = hook.input("input", "target_hostile")
end


function timer_enter_ambush(pirate)
   tk.msg("", fmt.f(target_nearest_text,
         {system=missys:name(), player=player.name(),
            target_hostile_key=tutGetKey("target_hostile")}))
   misn.osdActive(4)
end


function safe_target_hostile()
   tk.msg("", fight_text)
   misn.osdActive(5)
end


function pirate_death(p)
   hook.rm(input_hook)
   hook.rm(safe_hook)
   if p:exists() then
      p:hookClear()
   end

   hook.timer(3, "timer_pirate_death")
end


function timer_pirate_death()
   tk.msg("", fmt.f(dest_text, {planet=misplanet:name()}))
   misn.osdActive(6)

   player.allowLand(true)
   player.pilot():setNoJump(false)
   player.pilot():setVisible(false)
   pilot.toggleSpawn(true)

   hook.land("land")
end


function land()
   if planet.cur() ~= misplanet then
      return
   end

   tk.msg("", fmt.f(pay_text, {planet=misplanet:name(), player=player.name()}))

   player.pay(2 * credits)

   addMiscLog(misn_log)
   misn.finish(true)
end


function abort()
   if system.cur() == missys then
      player.allowLand(true)
      player.pilot():setNoJump(false)
      player.pilot():setVisible(false)
      pilot.toggleSpawn(true)
   end
   misn.finish(false)
end
