--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Tutorial Part 3">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>1</priority>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Kikero</planet>
  <done>Tutorial Part 2</done>
 </avail>
 <notes>
  <campaign>Tutorial</campaign>
 </notes>
</mission>
--]]
--[[

   Tutorial Part 3

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

   MISSION: Tutorial Part 3
   DESCRIPTION: Player mines Gold from asteroids, then takes it to Octawius.

--]]

local fmt = require "fmt"
require "proximity"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"


local ask_text = _([["Hello again, {player}! Are you ready for that other mission I had for you? It's a little more effort than the last mission, but still not too hard, and I'll pay you a nice {credits} reward for it."]])

local accept_text = _([["I appreciate it! Now, for this mission, you'll need {needed} kt of cargo capacity. Let's see, how much cargo capacity does your ship have?" Ian does some checks on his palmtop.]])

local space_needed_text = _([["It looks like you've got {available} kt of cargo capacity available right now. That falls a bit short, but no worries! You should be able to make up the difference by purchasing a #bCargo Pod#0 at the #bOutfit Shop#0, and then equipping it to your ship at the #bHangar#0. Oh, make sure you also sell off any cargo you might be carrying at the Commodity Exchange. I'll wait here while you get that taken care of."]])

local weapons_needed_text = _([["It looks like you've got plenty of cargo capacity! But wait, where are your weapons? I'm sorry, I forgot to mention that you do need weapons for this mission, as well. Would you re-equip your weapons at the #bHangar#0? The weapons your ship came with should be fine. If you sold them, you can buy them again them at the #bOutfit Shop#0. Come back to me here when you're done."]])

local enough_space_text = _([["It looks like you're ready! For this mission, we'll be going into space; I will be joining you on your ship. When you're ready, press the #bTake Off button#0. Make sure you still have weapons and enough cargo capacity when you do so!"]])

local overlay_text = _([["It's been awhile since I've been in space," Ian notes somewhat nervously. "Alright, the reason we're here is I need you to mine some Gold for me. Of course, I could buy it from the Commodity Exchange, but there happens to be a safe pure Gold asteroid field in this system, and that will be much cheaper than buying it.

"I've marked the asteroid field on your ship's overlay map. Could you press {overlaykey} to open your overlay map so I can show you, please?"]])

