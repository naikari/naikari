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
 <notes>
  <campaign>Tutorial</campaign>
 </notes>
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
   DESCRIPTION:
      Player transports Ian Structure to another system, then gets
      unexpectedly attacked by a lone pirate.

--]]

local fmt = require "fmt"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"


ask_text = _([["Ah, {player}! I was just thinking about you. I have one last job for you, if you would be willing. This one is simple: I just need you to ferry me to a neighboring system, and I'll pay you {credits} for it. Are you willing to do it?"]])

accept_text = _([["Thank you very much. I'll be at your ship when you're ready for me. I'll show you where we need to go once we're in space."]])

starmap_text = _([["Alright, {player}, let me show you where we need to go. Could you open your starmap by pressing {starmapkey}, please?"]])

jump_text = _([["Thank you. As you can see, I've marked the {system} system on your starmap. That's the system we need to go to. Luckily, it seems you already know the jump point to get there, so if you just select {system} with the mouse and click the Autonav button, we should be there in no time!"]])

target_nearest_text = _([[As you enter {system}, you see an icon indicating another ship on your radar. However, something seems off. Sirens blare as you realize that the ship is hostile!

Seeïng this, Ian's face goes pale. "N-no way! This is supposed to be the safe part of Empire space! Quick, {player}! Press {target_hostile_key} so you can aim your weapons at whatever that ship is!"]])

fight_text = _([[You see that the control you engaged automatically sets your designated target to the nearest hostile ship, which is the one you noticed on your radar. With the ship targeted, your weapons swerve as much as they can to point to it. You can also see what it is now: a Pirate Hyena. The sight makes Ian hyperventilate despite your best efforts to calm him down.

"P-please," Ian urges, "whatever you do, don't let that pirate kill us! Shoot them down or something!" As Ian continues to panic, you grab your ship's combat controls, telling yourself against your own instincts that this will be just like the asteroid mining you did previously.]])

dest_text = _([[With the pirate now defeated, you see Ian visibly relax, though he continues to sweat nervously. "Th-thank you," he stutters. You yourself breathe a sigh of relief before noticing, to your surprise, a message on your console informing you that the Empire has awarded you a bounty for killing the pirate.

"OK. I'm OK. Um, we need to get to {planet}. I don't know where it is exactly, but if you have enough talent to take out a p-pirate all by yourself, I'm sure you can manage. I know it's somewhere in this system, so you could either look around the system yourself or buy a map. Either method should…" Ian passes out in his chair from exhaustion before he can finish his sentence. You consider waking him, but quickly decide to let him rest while you search for his destination.]])

pay_text = _([[As you finish the landing procedures and arrive on the surface of {planet}, you gently wake Ian Structure. He flinches in surprise, but when he sees it's just you, he immediately relaxes. You tell him that you've arrived at his destination and upon hearing this, he breathes a sigh of relief and follows you out of your ship.

"Thank you," Ian says as both of you enter the spaceport. "You've outperformed my expectations, saving me from certain death like that. I can't possibly thank you enough. As a token of my appreciation, I'm giving you double the fee I originally agreed to pay you." You take your payment and thank him for his kind words.

"Good luck on your travels, {player}, and I hope to meet you again someday!" Ian offers his hand, which you shake before he walks off.]])

misn_desc = _("Ian Structure has hired you to give him transport to another planet.")
misn_log = _([[You helped transport Ian Structure to another planet in another system, fighting off an unexpected pirate along the way. He thanked you for keeping him safe and said he hopes to meet you again in the future.]])


function create()
   misplanet, missys = planet.get("Shiarta")
   credits = 15000

   if not misn.claim(missys) then
      misn.finish(false)
   end

   misn.setNPC(_("Ian Structure"),
         "neutral/unique/youngbusinessman.png",
         _("You see Ian Structure waiting for you at the bar again."))
end


function accept()
   if tk.yesno("", fmt.f(ask_text,
         {player=player.name(), credits=fmt.credits(credits)})) then
      tk.msg("", fmt.f(accept_text, {player=player.name()}))

      misn.accept()

      misn.setTitle(_("Ian's Transport"))
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
      misn.osdCreate(_("Ian's Transport"), osd_desc)

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

   misn.markerAdd(missys, "plot")

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

   pirate:memory().kill_reward = 20000

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

   -- Ensure the player has weapons.
   local p = player.pilot()
   local n = #p:outfits("weapon")
   if n < 2 then
      p:outfitAdd("Laser Cannon MK1", 2 - n)
   end

   -- If this happens, that likely means not enough CPU is available for
   -- weapons, so we'll override the CPU limitation and just let them
   -- have a weapon they shouldn't.
   if #p:outfits("weapon") <= 0 then
      p:outfitAdd("Laser Cannon MK1", 1, true, true)
   end
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
   diff.apply("hakoi_pirates")

   local exp = time.get() + time.create(0, 250, 0)
   news.add("Empire", _("Pirates in Hakoi"),
         _([[Residents of the previously peaceful Hakoi system are shocked to discover that pirates have begun showing up in the region out of nowhere. Imperial authorities have successfully stopped these pirates from spreading further into the Empire and note that the level of pirate presence is small, but nonetheless warn those traveling to and from the areä to be cautious. An investigation is underway.]]),
         exp)

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
