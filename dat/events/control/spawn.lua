--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Pilot Spawn Events">
 <trigger>enter</trigger>
 <chance>100</chance>
 <priority>0</priority>
</event>
--]]
--[[

   Meta-event for small events that happen when pilots spawn.

--]]

local fmt = require "fmt"


local trader_spawn_events = {
   -- Fuel request event.
   function(p)
      if rnd.rnd() > 0.1 then
         return
      end

      local mem = p:memory()
      local shipclass = p:ship():class()
      if not p:exists() or not mem.natural or p:leader() ~= nil
            or (shipclass ~= "Yacht" and shipclass ~= "Courier") then
         return
      end

      mem.natural = false
      mem.refuel_reward = p:credits() * rnd.uniform(0.05, 0.15)
   end,
}


function create()
   hook.custom("trader_spawn", "trader_spawn")
   hook.jumpout("exit")
   hook.land("exit")
end


function trader_spawn(p)
end


function exit()
   evt.finish()
end
