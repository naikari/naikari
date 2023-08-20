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
local pilotname = require "pilotname"


local trader_refuel_broadcast = {
   _("Attention: I need some fuel and am prepared to offer {credits} in exchange. Please hail me if you're interested in selling."),
   _("I'm in need of some fuel and prepared to offer {credits} for it. Please hail me if you have some spare fuel to sell."),
   _("Attention all pilots: if you have some fuel to spare, please contact me. I'm willing to pay {credits} for some fuel."),
   _("I'm offering {credits} to anyone who's willing to sell me a little fuel. Please hail me if you're interested in selling."),
   _("Would anyone be willing to sell me some fuel for {credits}? Please hail me if you would be."),
   _("If anyone's got fuel to spare, I could use a little, and I'm willing to pay {credits} in exchange. Please hail me if you're willing to sell me some of your fuel."),
}

local trader_refuel_cancel_broadcast = {
   _("Actually, it looks like I have enough fuel. Sorry about that."),
   _("Nevermind on that fuel request. It looks like I've got enough."),
}

local trader_refuel_ask_text = {
   _([["Ah, thanks for responding to my request. I need {fuel:.0f} hL of fuel, and I'm willing to pay {credits} for it. Would you be willing to sell me some of your fuel?"]]),
   _([["Hi there! I'm on an urgent cargo delivery mission and need some fuel to make it, but don't have enough time to land. Could you help me out with {fuel:.0f} hL of fuel? I'll pay you {credits} in exchange."]]),
   _([["Ah, perfect! See, it's not an emergency, but I need some more fuel to make it to my destination. Problem is, if I land, I'll miss my delivery deadline. Would you please sell me {fuel:.0f} hL of fuel for {credits}, so that I can make my delivery on time?"]]),
   _([["Whew, what a relief! See, I kind of accepted a delivery mission without running the numbers properly. I don't have enough fuel to make it to my destination, and if I land, I'll certainly miss my deadline. Would you be willing to help me out by selling me {fuel:.0f} hL of fuel? I'm willing to pay {credits} in exchange."]]),
}

local trader_refuel_accept_text = {
   _([["Thanks! I'll bring my ship to a stop now so you can board it."]]),
}

local trader_refuel_full_text = {
   _([[You transfer {fuel:.1f} hL of fuel and the trader gives you the promised {credits} payment in exchange.]]),
}