local autonav_text = _([["Thank you! If you look here, you'll see I've marked an area with the label, 'Asteroid Field'. I need you to use Autonav to take us to that area as fast as possible. I mean, of course, the trip will take the same duration in real-time, but giving the work to Autonav will allow you to leave the captain's chair and do other things; it makes the time passage feel almost instantaneous. Most pilots call this phenomenon 'Time Compression', I believe, or 'TC' for short." Just #bright-click#0 on the location of the asteroid field to initialize Autonav."]])

local mining_text = _([[Alright, let's start mining! Of course, mining is done with the same weaponry you would use to defend yourself against pirates should you be attacked. All you have to do is click on a suitable asteroid to target it, then use {primarykey} and {secondarykey} to fire your weapons and destroy the targeted asteroid. Once it's destroyed, it will normally drop some commodity, Gold in this case, and you can pick the commodity up simply by flying over its location.

"I just need you to mine {needed} kt of Gold. I'll let you know what to do with it when you've mined it."]])

local cooldown_text = _([[Ian Structure briefly startles you as he taps on your shoulder. "Sorry! I just noticed that your weapons are getting pretty hot. That's not doing your weapon accuracy any favors. Why don't you cool everything down by pressing {autobrake_key}?"]])

local dest_text = _([["That should do it! Good job! With those firing skills, maybe you'd even be able to handle yourself against a pirate! I sure hope you don't have to, thô. Oh, what am I saying? There's no way the Empire would let pirates get into a place like this!" Ian sweats nervously, as if not entirely convinced.

"Alright, I need you to take this Gold to {planet}. You should be able to see it on your overlay map, right? You can interact with its icon the same way you would interact with the planet itself, so you should be able to tell Autonav to land us there no problem."]])

local pay_text = _([[Ian steps out of your ship and stretches his arms, seemingly happy to be back in atmosphere. "Thank you for your service once again," he says as he hands you a credit chip with your payment. "You should sell any extra Gold you have at the Commodity Exchange; you can make a nice bit of credits that way. And if you like, I have one more mission for you. Meet me at the bar whenever you're ready and I'll tell you more."]])

local misn_desc = _("Ian Structure has hired you to mine Gold from some asteroids.")
local misn_log = _([[You accepted another mission from Ian Structure, this time mining some Gold from asteroids for him. He asked you to speak with him again on {planet} ({system}) for another mission.]])

local credits = 5000


function create()
   misplanet, missys = planet.get("Octawius")
   startplanet, startsys = planet.cur()

   misn.setNPC(_("Ian Structure"),
         "neutral/unique/youngbusinessman.png",
         _("Ian is at the bar. He said he has another mission for you."))
end


function accept()
   if tk.yesno("", fmt.f(ask_text,
         {player=player.name(), credits=fmt.credits(credits)})) then
      misn.accept()

      misn.setTitle(_("Ian's Supplies"))
      misn.setReward(fmt.credits(credits))
      misn.setDesc(misn_desc)

      started = false
      finished = false

      -- Calculate the player's total cargo capacity, including any
      -- that's in use.
      local capacity = player.pilot():cargoFree()
      local cargo_list = player.pilot():cargoList()
      for i = 1, #cargo_list do
         capacity = capacity + cargo_list[i].q
      end

      -- See if the player already has a Cargo Pod equipped. If so,
      -- that implies that the player has already figured out how to
      -- modify ship outfits. In that case, use a lower default cargo
      -- requirement, in case the player did something silly like sell
      -- all their weapons for cargo space.
      local has_pod = false
      local equipped_outfits = player.pilot():outfits("structure")
      for i = 1, #equipped_outfits do
         local o = equipped_outfits[i]
         if o == outfit.get("Cargo Pod")
               or o == outfit.get("Medium Cargo Pod")
               or o == outfit.get("Large Cargo Pod") then
            has_pod = true
            break
         end
      end
      if has_pod then
         -- Choose 27 kt (the default cargo capacity of a Llama plus 5),
         -- or the current full cargo capacity, whichever is lower.
         cargo_needed = math.min(27, capacity)
      else
         -- Choose the current full cargo capacity plus a bit more.
         cargo_needed = capacity + 5
      end

      tk.msg("", fmt.f(accept_text,
            {player=player.name(), needed=cargo_needed}))
      approach()
      land()

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system}), equip your ship with a weapon and {needed} kt of cargo capacity, and talk to Ian Structure at the bar"),
            {planet=startplanet, system=startsys, needed=cargo_needed}),
         fmt.f(_("Press {overlaykey} to open your overlay map"),
            {overlaykey=naik.keyGet("overlay")}),
         _("Fly to Asteroid Field indicated on overlay map by right-clicking the area"),
         _("Mine Gold from asteroids until your cargo hold is full"),
         "\t" .. _("Target an asteroid by left-clicking on it"),
         "\t" .. fmt.f(_("Use {primarykey} and {secondarykey} to fire your weapons and destroy the targeted asteroid"),
            {primarykey=naik.keyGet("primary"),
               secondarykey=naik.keyGet("secondary")}),
         "\t" .. _("Fly to the location of dropped Gold to collect it"),
         "\t" .. fmt.f(_("If your weapons overheat, engage Active Cooldown by pressing {autobrake_key}"),
            {autobrake_key=naik.keyGet("autobrake")}),
         fmt.f(_("Land on {planet} ({system})"),
            {planet=misplanet, system=missys}),
      }
      misn.osdCreate(_("Ian's Supplies"), osd_desc)

      marker = misn.markerAdd(missys, "low")

      hook.enter("enter")
      hook.land("land")
      hook.load("land")
   else
      misn.finish()
   end
