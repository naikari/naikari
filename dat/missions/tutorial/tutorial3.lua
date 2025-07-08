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


local ask_text = _([["Hello again, {player}! Are you ready for that other job I had for you? It's a little more effort than the last job, but still not too hard, and I'll pay you a nice {credits} reward for it."]])

local accept_text = _([["Perfect! Alright, this time we will be going into space; I will be joining you. I'll make my way to your ship now and wait for you there. When you're ready to begin, press the Take Off button."]])

local overlay_text = _([["It's been awhile since I've been in space," Ian notes somewhat nervously. "Alright, the reason we're here is I need you to mine some Gold for me. Of course, I could buy it from the Commodity Exchange, but there happens to be a safe pure Gold asteroid field in this system, and that will be much cheaper than buying it.

"I've marked the asteroid field on your ship's overlay map. Could you press {overlaykey} to open your overlay map so I can show you, please?"]])

local autonav_text = _([["Thank you! If you look here, you'll see I've marked an area with the label, 'Asteroid Field'. I need you to use Autonav to take us to that area as fast as possible. I mean, of course, the trip will take the same duration in real-time, but giving the work to Autonav will allow you to leave the captain's chair and do other things; it makes the time passage feel almost instantaneous. Most pilots call this phenomenon 'Time Compression', I believe, or 'TC' for short." Just #bright-click#0 on the location of the asteroid field to initialize Autonav."]])

local mining_text = _([[Alright, let's start mining! Of course, mining is done with the same weaponry you would use to defend yourself against pirates should you be attacked. All you have to do is click on a suitable asteroid to target it, then use {primarykey} and {secondarykey} to fire your weapons and destroy the targeted asteroid. Once it's destroyed, it will normally drop some commodity, Gold in this case, and you can pick the commodity up simply by flying over its location.

"I just need you to mine enough Gold to fill your cargo hold to capacity. I'll let you know what to do with it when your cargo hold is full."]])

local cooldown_text = _([[Ian Structure briefly startles you as he taps on your shoulder. "Sorry! I just noticed that your weapons are getting pretty hot. That's not doing your weapon accuracy any favors. Why don't you cool everything down by pressing {autobrake_key}?"]])

local dest_text = _([["That should do it! Good job! With those firing skills, maybe you'd even be able to handle yourself against a pirate! I sure hope you don't have to, thô. Oh, what am I saying? There's no way the Empire would let pirates get into a place like this!" Ian sweats nervously, as if not entirely convinced.

"Alright, I need you to take this Gold to {planet}. You should be able to see it on your overlay map, right? You can interact with its icon the same way you would interact with the planet itself, so you should be able to tell Autonav to land us there no problem."]])

local pay_text = _([[Ian steps out of your ship and stretches his arms, seemingly happy to be back in atmosphere. "Thank you for your service once again," he says as he hands you a credit chip with your payment. "If you like, I have one more job for you. Meet me at the bar in a bit."]])

local misn_desc = _("Ian Structure has hired you to mine Gold from some asteroids.")
local misn_log = _([[You accepted another job from Ian Structure, this time mining some Gold from asteroids for him. He asked you to speak with him again on {planet} ({system}) for another job.]])

local credits = 5000


function create()
   misplanet, missys = planet.get("Octawius")

   misn.setNPC(_("Ian Structure"),
         "neutral/unique/youngbusinessman.png",
         _("Ian is at the bar. He said he has another job for you."))
end


function accept()
   if tk.yesno("", fmt.f(ask_text,
         {player=player.name(), credits=fmt.credits(credits)})) then
      tk.msg("", fmt.f(accept_text, {player=player.name()}))

      misn.accept()

      misn.setTitle(_("Ian's Supplies"))
      misn.setReward(fmt.credits(credits))
      misn.setDesc(misn_desc)

      local osd_desc = {
         _("Press the Take Off button to go into space"),
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
   else
      misn.finish()
   end
end


function enter()
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
            secondarykey=tutGetKey("secondary")}))
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
   if player.pilot():cargoFree() > 0 then
      hook.timer(0.5, "timer_mining")
      return
   end

   hook.rm(input_hook)
   system.mrkRm(mark)
   hook.rm(overheat_timer_hook)

   player.allowLand(true)
   player.pilot():setNoJump(false)

   tk.msg("", fmt.f(dest_text, {planet=misplanet:name()}))
   misn.osdActive(9)

   misn.markerMove(marker, missys, misplanet)

   hook.land("land")
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
   if planet.cur() ~= misplanet then
      return
   end

   tk.msg("", pay_text)

   local ftonnes = player.pilot():cargoHas("Gold")
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
