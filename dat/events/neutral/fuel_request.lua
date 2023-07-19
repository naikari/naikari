--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Fuel Request">
 <trigger>enter</trigger>
 <chance>5</chance>
 <cond>player.jumps() &gt;= 2</cond>
</event>
--]]
--[[
   Fuel Request Event

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

   Event where a civilian or trader offers to pay you for fuel.

--]]

local fmt = require "fmt"
require "events/tutorial/tutorial_common"
require "proximity"


request_text = _([["I'm sorry to bother you, but I've run out of fuel and cannot make the jump to the next system. {fuel_needed_sentence} Can you help in exchange for {credits}?"]])
accept_text = _([["Thank you! I will stop and await the fuel transfer. Please board my ship by pressing {board_key} or by #bdouble-clicking#0 on my ship. I will pay you once the fuel is transferred."]])
rehail_text = _([["Please board my ship by pressing {board_key} or by #bdouble-clicking#0 on my ship. I will pay you once the fuel is transferred."]])
board_text = _([["Thanks for the rescue! I've transferred the credits into your account."]])


factions = {"Civilian", "Trader", "Miner", "Independent"}
ships = {
   Civilian = {
      {"Llama", _("Civilian Llama")},
      {"Hyena", _("Civilian Hyena")},
      {"Gawain", _("Civilian Gawain")},
   },
   Trader = {
      {"Llama", _("Trader Llama")},
      {"Quicksilver", _("Trader Quicksilver")},
      {"Koäla", _("Trader Koäla")},
      {"Mule", _("Trader Mule")},
      {"Rhino", _("Trader Rhino")},
   },
   Miner = {
      {"Llama", _("Miner Llama")},
      {"Koäla", _("Miner Koäla")},
      {"Mule", _("Miner Mule")},
   },
   Independent = {
      {"Gawain", _("Independent Gawain")},
      {"Hyena", _("Independent Hyena")},
   },
}


function create()
   local sys = system.cur()
   local presences = sys:presences()

   -- See if a faction used by this event is available.
   local avail_factions = {}
   for i, f in ipairs(factions) do
      if presences[f] then
         avail_factions[#avail_factions + 1] = f
      end
   end

   if #avail_factions <= 0 then
      evt.finish(false)
   end

   -- Choose the faction and ship type.
   local stranded_f = avail_factions[rnd.rnd(1, #avail_factions)]
   local shiptype_l = ships[stranded_f]
   local shiptype = shiptype_l[rnd.rnd(1, #shiptype_l)]
   stranded_f = faction.get(stranded_f)

   -- Make sure we're in a system where the chosen faction will actually
   -- be stranded.
   for i, pl in ipairs(sys:planets()) do
      local services = pl:services()
      if services["inhabited"] and services["land"] and services["refuel"] then
         local f = pl:faction()
         if not f:areEnemies(stranded_f) then
            evt.finish(false)
         end
      end
   end

   -- Create the stranded ship.
   local r = sys:radius()
   local pos = vec2.new(rnd.uniform(-r, r), rnd.uniform(-r, r))
   stranded_p = pilot.add(shiptype[1], stranded_f, pos, shiptype[2])

   -- Make sure the player can afford to lose the fuel.
   fuel_needed = stranded_p:stats().fuel_consumption
   local player_fuel, player_consumption = player.fuel()
   if player_fuel - fuel_needed < player_consumption then
      stranded_p:rm()
      evt.finish(false)
   end

   stranded_p:memory().loiter = 100000
   stranded_p:setFuel(false)
   stranded_p:setNoClear()
   stranded_p:control()
   stranded_p:follow(player.pilot())
   hook.timer(0.5, "proximityScan", {focus=stranded_p, funcname="prox_hail"})

   reward = rnd.rnd(7500, 15000)

   accepted = false

   hook.land("leave")
   hook.jumpout("leave")
   hook.pilot(stranded_p, "jump", "leave")
   hook.pilot(stranded_p, "death", "leave")
   hook.pilot(stranded_p, "hail", "pilot_hail")
end


function prox_hail()
   stranded_p:hailPlayer()
   stranded_p:setVisplayer()
end


function pilot_hail(p)
   player.commClose()

   if accepted then
      tk.msg("", fmt.f(rehail_text, {board_key=tutGetKey("board")}))
      return
   end

   local needed_sentence = fmt.f(
         n_("I need {amount} kL of fuel.",
            "I need {amount} kL of fuel.", fuel_needed),
         {amount=fuel_needed})

   local s = fmt.f(request_text,
         {fuel_needed_sentence=needed_sentence, credits=fmt.credits(reward)})
   if tk.yesno("", s) then
      tk.msg("", fmt.f(accept_text, {board_key=tutGetKey("board")}))

      accepted = true
      p:control()
      p:taskClear()
      p:brake()
      p:setActiveBoard()

      hook.pilot(p, "board", "pilot_board")
   else
      p:control(false)
   end
end


function pilot_board(p, boarder)
   if boarder == player.pilot() then
      player.unboard()

      local curfuel = player.fuel()
      boarder:setFuel(curfuel - fuel_needed)
      p:setFuel(fuel_needed)

      tk.msg("", board_text)
      player.pay(reward)

      p:setActiveBoard(false)
      p:setVisplayer(false)
      p:control(false)
      p:memory().loiter = 0

      evt.finish(true)
   end
end


function leave()
   evt.finish()
end
