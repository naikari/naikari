--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Commodity Run">
 <avail>
  <priority>79</priority>
  <cond>var.peek("commodity_runs_active") == nil or var.peek("commodity_runs_active") &lt; 3</cond>
  <chance>90</chance>
  <location>Computer</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Proteron</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Thurion</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 3 as
   published by the Free Software Foundation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

--

   Commodity delivery missions.
--]]

local fmt = require "fmt"
local mh = require "misnhelper"

--Mission Details
local misn_title = _("{commodity} Delivery")
local misn_desc = _("{planet} has an insufficient supply of {commodity} to satisfy the current demand. Go to any planet which sells this commodity and bring as much of it back as possible.")

local cargo_land_title = _("Delivery success!")

local cargo_land = {
   _("The containers of {commodity} are carried out of your ship and tallied. After several different men double-check the register to confirm the amount, you are paid {credits} and summarily dismissed."),
   _("The containers of {commodity} are quickly and efficiently unloaded, labeled, and readied for distribution. The delivery manager thanks you with a credit chip worth {credits}."),
   _("The containers of {commodity} are unloaded from your vessel by a team of dockworkers who are in no rush to finish, eventually delivering {credits} after the number of kilotonnes is determined."),
   _("The containers of {commodity} are unloaded by robotic drones that scan and tally the contents. The human overseër hands you {credits} when they finish."),
}


-- A script may require "missions/neutral/commodity_run" and override this
-- with a table of (raw) commodity names to choose from.
commchoices = nil


function update_active_runs(change)
   local current_runs = var.peek("commodity_runs_active")
   if current_runs == nil then current_runs = 0 end
   var.push("commodity_runs_active", math.max(0, current_runs + change))

   -- Note: This causes a delay (defined in create()) after accepting,
   -- completing, or aborting a commodity run mission.  This is
   -- intentional.
   var.push("last_commodity_run", time.tonumber(time.get()))
end


function create()
   misplanet, missys = planet.cur()

   -- String claim prevents having multiple commodity runs on one
   -- planet, since that would be a kind of strange situation that would
   -- be a bit confusing to navigate.
   if not misn.claim("commodity_run_" .. misplanet:name()) then
      misn.finish(false)
   end
   
   if commchoices == nil then
      local std = commodity.getStandard()
      chosen_comm = std[rnd.rnd(1, #std)]:nameRaw()
   else
      chosen_comm = commchoices[rnd.rnd(1, #commchoices)]
   end
   local comm = commodity.get(chosen_comm)
   local mult = rnd.rnd(1, 3) + math.abs(rnd.threesigma() * 2)
   price = comm:price() * mult

   local last_run = var.peek("last_commodity_run")
   if last_run ~= nil then
      local delay = time.create(0, 7, 0)
      if time.get() < time.fromnumber(last_run) + delay then
         misn.finish(false)
      end
   end

   for i, j in ipairs(missys:planets()) do
      for k, v in pairs(j:commoditiesSold()) do
         if v == comm then
            misn.finish(false)
         end
      end
   end

   -- Set Mission Details
   misn.setTitle(fmt.f(misn_title, {commodity=comm:name()}))
   marker = misn.markerAdd(system.cur(), "computer")
   misn.setDesc(fmt.f(misn_desc,
         {planet=misplanet:name(), commodity=comm:name()}))
   misn.setReward(fmt.f(n_("{price} ¢/kt", "{price} ¢/kt", price),
         {price=fmt.number(price)}))
end


function accept()
   local comm = commodity.get(chosen_comm)

   misn.accept()
   update_active_runs(1)

   local osd_msg = {
      fmt.f(_("Buy as much {commodity} as possible"), {commodity=comm:name()}),
      fmt.f(_("Take the {commodity} to {planet} ({system} system)"),
            {commodity=comm:name(), planet=misplanet:name(),
               system=missys:name()}),
   }
   misn.osdCreate(_("Commodity Delivery"), osd_msg)

   -- Don't need the mission marker until after the goods are obtained.
   misn.markerRm(marker)
   marker = nil

   hook.land("land")
   hook.safe("safe_updateCommod")
end


function land()
   local amount = pilot.cargoHas(player.pilot(), chosen_comm)
   local reward = amount * price

   if planet.cur() == misplanet and amount > 0 then
      local txt = fmt.f(cargo_land[rnd.rnd(1, #cargo_land)],
            {commodity=_(chosen_comm), credits=fmt.credits(reward)})
      tk.msg(cargo_land_title, txt)
      pilot.cargoRm(player.pilot(), chosen_comm, amount)
      player.pay(reward)
      update_active_runs(-1)
      misn.finish(true)
   end
end


function safe_updateCommod()
   if pilot.cargoHas(player.pilot(), chosen_comm) > 0 then
      misn.osdActive(2)
      if marker == nil then
         marker = misn.markerAdd(missys, "computer", misplanet)
      end
   else
      misn.osdActive(1)
      misn.markerRm(marker)
      marker = nil
   end

   hook.safe("safe_updateCommod")
end


function abort()
   update_active_runs(-1)
end