local trader_refuel_partial_text = {
   _([[You transfer all of the fuel from your tanks to the trader. Since it wasn't all the fuel they asked for, the trader gives you only {credits} in exchange.]]),
   _([["Oh, wow, that's all your fuel, isn't it? Well, if you're sure it's ok. It's not all the fuel I need, but it's better than nothing. Here, I'll give you {credits} for it."]]),
}

local trader_refuel_none_text = {
   _([[The trader frowns and tells you to get lost when they find out that you're wasting their time.]]),
   _([["What the hell is this, a prank? You don't have even a drop of fuel in your tanks! Get off my ship!"]]),
}


function create()
   hook.custom("trader_spawn", "trader_spawn")
   hook.jumpout("exit")
   hook.land("exit")
end


local trader_spawn_events = {
   -- Fuel request event.
   function(p)
      local mem = p:memory()
      local shipclass = p:ship():class()
      if not p:exists() or not mem.natural or p:leader() ~= nil
            or (shipclass ~= "Yacht" and shipclass ~= "Courier")
            or mem.spawn_origin_type ~= "system" then
         return false
      end

      local stats = p:stats()
      if stats.fuel > stats.fuel_max - stats.fuel_consumption then
         return false
      end

      if rnd.rnd() > 0.1 then
         return false
      end

      -- Choose jump destination.
      local total_jumps = system.cur():jumps()
      local jumps = {}
      for i = 1, #total_jumps do
         local jmp = total_jumps[i]
         -- Only count non-hidden jumps.
         if not jmp:hidden() then
            jumps[#jumps + 1] = jmp
         end
      end
      if #jumps <= 1 then
         return false
      end
      local jmp = jumps[rnd.rnd(1, #jumps)]
      mem.refuel_dest = jmp:dest()

      mem.natural = false
      mem.refuel_reward = p:credits() * rnd.uniform(0.05, 0.15)

      p:rename(pilotname.generic())
      p:setHilight()
      p:setNoClear()
      p:control()
      p:hyperspace(mem.refuel_dest, true)

      hook.timer(2, "timer_trader_refuel_request", p)
      hook.pilot(p, "hail", "pilot_hail_trader_refuel_request")

      return true
   end,
}


function trader_spawn(p)
   if not p:exists() then
      return
   end
   for i = 1, #trader_spawn_events do
      if trader_spawn_events[i](p) then
         return
      end
   end
end


function timer_trader_refuel_request(p)
   if not p:exists() then
      return
   end

   local mem = p:memory()
   if mem.refuel_finished then
      return
   end

   local stats = p:stats()
   local target = stats.fuel_max
   if not mem.refuel_started then
      target = target - 0.5*stats.fuel_consumption
   end
   if stats.fuel >= target then
      if mem.refuel_started then
         p:comm(player.pilot(), _("Nevermind, my tanks are full now."), true)
      else
         local msg = trader_refuel_cancel_broadcast[rnd.rnd(1, #trader_refuel_cancel_broadcast)]
         p:broadcast(msg)
      end
      p:setHilight(false)
      p:setActiveBoard(false)
      mem.refuel_finished = true
      p:hookClear()
      p:taskClear()
      p:hyperspace(mem.refuel_dest, true)
      return
   end

   if not mem.refuel_started then
      local msg = trader_refuel_broadcast[rnd.rnd(1, #trader_refuel_broadcast)]
      p:broadcast(fmt.f(msg, {credits=fmt.credits(mem.refuel_reward)}))
   end

   hook.timer(20, "timer_trader_refuel_request", p)
end


function pilot_hail_trader_refuel_request(p)
   if not p:exists() then
      return
   end

   local mem = p:memory()
   if mem.refuel_finished then
      return
   end

   player.commClose()

   if mem.refuel_started then
      p:comm(player.pilot(), _("I'm ready for the fuel transfer."), true)
      return
   end

   local stats = p:stats()
   if stats.fuel >= stats.fuel_max - 5 then
      p:comm(player.pilot(),
            _("Sorry, I don't need fuel anymore; my tanks are full."), true)
      p:setHilight(false)
      p:setActiveBoard(false)
      mem.refuel_finished = true
      p:hookClear()
      p:taskClear()
      p:hyperspace(mem.refuel_dest, true)
      return
   end

   local fuel = math.min(stats.fuel_consumption, stats.fuel_max - stats.fuel)
   local text = trader_refuel_ask_text[rnd.rnd(1, #trader_refuel_ask_text)]
   if tk.yesno("", fmt.f(text,
         {fuel=fuel, credits=fmt.credits(mem.refuel_reward)})) then
      tk.msg("", trader_refuel_accept_text[rnd.rnd(1, #trader_refuel_accept_text)])
      p:setActiveBoard()
      p:taskClear()
      p:brake()
      mem.refuel_started = true
      hook.pilot(p, "board", "pilot_board_trader_refuel_request")
   end
end


function pilot_board_trader_refuel_request(p, boarder)
   if not p:exists() then
      return
   end

   if boarder ~= player.pilot() then
      return
   end

   player.unboard()

   local mem = p:memory()
   local stats = p:stats()
   local fuel = stats.fuel
   local fuel_needed = math.min(stats.fuel_consumption, stats.fuel_max - fuel)

   local pp = player.pilot()
   local player_stats = pp:stats()
   local player_fuel = player_stats.fuel

   if player_fuel >= fuel_needed then
      local reward = mem.refuel_reward
      local s = trader_refuel_full_text[rnd.rnd(1, #trader_refuel_full_text)]
      tk.msg("", fmt.f(s, {fuel=fuel_needed, credits=fmt.credits(reward)}))
      pp:setFuel(player_fuel - fuel_needed)
      p:setFuel(fuel + fuel_needed)
      player.pay(reward)
      p:pay(-reward)
   elseif player_fuel >= 1 then
      local reward = mem.refuel_reward * player_fuel / mem.refuel_reward
      local s = trader_refuel_partial_text[rnd.rnd(1, #trader_refuel_partial_text)]
      tk.msg("", fmt.f(s, {fuel=player_fuel, credits=fmt.credits(reward)}))
      pp:setFuel(0)
      p:setFuel(fuel + player_fuel)
      player.pay(reward)
      p:pay(-reward)
   else
      tk.msg("", trader_refuel_none_text[rnd.rnd(1, #trader_refuel_none_text)])
   end

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
