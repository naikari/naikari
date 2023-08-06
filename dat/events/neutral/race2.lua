--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Race Event 2">
 <priority>100</priority>
 <cond>
   player.misnDone("Racing Skills 1")
   and system.cur():presence("Civilian") &gt; 0
   and system.cur():presence("Pirate") &lt;= 0
 </cond>
 <trigger>enter</trigger>
 <chance>10</chance>
 <notes>
  <done_misn name="Racing Skills 1"/>
 </notes>
</event>
--]]
--[[

   Event version of the race 2 mission (showing a race in progress).

--]]

local fmt = require "fmt"


function create()
   hook.land("leave")
   hook.jumpout("leave")
end


function leave()
   evt.finish()
end
