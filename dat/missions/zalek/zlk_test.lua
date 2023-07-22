--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Za'lek Test">
 <avail>
  <priority>60</priority>
  <cond>
   player.numOutfit("Mercenary License") &gt; 0
   and faction.playerStanding("Za'lek") &gt;= 5
   and (planet.cur():services().outfits
      or planet.cur():services().shipyard)
  </cond>
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
misn_desc = _([[A Za'lek student research team needs a pilot to test an experimental engine by equipping a ship with it and flying to {planet} in the {system} system.

You will be required to pay a deposit up-front: {small_credits} for a small engine, {medium_credits} for a medium engine, or {large_credits} for a large engine. The deposit will be refunded when you return the engine by either completing or aborting the mission.]])

nodeposit_text = _([[You do not have enough credits to pay the deposit for the engine. The deposit is {credits}, but you only have {player_credits}. You need {shortfall_credits} more.]])

accept_text = _([[You are given a dangerous-looking {engine}. You will have to equip it to your ship thru the Equipment tab.]])

pay_text = {
   _([[You arrive at your destination, happy to be safe, and return the experimental engine. You are given your pay plus a refund of the deposit you paid for the engine.]]),
   _([[As you collect your pay and deposit, you ask one of the researchers why they don't use drones for dangerous jobs like this. The researcher incredulously answers that they wouldn't want to risk destroying a precious drone.]]),
}

refund_text = _([[The experimental engine is returned and you are given your {credits} deposit back.]])

fail_land_text = _([[You landed on your destination without using the experimental engine, thus failing your mission. It is returned and you are given your {credits} deposit back, but you are not given the promised payment.]])

fail_land_norefund_text = _([[You have landed on your destination without the experimental engine, thus failing your mission. Furthermore, you are not given your deposit back since you no longer have the engine and thus cannot return it.]])

fail_msg = _("You jumped without the {engine} equipped.")
refund_msg = _("Engine has been returned and your deposit refunded.")


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

   local risktext, riskreward
   if risk == 0 then
      risktext = _("#nPiracy Risk:#0 None")
      riskreward = 0
   elseif risk <= 25 then
      risktext = _("#nPiracy Risk:#0 Low")
      riskreward = 250
   elseif risk > 25 and risk <= 100 then
      risktext = _("#nPiracy Risk:#0 Medium")
      riskreward = 500
   else
      risktext = _("#nPiracy Risk:#0 High")
      riskreward = 500
   end

   misn_engine = "Za'lek S300 Test Engine"
   deposit = outfit.price(misn_engine)

   local jumpreward = 10000
   local distreward = 0.1
   reward = (1.25^tier
         * (risk*riskreward + njumps*jumpreward + dist*distreward + 75000)
         * (1 + 0.05*rnd.twosigma()))

   deposit_small = outfit.price("Za'lek S300 Test Engine")
   deposit_medium = outfit.price("Za'lek M1200 Test Engine")
   deposit_large = outfit.price("Za'lek L6500 Test Engine")

   misn.setTitle(fmt.f(misn_title,
            {planet=destpla:name(), system=destsys:name()}))
   local desc = fmt.f(misn_desc,
         {planet=destpla:name(), system=destsys:name(),
            small_credits=fmt.credits(deposit_small),
            medium_credits=fmt.credits(deposit_medium),
            large_credits=fmt.credits(deposit_large)})
   cargo_setDesc(desc, nil, nil, destpla, njumps, nil, risktext)
   misn.setReward(fmt.credits(reward))

   misn.markerAdd(destsys, "computer")
end


function accept()
   for i, slot in ipairs(player.pilot():ship():getSlots()) do
      if slot.type == "structure" and slot.property == "Engine" then
         if slot.size == "Large" then
            misn_engine = "Za'lek L6500 Test Engine"
         elseif slot.size == "Medium" then
            misn_engine = "Za'lek M1200 Test Engine"
         else
            misn_engine = "Za'lek S300 Test Engine"
         end
         break
      end
   end

   deposit = outfit.price(misn_engine)

   local creds, screds = player.credits(2)
   if creds < deposit then
      tk.msg("", fmt.f(nodeposit_text,
            {credits=fmt.credits(deposit), player_credits=screds,
               shortfall_credits=fmt.credits(deposit - creds)}))
      misn.finish()
   end

   misn.accept()

   tk.msg("", fmt.f(accept_text, {engine=_(misn_engine)}))

   player.pay(-deposit, "adjust")
   player.outfitAdd(misn_engine)

   local osd_msg = {
      fmt.f(_("Equip the {engine} onto your ship"),
         {engine=_(misn_engine)}),
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
   if outfit_owned(misn_engine) then
      player.outfitRm(misn_engine)
      return true
   end

   if player.isLanded() and outfit_mounted(misn_engine) then
      local p = player.pilot()
      p:outfitRm(misn_engine)
      if not planet.cur():services()["outfits"] then
         p:outfitAdd("Beat Up Small Engine")
      end
      return true
   end

   return false
end


function land()
   if planet.cur() == destpla then
      if outfit_mounted(misn_engine) then
         tk.msg("", pay_text[rnd.rnd(1, #pay_text)])
         if not remove_engine() then
            warn(_("Failed to remove Za'lek Test Engine even thô mounted."))
         end
         player.pay(deposit, "adjust")
         player.pay(reward)
         var.push("zalek_test_done", true)
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
   if outfit_mounted(misn_engine) then
      misn.osdActive(2)
   else
      misn.osdActive(1)
   end
end


function jumpin()
   if not outfit_mounted(misn_engine) then
      mh.showFailMsg(fmt.f(fail_msg, {engine=_(misn_engine)}))
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

