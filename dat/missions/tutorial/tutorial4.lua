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
  <planet>Octawius</planet>
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
local fleet = require "fleet"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"


local ask_text = _([["I have one last mission for you, {player}, if you would be willing. This one is simple: I just need you to ferry me to a neighboring system, and I'll pay you {credits} for it. Are you willing to do it?"]])

local accept_text = _([["Thank you very much. I'll be at your ship when you're ready for me. I'll show you where we need to go once we're in space."]])

local starmap_text = _([["Alright, {player}, let me show you where we need to go. Could you open your starmap by pressing {starmapkey}, please?"]])

local jump_text = _([["As you can see, I've marked the {system} system on your starmap. That's the system we need to go to. Luckily, it seems you already know the jump point to get there, so if you just select {system} with the mouse and click the Autonav button, we should be there in no time!"]])

local target_nearest_text = _([[As you enter {system}, you see an icon indicating another ship on your radar. However, something seems off. Sirens blare as you realize that the ship is hostile!

Seeing this, Ian's face goes pale. "N-no way! This is supposed to be the safe part of Empire space! Quick, {player}! Press {target_hostile_key} so you can aim your weapons at whatever that ship is!"]])

local fight_text = _([[You see that the control you engaged automatically sets your designated target to the nearest hostile ship, which is the one you noticed on your radar. You can see what it is now: a Pirate Hyena. The sight makes Ian hyperventilate despite your best efforts to calm him down.

"P-please," Ian urges, "whatever you do, don't let that pirate kill us! Shoot them down or something!" As Ian continues to panic, you grab your ship's combat controls, telling yourself against your own instincts that this will be just like the asteroid mining you did previously.]])

local dest_text = _([[With the pirate now defeated, you see Ian visibly relax. "Th-thank you," he stutters. "Now we just need to land on {planet} and… oh, shit! Shit, shit, shit!" You look at your radar and see the source of Ian's newfound panic: a large fleet of pirates. "There's too many of them! Oh, I knew I should've never come out here! We're gonna die! I don't wanna die!"]])

local pay_text = _([[As you finish the landing procedures and arrive on the surface of {planet}, you notice an Imperial Lieutenant waiting for you. Unsure what to think, you step outside of your ship and begin to salute him, as is the custom, but are interrupted by the sound of Ian's voice behind you. "Milo! Oh, Milo, I'm so happy to s-see you."

With tears in his eyes, Ian rushes to Lieutenant Milo, who opens his arms and firmly embraces him. "It's OK, love," he gently whispers. "I'm here. You're safe."

After a few minutes, Ian calms down and hands you a credit chip. "Thank you, {player}," he says.

"And thank you from me as well," Milo adds, handing you a second credit chip. "Thank you for keeping my boyfriend safe. As a token of my gratitude, I'd be willing to personally offer you a chance to climb the ranks of the Empire. Meet me at the bar if you're interested." He grabs Ian's hand, gives him a kiss, and walks off with him.]])

local misn_desc = _("Ian Structure has hired you to give him transport to another planet.")
local misn_log = _([[You helped transport Ian Structure to {planet} ({system}), fighting off an unexpected pirate along the way. He and his boyfriend, Milo, thanked you for keeping him safe. Milo also offered a chance to climb the ranks of the Empire; he said to meet him at the bar on {planet} ({system}) if you're interested.]])


function create()
   misplanet, missys = planet.get("Liwia")
   credits = 5000

   -- Must claim the system to disable spawning (and make sure no Empire
   -- ships come to the player's rescue).
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
            {starmapkey=naik.keyGet("starmap")}),
         fmt.f(_("Select {system} by clicking on it in your starmap, then click \"Autonav\" and wait for Autonav to fly you there"),
            {system=missys:name()}),
         fmt.f(_("Press {target_hostile_key} to target the hostile ship"),
            {target_hostile_key=naik.keyGet("target_hostile")}),
         _("Destroy the Pirate Hyena"),
         fmt.f(_("Land on {planet} ({system})"),
            {planet=misplanet:name(), system=missys:name()}),
      }
      misn.osdCreate(_("Ian's Transport"), osd_desc)

      marker = misn.markerAdd(missys, "plot", misplanet)

      enter_hook = hook.enter("enter_start")
   else
      misn.finish()
   end
end


function enter_start()
   hook.rm(enter_hook)

   misn.osdActive(2)

   input_timer_hook = hook.timer(1, "timer_enter_start")
   input_hook = hook.input("input", "starmap")
   enter_hook = hook.enter("enter_ambush")
end


function timer_enter_start()
   tk.msg("", fmt.f(starmap_text,
            {player=player.name(), starmapkey=tutGetKey("starmap")}))
end


function input(inputname, inputpress, arg)
   if not inputpress then
      return
   end

   if inputname ~= arg then
      return
   end

   safe_hook = hook.safe(string.format("safe_%s", arg))
   hook.rm(input_timer_hook)
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

   local pos = jump.get("Beta Pyxidis", "Alpha Pyxidis"):pos() + vec2.new(2000, 0)
   local pirate = pilot.add("Hyena", "Pirate", pos, _("Pirate Hyena"),
         {ai="pirate_norun", naked=true})

   pirate:outfitAdd("Makeshift Small APU")
   pirate:outfitAdd("Beat Up Small Engine")
   pirate:outfitAdd("Patchwork Light Hull")
   pirate:outfitAdd("Jump Scanner") -- Lowers energy regeneration
   pirate:outfitAdd("FL21-U Lumina Gun")

   pirate:setHealth(100, 100)
   pirate:setEnergy(100)
   pirate:setVisible()
   pirate:setHostile()

   pirate:memory().kill_reward = 5000

   misn.osdActive(4)

   hook.pilot(pirate, "death", "pirate_death")
   hook.pilot(pirate, "jump", "pirate_death")
   hook.pilot(pirate, "land", "pirate_land")

   timer_hook = hook.timer(2, "timer_enter_ambush", pirate)
   input_hook = hook.input("input", "target_hostile")
end


function timer_enter_ambush(pirate)
   tk.msg("", fmt.f(target_nearest_text,
         {system=missys:name(), player=player.name(),
            target_hostile_key=tutGetKey("target_hostile")}))
end


function safe_target_hostile()
   hook.rm(timer_hook)

   tk.msg("", fight_text)
   misn.osdActive(5)

   -- Ensure the player has weapons.
   local p = player.pilot()
   local n = #p:outfits("weapon")
   if n < 2 then
      p:outfitAdd("FL21-U Lumina Gun", 2 - n)
   end

   -- If this happens, that likely means not enough CPU is available for
   -- weapons, so we'll override the CPU limitation and just let them
   -- have a weapon they shouldn't.
   if #p:outfits("weapon") <= 0 then
      p:outfitAdd("FL21-U Lumina Gun", 1, true, true)
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

   -- Spawn the pirates as mercenaries to given them lethal weapons,
   -- then change faction to pirate.
   local pirates = fleet.add(1,
         {"Pirate Kestrel", "Pirate Admonisher", "Pirate Phalanx",
            "Pirate Ancestor", "Pirate Ancestor", "Pirate Vendetta",
            "Pirate Vendetta", "Pirate Shark", "Pirate Shark", "Pirate Shark",
            "Pirate Shark"},
         "Mercenary", system.get("Alpha Pyxidis"), nil, nil, true)
   for i = 1, #pirates do
      pirates[i]:setFaction("Pirate")
   end

   police_hook = hook.timer(5, "timer_police", pirates)
   hook.jumpout("delete_policehook_timer")
   hook.land("land")
end


function timer_police(pirates)
   local police = fleet.add(1,
         {"Imperial Pacifier", "Imperial Lancelot", "Imperial Shark"},
         "Empire", system.get("Alpha Pyxidis"), nil, nil, true)

   local msg = fmt.f(_("All citizens, evacuate this area immediately! Press {local_jump_key} to initiate an Escape Jump!"),
         {local_jump_key=tutGetKey("local_jump")})
   police[1]:broadcast(msg, true)

   police_broadcast_hook = hook.timer(5, "timer_rebroadcast", police[1])
end


function timer_rebroadcast(p)
   if p == nil or not p:exists() then
      return
   end

   local msg = fmt.f(_("I repeat: all citizens, initiate an Escape Jump by pressing {local_jump_key} and evacuate immediately!"),
         {local_jump_key=tutGetKey("local_jump")})
   p:broadcast(msg, true)
end


function delete_policehook_timer()
   hook.rm(police_hook)
   hook.rm(police_broadcast_hook)
end


function land()
   delete_policehook_timer()

   if planet.cur() ~= misplanet then
      return
   end

   tk.msg("", fmt.f(pay_text, {planet=misplanet:name(), player=player.name()}))

   player.pay(2 * credits)
   diff.apply("hakoi_pirates")

   local exp = time.get() + time.create(0, 250, 0)
   news.add("Empire", _("Pirates in Pyxidis"),
         _([[Residents of the previously peaceful Pyxidis constellation are shocked to discover that pirates have begun showing up in the region out of nowhere. Imperial authorities have successfully stopped these pirates from spreading further into the Empire and note that the level of pirate presence is small, but nonetheless warn those traveling in the area to be cautious. An investigation is underway.]]),
         exp)

   addMiscLog(fmt.f(misn_log, {planet=misplanet:name(), system=missys:name()}))
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
