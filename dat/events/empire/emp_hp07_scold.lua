--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Big Time Scolding">
 <trigger>land</trigger>
 <chance>100</chance>
 <priority>10</priority>
 <cond>
   player.misnDone("Big Time")
   and planet.cur() == planet.get("Emperor's Fist")
 </cond>
 <flags>
  <unique />
 </flags>
 <notes>
  <done_misn name="Big Time"/>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</event>
--]]

local fmt = require "fmt"
require "missions/empire/common"


scold_text = _([[As you land on {planet}, you are surprised to see Commander Soldner waiting for you with a furious expression.

"What the hell were you thinking, {player}?!" he barks the moment you step out of your ship. "Going off on your own like that! Do you have any idea what I had to do to avoid a diplomatic incident from that stunt you pulled? Come on, {player}, you know better than this!"

You sheepishly explain what happened and hand him a data chip containing the map data you gathered. His eyes widen and his demeanor changes. "Well, I suppose I've given you a sufficient warning. Don't pull off a stunt like that again, you hear? In any case, I'm going to analyze this data and come up with a plan of action. I'll see you at the bar."]])

log_text = _([[As you landed on {planet}, Commander Soldner furiously scolded you for going off on your own, noting that you almost caused a diplomatic incident. When you told him what happened and handed him the map data you discovered, he suddenly calmed down and asked you to meet him at the bar on {planet} in the {system} system.]])


function create()
   local curplanet, cursys = planet.cur()
   tk.msg("", fmt.f(scold_text,
         {planet=curplanet:name(), player=player.name()}))
   emp_addShippingLog(fmt.f(log_text,
         {planet=curplanet:name(), system=cursys:name()}))
   evt.finish(true)
end
