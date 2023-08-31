--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Ship Stealing">
 <avail>
  <priority>40</priority>
  <cond>planet.cur():blackmarket() or (faction.playerStanding("Pirate") &gt;= 0 and player.numOutfit("Mercenary License") &gt; 0)</cond>
  <chance>810</chance>
  <location>Bar</location>
  <faction>Pirate</faction>
  <faction>Independent</faction>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[

   Ship Stealing

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

   A mission which allows the player to steal a ship by disabling it.
   Replacement for the old ship stealing mission.

--]]

local fmt = require "fmt"
local pilotname = require "pilotname"
local portrait = require "portrait"
local mh = require "misnhelper"
require "missions/pirate/common"
require "jumpdist"


npc_desc = _("A pirate informer sits at the bar. Perhaps they might have some useful information.…")
misn_desc = _("You and a pirate informer have conspired to steal a vulnerable {shiptype} in the {system} system. You are to disable and board the ship, then meet up with the pirate at a place of your choosing.")

ask_text = _([[You approach the pirate informer. "I have a fantastic offer for you," they say. "There's a practically defenseless {shiptype} just waiting to be… taken off its pilot's hands. For just {credits}, I'll tell you the ship's location and even help you get the ship! Well? What do you say?"]])

explain_text = _([[You pay the informant. "Heh heh, thanks! The ship is being piloted by someone called {pilot}. It can be found in the {system} system and it's been damaged by a failed pirate attack. All you need to do is locate the ship, disable it, board it, and let me take care of sneaking it out of the system. Don't forget to equip ion cannons or Medusa missiles or something like that so you don't accidentally blow the ship up. We'll meet up on a nearby planet somewhere after that; I'll let you choose which one."]])

nomoney_text = _([["You don't even have enough money! Don't waste my time!"]])

offer_newtarget_free_text = _([[As you prepare to board your target, the pirate informer who you paid {credits} to help you steal the {shiptype} stops you. "Wait a moment, friend. I have an offer just for you! For no additional cost, I can steal this ship for you instead of the target we were originally going to go after. Well? What do you say?"]])

offer_newtarget_text = _([[As you prepare to board your target, the pirate informer who you paid {credits} to help you steal the {shiptype} stops you. "Wait a moment, friend. I have an offer just for you! For just {extracredits} more, I can steal this ship for you instead of the target we were originally going to go after. Well? What do you say?"]])

subdue_text = {
   _("You successfully infiltrate the ship. The pirate informer takes control of the ship and prepares to make the getaway."),
   _("You and the pirate easily make your way past the ship's pathetic security system, and the pirate takes control of the ship that will soon be yours."),
   _("You and the pirate informer have a laugh at how easy infiltrating the ship was before the pirate informer begins preparations to fly the ship out of the system."),
   _("The crew on this ship gives you a hard time, but you eventually subdue them."),
}

finish_text = _([[You meet back up with the pirate, who delivers the promised ship.]])

-- Messages
ran_msg = _("{pilot} got away.")
died_msg = _("Target ship has been destroyed.")
abandoned_msg = _("You have left the {system} system.")

osd_title = _("Ship Stealing")

-- List of ships that you are never allowed to steal.
forbidden_ships = {
   -- Collective drones
   "Drone", "Heavy Drone",

   -- Za'lek drones
   "Za'lek Scout Drone", "Za'lek Light Drone", "Za'lek Heavy Drone",
   "Za'lek Bomber Drone",

   -- Stations
   "Sindbad", "Raelid Outpost", "Raglan Outpost",
}


