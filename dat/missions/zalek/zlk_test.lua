--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Za'lek Test">
 <avail>
  <priority>60</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0 and not player.misnActive("Za'lek Test") and faction.playerStanding("Za'lek") &gt;= 5 and (planet.cur():services()["outfits"] or planet.cur():services()["shipyard"])</cond>
  <chance>980</chance>
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
local mh = require "misnhelper"
require "cargo_common"


misn_title = _("Engine Test to {planet} ({system} system)")
misn_desc = _([[A Za'lek student research team needs a pilot to test an experimental engine by equipping a ship with it and flying to {planet} in the {system} system. You can take however long you want and whatever route you want, but you must have the test engine equipped every time you use a jump gate or you will fail the mission.

You will be required to pay a deposit of {credits} up-front; this will be refunded when you return the engine, either by finishing the mission or by aborting it.]])

nodeposit_text = _([[You do not have enough credits to pay the deposit for the engine. The deposit is {credits}, but you only have {player_credits}. You need {shortfall_credits} more.]])

accept_text = _([[You are given a dangerous-looking Za'lek Test Engine. You will have to equip it to your ship through the Equipment tab.]])

pay_text = {
   _([[You arrive at your destination, happy to be safe, and return the experimental engine. You are given your pay plus a refund of the deposit you paid for the engine.]]),
}

refund_text = _([[The experimental engine is returned and you are given your {credits} deposit back.]])

fail_land_text = _([[You landed on your destination without using the experimental engine, thus failing your mission. It is returned and you are given your {credits} deposit back, but you are not given the promised payment.]])

fail_land_norefund_text = _([[You have landed on your destination without the experimental engine, thus failing your mission. Furthermore, you are not given your deposit back since you no longer have the engine and thus cannot return it.]])

fail_msg = _("You jumped without the Za'lek Test Engine equipped.")
refund_msg = _("Engine has been returned and your deposit refunded.")

piracyrisk = {}
piracyrisk[1] = _("Piracy Risk: None")
piracyrisk[2] = _("Piracy Risk: Low")
piracyrisk[3] = _("Piracy Risk: Medium")
piracyrisk[4] = _("Piracy Risk: High")


function create()
   -- Note: this mission does not make any system claims.

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

   local risktext, riskreward, jumpreward, distreward

   if risk == 0 then
      risktext = piracyrisk[1]
      riskreward = 0
   elseif risk <= 25 then
      risktext = piracyrisk[2]
      riskreward = 40
   elseif risk > 25 and risk <= 100 then
      risktext = piracyrisk[3]
      riskreward = 100
   else
      risktext = piracyrisk[4]
      riskreward = 200
   end

   jumpreward = 10000
   distreward = 0.01
   reward = (1.25^tier
         * (risk*riskreward + njumps*jumpreward + dist*distreward + 50000)
         * (1 + 0.05*rnd.twosigma()))
   deposit = outfit.price("Za'lek Test Engine")

   misn.setTitle(fmt.f(misn_title,
            {planet=destpla:name(), system=destsys:name()}))
   local desc = fmt.f(misn_desc,
         {planet=destpla:name(), system=destsys:name(),
            credits=fmt.credits(deposit)})
   cargo_setDesc(desc, nil, nil, destpla, nil, risktext)
   misn.setReward(fmt.credits(reward))

   misn.markerAdd(destsys, "computer")
end


function accept()
   local creds, screds = player.credits(2)
   if creds < deposit then
      tk.msg("", fmt.f(nodeposit_text,
            {credits=fmt.credits(deposit), player_credits=screds,
               shortfall_credits=fmt.credits(depisit - creds)}))
      misn.finish()
   end

   misn.accept()

   player.pay(-deposit, "adjust")
   player.outfitAdd("Za'lek Test Engine")

   tk.msg("", accept_text)

   local osd_msg = {
      _("Equip the Za'lek Test Engine onto your ship"),
      fmt.f(_("Land on {planet} ({system} system)"),
         {planet=destpla:name(), system=destsys:name()}),
   }
   misn.osdCreate(_("Engine Test"), osd_msg)

   hook.land("land")
   hook.takeoff("takeoff")
   hook.jumpin("jumpin")
end


function outfit_mounted(oname, outfits)
   outfits = outfits or player.pilot():outfits()
   for i, o in ipairs(outfits) do
      if o == outfit.get(oname) then
         return true
      end
   end
   return false
end


function outfit_owned(oname)
   for i, o in ipairs(player.outfits()) do
      if o == outfit.get(oname) then
         return true
      end
   end
   return false
end


function remove_engine()
   if outfit_owned("Za'lek Test Engine") then
      player.outfitRm("Za'lek Test Engine")
      return true
   end

   if player.isLanded() and outfit_mounted("Za'lek Test Engine") then
      player.pilot():outfitRm("Za'lek Test Engine")
      if not planet.cur():services()["outfits"] then
         player.pilot():outfitAdd("Beat Up Small Engine")
      end
      return true
   end

   for i, s in ipairs(player.ships()) do
      if outfit_mounted("Za'lek Test Engine", player.shipOutfits(s.name)) then
         player.shipOutfitRm(s.name, "Za'lek Test Engine")
         return true
      end
   end

   return false
end


function land()
   if planet.cur() == destpla then
      if outfit_mounted("Za'lek Test Engine") then
         tk.msg("", pay_text[rnd.rnd(1, #pay_text)])
         if not remove_engine() then
            warn(_("Failed to remove Za'lek Test Engine even though mounted."))
         end
         player.pay(deposit, "adjust")
         player.pay(reward)
         misn.finish(true)
      else
         if remove_engine() then
            tk.msg("", fmt.f(fail_land_text, {credits=fmt.credits(deposit)}))
            player.pay(deposit, "adjust")
         else
            tk.msg("", fail_land_norefund_text)
         end
         misn.finish(false)
      end
   end
end


function takeoff()
   if outfit_mounted("Za'lek Test Engine") then
      misn.osdActive(2)
   else
      misn.osdActive(1)
   end
end


function jumpin()
   if not outfit_mounted("Za'lek Test Engine") then
      mh.showFailMsg(fail_msg)
      if remove_engine() then
         player.msg(refund_msg)
         player.pay(deposit, "adjust")
      end
      misn.finish(false)
   end
end


function abort()
   if remove_engine() then
      tk.msg("", fmt.f(refund_text, {credits=fmt.credits(deposit)}))
      player.pay(deposit, "adjust")
   end
   misn.finish(false)
end

