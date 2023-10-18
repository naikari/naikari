--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Fake ID">
 <avail>
  <priority>99</priority>
  <cond>
   not player.misnActive("Fake ID")
   and not var.peek("no_fake_id")
  </cond>
  <chance>100</chance>
  <location>Computer</location>
  <faction>Pirate</faction>
 </avail>
</mission>
--]]
--[[

   Fake ID

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

--]] 

local fmt = require "fmt"


misn_title = _("Fake ID")
misn_desc = _([[This fake ID will allow you to conduct business with all major locations where you are currently wanted. It will be as if you were a new person. However, committing any crime will risk discovery of your identity by authorities, no gains in reputation under your fake ID will ever improve your real name's reputation under any circumstance, and gaining too much reputation with factions where you are wanted can lead to the discovery of your true identity as well. Note that fake ID does not work on pirates, for whom your reputation will be affected as normal (whether good or bad).

Cost: %s]])
misn_reward = _("None")

lowmoney = _("You don't have enough money to buy a fake ID. The price is %s.")

noticed_onplanet = _([[During a routine check, you hand over your fake ID as usual, but the person checking your ID eyes it strangely for what feels like hours. Eventually you are handed your ID back, but this is not a good sign.

When you check, you see that the secrecy of your identity is in jeopardy. You're safe for now, but you make a mental note to prepare for the worst when you take off, because your fake ID probably won't be of any further use by then.]])

noticed_offplanet = _("It seems your actions have led to the discovery of your identity. As a result, your fake ID is now useless.")


factions = {
   "Empire", "Goddard", "Dvaered", "Za'lek", "Sirius", "Soromid", "Frontier",
   "Trader", "Miner"
}
orig_standing = {}
orig_standing["__save"] = true


function create ()
   local nhated = 0
   for i, j in ipairs(factions) do
      if faction.get(j):playerStanding() < 0 then
         nhated = nhated + 1
      end
   end
   if nhated <= 0 then misn.finish(false) end

   credits = 50000 * nhated

   misn.setTitle(misn_title)
   misn.setDesc(misn_desc:format(fmt.credits(credits)))
   misn.setReward(misn_reward)
end


function accept ()
   if player.credits() < credits then
      tk.msg("", lowmoney:format(fmt.credits(credits)))
      misn.finish()
   end

   player.pay(-credits)
   misn.accept()

   for i, fn in ipairs(factions) do
      local f = faction.get(fn)
      if f:playerStanding() < 0 then
         orig_standing[fn] = f:playerStanding()
         f:setPlayerStanding(0)
      end
   end

   next_discovered = false
   standhook = hook.standing("standing")
end


function standing(f, delta, secondary)
   local fn = f:nameRaw()
   if orig_standing[fn] ~= nil then
      if delta < 0 then
         abort()
      elseif f:playerStanding() >= 20 then
         if next_discovered then
            abort()
         else
            next_discovered = rnd.rnd() < 0.1
         end
      end
   elseif fn == "Pirate" and delta >= 0 then
      local sf = system.cur():faction()
      if sf ~= nil and orig_standing[sf:nameRaw()] ~= nil then
         -- We delay choice of when you are discovered to prevent players
         -- from subverting the system to eliminate the risk.
         if next_discovered then
            abort()
         else
            next_discovered = rnd.rnd() < 0.1
         end
      end
   end
end


function abort()
   hook.rm(standhook)
   
   for i, fn in ipairs(factions) do
      if orig_standing[fn] ~= nil then
         faction.get(fn):setPlayerStanding(orig_standing[fn])
      end
   end
   
   local msg = noticed_offplanet
   if player.isLanded() then
      local f = planet.cur():faction()
      if f ~= nil and orig_standing[f:nameRaw()] ~= nil then
         msg = noticed_onplanet
      end
   end

   tk.msg("", msg)
   misn.finish(false)
end
