--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Hakoi and Salvador comm">
 <trigger>enter</trigger>
 <chance>100</chance>
 <cond>
   player.misnDone("Hakoi's Hidden Jumps")
   and not player.misnDone("Hakoi and Salvador")
   and not player.misnActive("Hakoi and Salvador")
   and faction.playerStanding("Empire") &gt;= 10
   and faction.playerStanding("Dvaered") &gt;= 0
   and player.numOutfit("Mercenary License") &gt; 0
   and player.misnDone("The macho teenager")
   and system.cur():presences()["Empire"]
 </cond>
 <flags>
  <unique />
 </flags>
 <notes>
  <done_misn name="Hakoi's Hidden Jumps"/>
  <done_misn name="The macho teenager"/>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</event>
--]]

local fmt = require "fmt"
require "proximity"


hail_text = _([["Hello, {player}. I'm sorry to bother you, but I have an important message for you from Commander Soldner.

"The Commander wanted me to relay to you that you're needed for another mission on {planet} in the {system} system. Please drop by there and contact the Commander at your earliest convenience.

"And from me personally, thank you for what you're doing in service of the Empire, {player}. My mother lives in the Hakoi system and has been terrified ever since the pirates arrived. With the help of good citizens like you, I'm certain we can drive out the pirates and make the Hakoi system safe once again."]])


function create()
   local pilots = pilot.get(faction.get("Empire"))
   if #pilots <= 0 then
      evt.finish(false)
   end

   hail_p = pilots[rnd.rnd(1, #pilots)]
   local mem = hail_p:memory()

   if not mem.natural then
      evt.finish(false)
   end

   hail_p:control()
   hail_p:follow(player.pilot())
   mem.natural = false
   hook.timer(0.5, "proximityScan", {focus=hail_p, funcname="hailme"})
end


function hailme()
   hail_p:hailPlayer()
   hail_hook = hook.pilot(hail_p, "hail", "hail")
end


function hail(p)
   player.commClose()
   p:control(false)

   -- Give the pilot back as a natural pilot.
   local mem = p:memory()
   mem.natural = true

   local pnt, sys = planet.get("Emperor's Fist")
   tk.msg("", fmt.f(hail_text,
         {player=player.name(), planet=pnt:name(), system=sys:name()}))

   evt.finish(true)
end


function leave()
   evt.finish(false)
end
