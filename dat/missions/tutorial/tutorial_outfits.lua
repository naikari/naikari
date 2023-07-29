--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Outfitter Tutorial">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>1</priority>
  <chance>100</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
  <done>Teddy Bears from Space</done>
 </avail>
 <notes>
  <campaign>Tutorial</campaign>
 </notes>
</mission>
--]]
--[[

   Outfitter Tutorial

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

   MISSION: Outfitter tutorial
   DESCRIPTION:
      Player is asked to deliver cargo, but does not have enough cargo
      space to do so, leading to the mission-giver explaining how to add
      a cargo pod.

--]]

local fmt = require "fmt"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"
require "cargo_common"


ask_text = _([[The woman smiles as you approach her. "Well met," she says. "I believe you are a pilot, yes? I have a job for you, if you are interested. Just a cargo delivery, and it's important enough that I'm willing to pay {credits} for it. Well, does that interest you?"]])

accept_text = _([["I'm glad to hear it! My name is Terra, by the way." You introduce yourself as well. "Ah, I've heard that name before. Why, as it happens, I believe you took a personal mission from my company's founder, Reynir. He's retired now, but he spoke quite fondly about his experience with you. Pleased to finally meet you, {player}!

"{amount_description} We'll just load that onto your ship and you can drop it off at {planet} in the {system} system!"]])

nospace_text = _([[You notice your ship's cargo capacity isn't enough to carry out the delivery, so you sheepishly start explaining to Terra that you won't be able to accept the mission after all. Terra, however, waves her hand to indicate that it isn't a problem. "Not to worry," she reassures. "You're not familiar with how to customize your ship, are you? I happen to know that the outfitter on this planet has Cargo Pods available, so you'll be able to take the mission no problem. Here, I'll show you! To start with, click on the #bOutfits tab#0 to go to the outfitter." She proceeds to the outfitter ahead of you.]])

outfits_text = _([[You find Terra waiting for you. She waves you over. "Hello again, {player}! This is the outfitter," she explains. "You can buy all kinds of improvements for your ship here. I'm not a pilot myself, but I understand many pilots spend a lot of time customizing and improving their ships. Let's see, we're looking for the Cargo Pod outfit. You can find it more easily either by using the category tabs, or by using the filter box to search for it by name. In any case, once you locate it, select the #bCargo Pod#0 entry from the list and click on the #bBuy button#0, please."]])

buy_text = _([["See, easy, right? Of course, that just adds the Cargo Pod to your outfits list. It won't do much good unless you actually equip it. Here, let's go to the #bEquipment tab#0 so we can do that."]])

equipment_text = _([["See, here's where you can change what's actually equipped to your ship. Go ahead and equip the Cargo Pod, and then we can proceed to load the cargo!"]])

load_cargo_text = _([[After verifying that your ship has enough cargo space, Terra pushes some buttons on her wrist computer and before you know it, the cargo is loaded onto your ship. "There we go, all set, {player}," Terra remarks. "Just deliver it to {planet} in the {system} system and my agents will deliver your payment." She shakes your hand and leaves, presumably to take care of some other matters.]])