end


function approach()
   local cargo_free = player.pilot():cargoFree()
   if cargo_free < cargo_needed then
      tk.msg("", fmt.f(space_needed_text, {available=cargo_free}))
      return
   end

   local weapons_equipped = #player.pilot():outfits("weapon")
   if weapons_equipped < 1 then
      tk.msg("", weapons_needed_text)
      return
   end

   tk.msg("", enough_space_text)
end


function enter()
   if started or finished then
      return
   end

   if system.cur() ~= missys then
      return
   end

   local weapons_equipped = #player.pilot():outfits("weapon")
   if weapons_equipped < 1 then
      return
   end

   started = true
   player.allowLand(false)
   player.pilot():setNoJump(true)

   hook.rm(timer_hook)
   timer_hook = hook.timer(2, "timer_enter")
end


function timer_enter()
   tk.msg("", fmt.f(overlay_text,
            {player=player.name(), overlaykey=tutGetKey("overlay")}))

   misn.osdActive(2)

   local pos = vec2.new(0, 0)
   mark = system.mrkAdd(_("Asteroid Field"), pos)

   input_hook = hook.input("input", "overlay")
   hook.timer(0.5, "proximity",
         {location=pos, radius=2500, funcname="asteroid_proximity"})
end


function input(inputname, inputpress, arg)
   if not inputpress then
      return
   end

   if inputname ~= arg then
      return
   end

   hook.safe(string.format("safe_%s", arg))
   hook.rm(input_hook)
end


function safe_overlay()
   tk.msg("", autonav_text)
   misn.osdActive(3)
end


function asteroid_proximity()
   hook.rm(input_hook)
   system.mrkRm(mark)

   tk.msg("", fmt.f(mining_text,
         {primarykey=tutGetKey("primary"),
            secondarykey=tutGetKey("secondary"),
            needed=cargo_needed}))
   misn.osdActive(4)

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

   hook.timer(0.5, "timer_mining")
   overheat_timer_hook = hook.timer(0.5, "timer_overheat")
end


function timer_mining()
   if player.pilot():cargoHas("Gold") < cargo_needed then
      hook.timer(0.5, "timer_mining")
      return
   end

   hook.rm(input_hook)
   system.mrkRm(mark)
   hook.rm(overheat_timer_hook)

   finished = true
   player.allowLand(true)
   player.pilot():setNoJump(false)

   tk.msg("", fmt.f(dest_text, {planet=misplanet:name()}))
   misn.osdActive(9)

   misn.markerMove(marker, missys, misplanet)
end


function timer_overheat()
   local p = player.pilot()
   local overheating = false
   for i = 1, 10 do
      local hmean, hpeak = p:weapsetHeat(i)
      if hpeak >= 0.5 then
         overheating = true
         break
      end
   end
   if not overheating then
      overheat_timer_hook = hook.timer(0.5, "timer_overheat")
      return
   end

   tk.msg("", fmt.f(cooldown_text, {autobrake_key=tutGetKey("autobrake")}))
end


function land()
   if not started then
      npc = misn.npcAdd("approach", _("Ian Structure"),
            "neutral/unique/youngbusinessman.png",
            _("Ian appears to be reading something on his palmtop."), 1)
      return
   end

   if not finished then
      return
   end

   if planet.cur() ~= misplanet then
      return
   end

   tk.msg("", pay_text)

   -- If the player for some reason decided to dump their Gold, we give
   -- it a pass and just take whatever Gold they still have left.
   local ftonnes = math.min(cargo_needed, player.pilot():cargoHas("Gold"))
   player.pilot():cargoRm("Gold", ftonnes)
   player.pay(credits)

   addMiscLog(fmt.f(misn_log,
         {planet=misplanet:name(), system=missys:name()}))
   misn.finish(true)
end


function abort()
   if system.cur() == missys then
      player.allowLand(true)
      player.pilot():setNoJump(false)
      system.mrkRm(mark)
   end
   misn.finish(false)
end
