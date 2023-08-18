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


local trader_refuel_ask_text = {
   _([["Ah, thanks for responding to my request. I need {fuel:1f} hL of fuel, and I'm willing to pay {credits} for it. Would you be willing to sell me some of your fuel?"]]),
}

local trader_refuel_accept_text = {
   _([["Thanks! I'll bring my ship to a stop now so you can board it."]]),
}


function create()
   hook.custom("trader_spawn", "trader_spawn")
   hook.jumpout("exit")
   hook.land("exit")
end


local trader_spawn_events = {
   -- Fuel request event.
   function(p)
      if rnd.rnd() > 0.1 then
         return
      end

      local mem = p:memory()
      local shipclass = p:ship():class()
      if not p:exists() or not mem.natural or p:leader() ~= nil
            or (shipclass ~= "Yacht" and shipclass ~= "Courier")
            or mem.spawn_origin_type ~= "system" then
         return
      end

      local stats = p:stats()
      if stats.fuel > stats.fuel_max - 2*stats.fuel_consumption then
         return
      end

      -- Choose jump destination.
      local jumps = system.cur():jumps()
      if #jumps <= 1 then
         return
      end
      local jmp = jumps[rnd.rnd(1, #jumps)]
      mem.refuel_dest = jmp:dest()

      mem.natural = false
      mem.refuel_reward = p:credits() * rnd.uniform(0.05, 0.15)

      p:setHilight()
      p:setNoClear()
      p:control()
      p:hyperspace(mem.refuel_dest, true)

      hook.timer(2, "timer_trader_refuel_request", p)
      hook.pilot(p, "hail", "pilot_hail_trader_refuel_request")
   end,
}


function trader_spawn(p)
end


function timer_trader_refuel_request(p)
   local mem = p:memory()
   if mem.refuel_started or mem.refuel_finished then
      return
   end

   local stats = p:stats()
   if stats.fuel > stats.fuel_max - stats.fuel_consumption then
      p:setHilight(false)
      p:setActiveBoard(false)
      mem.refuel_finished = true
      p:hookClear()
      p:taskClear()
      p:hyperspace(mem.refuel_dest, true)
      return
   end

   local msg = fmt.f(_("Attention: I need some fuel and am prepared to offer {credits} in exchange. Please hail me if you're interested in selling."),
         {credits=fmt.credits(mem.refuel_reward)})
   p:broadcast(msg)

   hook.timer(20, "timer_trader_refuel_request", p)
end


function pilot_hail_trader_refuel_request(p)
   local mem = p:memory()
   if mem.refuel_finished then
      return
   end

   player.commClose()

   if mem.refuel_started then
      tk.msg("", _([["I'm ready for the fuel transfer."]]))
      return
   end

   local stats = p:stats()
   if stats.fuel >= stats.fuel_max then
      tk.msg("", _([["Ah, sorry, I don't need fuel anymore; my tanks are full."]]))
      p:setHilight(false)
      p:setActiveBoard(false)
      mem.refuel_finished = true
      p:hookClear()
      p:taskClear()
      p:hyperspace(mem.refuel_dest, true)
      return
   end

   local stats = p:stats()
   local fuel = math.min(stats.fuel_consumption, stats.fuel_max - stats.fuel)
   local text = trader_refuel_ask_text[rnd.rnd(1, #trader_refuel_ask_text)]
   if tk.yesno("", fmt.f(text, {fuel=fuel, credits=mem.refuel_reward})) then
      tk.msg("", trader_refuel_accept_text[rnd.rnd(1, #trader_refuel_accept_text)])
      p:setActiveBoard()
      p:taskClear()
      p:brake()
      mem.refuel_started = true
      hook.pilot(p, "board", "pilot_board_trader_refuel_request")
   end
end


function pilot_board_trader_refuel_request(p, boarder)
   if boarder ~= player.pilot() then
      return
   end

   player.unboard()

   tk.msg("", _([[You transfer the fuel and the trader gives you the promised payment in exchange.]]))

   local mem = p:memory()
   player.pay(mem.refuel_reward)
   p:pay(-mem.refuel_reward)

   p:setHilight(false)
   p:setActiveBoard(false)
   mem.refuel_finished = true
   p:hookClear()
   p:taskClear()
   p:hyperspace(mem.refuel_dest, true)
end


function exit()
   evt.finish()
end