finish_text = _([[As your ship approaches the hangar, you see Terra's agents already waiting for you. When the landing finishes, they quickly get to work unloading the cargo. After tallying it and making sure everything is in order, the leader of the group approaches you with a smile and hands you a credit chip with the promised payment.]])

misn_desc = _("A businesswoman named Terra has hired you to deliver some cargo for her.")
misn_log = _([[You met a businesswoman named Terra and delivered some cargo for her.]])

cargo_always_available = true


function create()
   -- Note: This mission makes no system claims.

   -- Calculate the route, distance, jumps, risk of piracy, and cargo to take
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   if destplanet == nil then
      misn.finish(false)
   end

   -- Outfitter must be available.
   if not planet.cur():services()["outfits"] then
      misn.finish(false)
   end

   cargopod = outfit.get("Cargo Pod")

   -- Player must be able to afford a cargo pod.
   if player.credits() < cargopod:price() then
      misn.finish(false)
   end

   -- Cargo pod must be available to purchase.
   local cargopod_available = false
   for i, o in ipairs(planet.cur():outfitsSold()) do
      if outfit.get(o) == cargopod then
         cargopod_available = true
         break
      end
   end
   if not cargopod_available then
      misn.finish(false)
   end

   -- Set a default cargo if none chosen.
   if cargo == nil then
      cargo = "Luxury Goods"
   end
   
   credits = 300000
   talked = false

   misn.setNPC(_("A well-dressed woman"),
         "neutral/unique/terra.png",
         _("You see a woman in a suit and tie who seems to be in search of a suitable pilot."))
end


function accept()
   if tk.yesno("", fmt.f(ask_text, {credits=fmt.credits(credits)})) then
      -- If the player is unable to equip a cargo pod, assume they don't
      -- need the tutorial and make the amount fit in their current
      -- cargo capacity. Otherwise, make sure the player doesn't have
      -- enough capacity to proceed.
      local cargofree = player.pilot():cargoFree()
      amount = cargofree
      if player.pilot():outfitAdd(cargopod) > 0 then
         player.pilot():outfitRm(cargopod)
         amount = cargofree + 5
      end

      local amount_description = fmt.f(
            n_("I just need you to deliver {amount} kt of {cargotype}.",
               "I just need you to deliver {amount} kt of {cargotype}.",
               amount),
            {amount=fmt.number(amount), cargotype=_(cargo)})
      tk.msg("", fmt.f(accept_text,
            {player=player.name(), amount_description=amount_description,
               planet=destplanet:name(), system=destsys:name()}))

      misn.accept()

      misn.setTitle(_("Terra's Cargo"))
      misn.setReward(fmt.credits(credits))
      misn.setDesc(misn_desc)

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system)"),
               {planet=destplanet:name(), system=destsys:name()}),
      }

      if amount > cargofree then
         tk.msg("", nospace_text)

         osd_desc = {
            _("Go to the Outfits tab"),
            _("Buy a Cargo Pod"),
            _("Go to the Equipment tab"),
            fmt.f(n_("Equip the Cargo Pod onto your ship to give it a free cargo capacity of at least {amount} kt",
                     "Equip the Cargo Pod onto your ship to give it a free cargo capacity of at least {amount} kt",
                     amount),
                  {amount=fmt.number(amount)}),
            fmt.f(_("Land on {planet} ({system} system)"),
                  {planet=destplanet:name(), system=destsys:name()}),
         }

         leave_hook = hook.takeoff("leave")
         land_outfits_hook = hook.land("land_outfits", "outfits")
      else
         misn.cargoAdd(cargo, amount)
         tk.msg("", fmt.f(load_cargo_text,
               {player=player.name(), planet=destplanet:name(),
                  system=destsys:name()}))
         misn.markerAdd(destsys, "low", destplanet)
         hook.land("land_delivery")
      end

      misn.osdCreate(_("Terra's Cargo"), osd_desc)
   else
      misn.finish()
   end
end


function land_outfits()
   hook.rm(land_outfits_hook)
   tk.msg("", fmt.f(outfits_text, {player=player.name()}))
   misn.osdActive(2)
   buy_hook = hook.outfit_buy("outfit_buy")
end


function outfit_buy(outfit_name, quantity)
   if outfit_name == "Cargo Pod" then
      hook.rm(buy_hook)
      tk.msg("", buy_text)
      misn.osdActive(3)
      land_equipment_hook = hook.land("land_equipment", "equipment")
   end
end


function land_equipment()
   hook.rm(land_equipment_hook)
   tk.msg("", equipment_text)
   misn.osdActive(4)
   hook.safe("safe_checkdone")
end


function safe_checkdone()
   if player.pilot():cargoFree() >= amount then
      misn.cargoAdd(cargo, amount)
      tk.msg("", fmt.f(load_cargo_text,
            {player=player.name(), planet=destplanet:name(),
               system=destsys:name()}))
      misn.osdActive(5)
      misn.markerAdd(destsys, "low", destplanet)
      hook.rm(leave_hook)
      hook.land("land_delivery")
   else
      hook.safe("safe_checkdone")
   end
end


function land_delivery()
   if planet.cur() == destplanet then
      tk.msg("", finish_text)
      player.pay(credits)
      addMiscLog(misn_log)
      misn.finish(true)
   end
end


function leave()
   misn.finish(false)
end