function create()
   paying_faction = faction.get("Pirate")

   local target_factions = {
      "Civilian",
      "Dvaered",
      "Empire",
      "Frontier",
      "Goddard",
      "Independent",
      "Sirius",
      "Soromid",
      "Trader",
      "Za'lek",
   }

   local systems = getsysatdistance(system.cur(), 1, 6,
      function(s)
         for i, j in ipairs(target_factions) do
            local p = s:presences()[j]
            if p ~= nil and p > 0 then
               return true
            end
         end
         return false
      end, nil, true)

   if #systems == 0 then
      -- No enemy presence nearby
      misn.finish(false)
   end

   missys = systems[rnd.rnd(1, #systems)]

   target_faction = nil
   while target_faction == nil and #target_factions > 0 do
      local i = rnd.rnd(1, #target_factions)
      local p = missys:presences()[target_factions[i]]
      if p ~= nil and p > 0 then
         target_faction = target_factions[i]
      else
         for j = i, #target_factions do
            target_factions[j] = target_factions[j + 1]
         end
      end
   end

   if target_faction == nil then
      -- Should not happen, but putting this here just in case.
      misn.finish(false)
   end

   jumps_permitted = system.cur():jumpDist(missys, true) + rnd.rnd(3, 10)
   if rnd.rnd() < 0.05 then
      jumps_permitted = jumps_permitted - 1
   end

   name = pilotname.generic()
   bounty_setup()

   local portrait_f = "Thief"
   if planet.cur():faction() == faction.get("Pirate") then
      portrait_f = "Pirate"
   end

   misn.setNPC(_("Pirate Informer"), portrait.get(portrait_f), npc_desc)
end


function accept()
   local t = fmt.f(ask_text,
         {shiptype=_(shiptype), credits=fmt.credits(credits)})
   if not tk.yesno("", t) then
      misn.finish()
      return
   end

   if player.credits() < credits then
      tk.msg("", nomoney_text)
      misn.finish()
      return
   end

   player.pay(-credits, "adjust")

   tk.msg("", fmt.f(explain_text, {system=missys:name(), pilot=name}))
   misn.accept()

   -- Set mission details
   misn.setTitle(_("Ship Stealing"))
   misn.setDesc(fmt.f(misn_desc, {shiptype=_(shiptype), system=missys:name()}))

   misn.setReward(_("A shiny new ship"))
   marker = misn.markerAdd(missys, "computer")

   local osd_msg = {
      fmt.f(_("Fly to the {system} system"), {system=missys:name()}),
      fmt.f(_("Disable and board {pilot}"), {pilot=name}),
      _("Land on any planet or station"),
   }
   misn.osdCreate(osd_title, osd_msg)

   last_sys = system.cur()
   job_done = false
   soutfits = nil

   jumpin_hook = hook.jumpin("jumpin")
   jumpout_hook = hook.jumpout("jumpout")
   takeoff_hook = hook.takeoff("takeoff")
   board_hook = hook.board("board")
   hook.land("land")
end


function jumpin()
   -- Nothing to do.
   if system.cur() ~= missys then
      return
   end

   local jp = jump.get(system.cur(), last_sys)
   local pos = nil
   if jp ~= nil then
      local pos = jump.pos(jp)
      local offset_ranges = {{-5000, -2500}, {2500, 5000}}
      local xrange = offset_ranges[rnd.rnd(1, #offset_ranges)]
      local yrange = offset_ranges[rnd.rnd(1, #offset_ranges)]
      pos = pos + vec2.new(rnd.rnd(xrange[1], xrange[2]),
               rnd.rnd(yrange[1], yrange[2]))
   else
      local r = system.cur():radius()
      pos = vec2.new(rnd.uniform(-r, r), rnd.uniform(-r, r))
   end
   spawn_target(pos)
end


function jumpout ()
   jumps_permitted = jumps_permitted - 1
   last_sys = system.cur()
   if not job_done and last_sys == missys then
      fail(fmt.f(abandoned_msg, {system=last_sys:name()}))
   end
end


function takeoff()
   local r = system.cur():radius()
   local pos = vec2.new(rnd.uniform(-r, r), rnd.uniform(-r, r))
   spawn_target(pos)
end


function land()
   if job_done then
      tk.msg("", finish_text)

      local newship = player.addShip(shiptype, name)
      if soutfits ~= nil then
         player.shipOutfitRm(newship, "all")
         player.shipOutfitRm(newship, "cores")
         for i, o in ipairs(soutfits) do
            player.shipOutfitAdd(newship, o, 1, true)
         end
      end

      -- Give some pirate fame, take away standing from target faction.
      faction.get("Pirate"):modPlayer(1)
      faction.get(target_faction):modPlayerSingle(-1)

      misn.finish(true)
   end
end


function board(target, arg)
   -- Make sure it's not the target we're set to steal anyway
   if target == target_ship then
      return
   end

   -- Make sure the ship isn't forbidden.
   for i, sname in ipairs(forbidden_ships) do
      if sname == target:ship():nameRaw() then
         return
      end
   end

   -- Only offer to steal natural ships.
   if not target:memory().natural then
      return
   end

   -- Make sure another pirate informer didn't just offer to steal the
   -- ship, since getting multiple offers in a row would be annoying.
   if var.peek("board_nosteal") then
      return
   end

   local n, price = target:ship():price()
   for i, o in ipairs(target:outfits()) do
      price = price + o:price()
   end

   local t
   local diff = price - credits
   if diff > player.credits() then
      return
   elseif diff > 0 then
      t = fmt.f(offer_newtarget_text,
            {credits=fmt.credits(credits), shiptype=_(shiptype),
               extracredits=fmt.credits(diff)})
   else
      t = fmt.f(offer_newtarget_free_text,
            {credits=fmt.credits(credits), shiptype=_(shiptype)})
   end

   var.push("board_nosteal", true)
   hook.safe("safe_restoreOffer")

   if not tk.yesno("", t) then
      return
   end

   if diff > 0 then
      player.pay(-diff, "adjust")
   end
   pilot_board(target, player.pilot())
end


function safe_restoreOffer()
   var.pop("board_nosteal")
end


function pilot_board(p, boarder)
   if boarder == player.pilot() then
      player.unboard()
      local t = subdue_text[rnd.rnd(1, #subdue_text)]
      tk.msg("", t)
      succeed()

      -- Pirate takes over the ship
      p:setHostile(false)
      p:setFriendly()
      p:setHilight(false)
      p:setNoDeath()
      p:control()
      p:hyperspace()

      -- Set ship type in case we're boarding a different ship
      shiptype = p:ship():nameRaw()

      -- Store the outfits on the ship
      soutfits = {}
      soutfits["__save"] = true
      for i, o in ipairs(p:outfits()) do
         soutfits[#soutfits + 1] = o
      end
   else
      p:setHilight(false)
      fail(_("Another pilot captured your target."))
   end
end


function pilot_death()
   fail(died_msg)
end


function pilot_jump()
   fail(fmt.f(ran_msg, {pilot=name}))
end


function anti_regen_timer(p)
   if p == nil or not p:exists() then
      return
   end

   local armor, shield, stress, disabled = p:health()
   local energy = p:energy()
   p:setHealth(math.min(armor, 25), shield, stress)
   p:setEnergy(math.min(energy, 50))

   anti_regen_hook = hook.timer(0.1, "anti_regen_timer", p)
end


-- Set up the ship to steal and calculate cost
function bounty_setup()
   local ship_choices = {
      Civilian = {
         "Llama", "Gawain", "Schroedinger", "Hyena",
      },
      Dvaered = {
         "Dvaered Vendetta", "Dvaered Ancestor", "Dvaered Phalanx",
         "Dvaered Vigilance", "Dvaered Goddard",
      },
      Empire = {
         "Empire Shark", "Empire Lancelot", "Empire Admonisher",
         "Empire Pacifier", "Empire Hawking", "Empire Peacemaker",
      },
      Frontier = {
         "Hyena", "Lancelot", "Vendetta", "Ancestor", "Phalanx", "Pacifier",
      },
      Goddard = {
         "Lancelot", "Goddard",
      },
      Independent = {
         "Hyena", "Shark", "Lancelot", "Vendetta", "Ancestor", "Phalanx",
         "Admonisher", "Vigilance", "Pacifier", "Kestrel", "Hawking",
      },
      Sirius = {
         "Sirius Fidelity", "Sirius Shaman", "Sirius Preacher", "Sirius Dogma",
         "Sirius Divinity",
      },
      Soromid = {
         "Soromid Brigand", "Soromid Reaver", "Soromid Marauder",
         "Soromid Odium", "Soromid Nyx", "Soromid Ira", "Soromid Vox",
         "Soromid Arx",
      },
      Trader = {
         "Llama", "Quicksilver", "Koäla", "Mule", "Rhino",
      },
      ["Za'lek"] = {
         "Za'lek Sting", "Za'lek Demon", "Za'lek Mephisto", "Za'lek Diablo",
         "Za'lek Hephaestus",
      },
   }

   local fshiplist = ship_choices[target_faction]

   shiptype = "Schroedinger"
   credits = 10000

   if fshiplist == nil or #fshiplist <= 0 then
      return
   end

   shiptype = fshiplist[rnd.rnd(1, #fshiplist)]

   local n, price = ship.get(shiptype):price()
   credits = price * rnd.uniform(0.4, 0.8)
end


-- Spawn the ship at the location source.
function spawn_target(source)
   if not job_done and system.cur() == missys then
      if jumps_permitted >= 0 then
         misn.osdActive(2)

         target_ship = pilot.add(shiptype, target_faction, source, name)
         target_ship:setHilight()
         target_ship:setNoClear()
         target_ship:setHealth(25, 100)
         target_ship:setEnergy(10)

         local mem = target_ship:memory()
         mem.norun = true
         mem.noleave = true

         -- Lower ammo
         for i, amm in ipairs(target_ship:ammo()) do
            target_ship:outfitRm(amm.name, math.ceil(amm.quantity * 0.6))
         end

         hook.pilot(target_ship, "board", "pilot_board")
         hook.pilot(target_ship, "death", "pilot_death")
         target_jump_hook = hook.pilot(target_ship, "jump", "pilot_jump")
         target_land_hook = hook.pilot(target_ship, "land", "pilot_jump")
         anti_regen_hook = hook.timer(0.1, "anti_regen_timer", target_ship)

         target_ship:taskClear()
      else
         fail(fmt.f(ran_msg, {pilot=name}))
      end
   end
end


-- Succeed the capture, proceed to landing on the planet
function succeed()
   job_done = true
   misn.osdActive(3)
   misn.markerRm(marker)
   hook.rm(jumpin_hook)
   hook.rm(jumpout_hook)
   hook.rm(takeoff_hook)
   hook.rm(board_hook)
   hook.rm(target_jump_hook)
   hook.rm(target_land_hook)
   hook.rm(anti_regen_hook)
end


-- Fail the mission, showing message to the player.
function fail(reason)
   -- Don't show fail message after already failed.
   if failed then
      return
   end

   mh.showFailMsg(reason)

   -- Change objective
   local osd_msg = {
      fmt.f(_("Fly to the {system} system"), {system=missys:name()}),
      _("Disable and board any ship and see if the pirate informer will steal it for you"),
      _("Land on any planet or station"),
   }
   misn.osdCreate(osd_title, osd_msg)
   misn.osdActive(2)
   misn.markerRm(marker)
   hook.rm(jumpin_hook)
   hook.rm(jumpout_hook)
   hook.rm(takeoff_hook)
   hook.rm(board_hook)
   hook.rm(target_jump_hook)
   hook.rm(target_land_hook)
   hook.rm(anti_regen_hook)

   failed = true
end
