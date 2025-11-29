--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Bounty Awarder">
 <trigger>enter</trigger>
 <chance>100</chance>
 <priority>0</priority>
</event>
--]]
--[[

   Bounty Awarder Event

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

   This event awards bounties to the player when killing pilots which
   have enemies in the current system.

--]]

local fmt = require "fmt"


local pay_msg_default = _("{credits} {faction} bounty paid for killing {pilot}.")
local pay_msg_faction = {
   Empire = _("{credits} Imperial official bounty awarded for dispatching {pilot}."),
   Pirate = _("{credits} paid by local crime lord for eliminating {pilot}."),
}

local nopay_factions = {
   "Civilian",
   "Trader",
   "Miner",
   "Mercenary",
   "Frontier",
   "FLF",
}


function create()
   hook.attacked("attacked")
   hook.death("death")
   hook.jumpout("exit")
   hook.land("exit")
end


function log_entry(text)
   shiplog.create("combat", p_("log", "Combat"), false, 50)
   shiplog.append("combat", text)
end


function attacked(target, attacker, damage)
   if attacker == nil or not attacker:exists() then
      return
   end
   if attacker ~= player.pilot()
         and attacker:leader(true) ~= player.pilot() then
      return
   end
   target:memory().player_bounty_claimed = true
end


function death(target, killer)
   if killer == nil or not killer:exists() then
      if target:memory().player_bounty_claimed then
         killer = player.pilot()
      else
         return
      end
   end
   if killer ~= player.pilot() and killer:leader(true) ~= player.pilot() then
      return
   end

   local reward = target:memory().kill_reward
   if not reward or reward <= 0 then
      return
   end

   local target_f = target:faction()
   local pay_f = system.cur():faction()
   if target_f == faction.get("Mercenary") then
      -- Mercenaries are a special case since they have no formal
      -- enemies, but likely should award a bounty.
      pay_f = nil
      local presences = system.cur():presences()
      if presences["Pirate"] and rnd.rnd() < 0.9 then
         pay_f = faction.get("Pirate")
      elseif rnd.rnd() < 0.05 then
         local f_choices = {}
         for f, presence in pairs(presences) do
            if faction.get(f):playerStanding() >= 0 or f == "Pirate" then
               local canpay = true
               for i = 1, #nopay_factions do
                  if f == nopay_factions[i] then
                     canpay = false
                     break
                  end
               end
               if canpay then
                  f_choices[#f_choices + 1] = f
               end
            end
         end
         if #f_choices > 0 then
            pay_f = faction.get(f_choices[rnd.rnd(1, #f_choices)])
         end
      end
   elseif pay_f == nil or not pay_f:areEnemies(target_f) then
      pay_f = nil
      local pay_f_presence = 0
      for f, presence in pairs(system.cur():presences()) do
         local fac = faction.get(f)
         if fac:areEnemies(target_f)
               and (fac:playerStanding() >= 0 or f == "Pirate") then
            local canpay = true
            for i = 1, #nopay_factions do
               if f == nopay_factions[i] then
                  canpay = false
                  break
               end
            end
            if canpay and (pay_f == nil or presence > pay_f_presence) then
               pay_f = fac
            end
         end
      end
   end

   if pay_f == nil then
      return
   end

   local msg = pay_msg_faction[pay_f:nameRaw()] or pay_msg_default
   msg = fmt.f(msg,
         {credits=fmt.credits(reward), faction=pay_f:name(),
            pilot=target:name()})

   player.pay(reward)
   player.msg(msg)
   log_entry(msg)
end


function exit()
   evt.finish()
end
