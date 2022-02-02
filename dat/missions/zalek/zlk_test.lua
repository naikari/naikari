--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Za'lek Test">
 <avail>
  <priority>60</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0 and not player.misnActive("Za'lek Test") and faction.playerStanding("Za'lek") &gt;= 5 and (planet.cur():services()["outfits"] or planet.cur():services()["shipyard"])</cond>
  <chance>80</chance>
  <location>Computer</location>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[

   Za'lek Test

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

   MISSION: Za'lek Test
   DESCRIPTION: You are given a Za'lek Test Engine to test.

--]]

local fmt = require "fmt"
require "cargo_common"


misn_title = _("Engine Test to {planet} ({system} system)")
misn_desc = _([[A Za'lek student research team needs a pilot to test an experimental engine by equipping a ship with it and flying to {planet} in the {system} system. You can take however long you want and whatever route you want, but you must have the test engine equipped every time you use a jump gate or you will fail the mission.

You will be required to pay a deposit of {credits} up-front; this will be refunded when you return the engine, either by finishing the mission or by aborting it.

Please note that the experimental nature of the engine means you may encounter dangerous malfunctions.]])

nodeposit_text = _([[You do not have enough credits to pay the deposit for the engine. The deposit is {credits}.]])

accept_text = _([[You are given a dangerous-looking Za'lek Test Engine. You will have to equip it to your ship through the Equipment tab.]])

pay_text = {
   _([[You arrive at your destination, happy to be safe, and return the experimental engine. You are given your pay plus a refund of the deposit you paid for the engine.]]),
}


function create()
   destpla, destsys, njumps, dist, cargo, risk, tier = cargo_calculateRoute()
   if destpla == nil then
      misn.finish(false)
   end

   if destpla:faction() ~= faction.get("Za'lek") then
      misn.finish(false)
   end

   if not destpla:services()["outfits"] then
      misn.finish(false)
   end
   misn.finish(false)
end

