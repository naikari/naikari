--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Escort Handler">
 <trigger>load</trigger>
 <chance>100</chance>
 <flags>
  <unique />
 </flags>
</event>
--]]
--[[

   Escort Handler Event

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

   This event runs constantly in the background and manages escorts
   hired from the bar, including generating NPCs at the bar and managing
   escort creation and behavior in space.

--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "pilot/generic"
require "pilot/pirate"
require "events/tutorial/tutorial_common"


tutorial_text = _([[Captain T. Practice pipes up. "Ah, it looks like there's pilots available for hire here at the bar! Let me explain: throughout the galaxy, there are many pilots who seek to work as escorts for other pilots, whether for experience or just to make good money. Having escorts can really make a lot of missions easier for you.

"I would recommend at least talking to any pilots you find and seeing if you might want to hire them to join your fleet. Each pilot has a deposit that you have to pay up-front, and a royalty, which is a percentage of your mission earnings that you have to pay them whenever you get paid for a mission.

"Of course, do make sure that your ship is able to defend itself if caught without escorts as your first priority; being alone and able to defend yourself is probably better than depending on other pilots! You should also try to pick pilots that can keep up with your ship have good synergy with the rest of your fleet."]])
tutorial_log = _([[Pilots which are available for hire can be found at the Spaceport Bar. Each pilot has a deposit you have to pay up-front, and a royalty, which is a percentage of your mission earnings you have to pay them every time you complete a mission. Each pilot is different, so you should try to pick pilots that will work well for you as a fleet.]])

npctext = {}
npctext[1] = _([["Hi there! I'm looking to get some piloting experience. Here are my credentials. Would you be interested in hiring me?"]])
npctext[2] = _([["Hello! I'm looking to join someone's fleet. Here's my credentials. What do you say, would you like me on board?"]])
npctext[3] = _([["Hi! You look like you could use a pilot! I'm available and charge some of the best rates in the galaxy, and I promise you I'm perfect for the job! Here's my info. Well, what do you think? Would you like to add me to your fleet?"]])

credentials = _([[
Pilot name: %s
Ship: %s
Deposit: %s
Royalty: %.1f%% of mission earnings

Money: %s
Current total royalties: %.1f%% of mission earnings]])

pilot_action_text = _([[Would you like to do something with this pilot?

Pilot credentials:]])


function create ()
   lastplanet = nil
   lastsys = system.cur()
   npcs = {}
   escorts = {}
   escorts["__save"] = true

   hook.land("land")
   hook.load("land")
   hook.land("land_bar", "bar")
   hook.jumpout("jumpout")
   hook.enter("enter")
   hook.pay("pay")
end


function createPilotNPCs ()
   local ship_choices = {
      { ship = "Llama", royalty = 0.05 },
      { ship = "Hyena", royalty = 0.1 },
      { ship = "Shark", royalty = 0.15 },
      { ship = "Vendetta", royalty = 0.2 },
      { ship = "Lancelot", royalty = 0.2 },
      { ship = "Ancestor", royalty = 0.25 },
      { ship = "Admonisher", royalty = 0.35 },
      { ship = "Phalanx", royalty = 0.35 },
      { ship = "Pacifier", royalty = 0.5 },
      { ship = "Vigilance", royalty = 0.5 },
   }
   local num_pilots = rnd.rnd(0, 5)
   local fac = faction.get("Mercenary")
   local def_ai = "mercenary"
   local name_func = pilot_name
   local portrait_arg = nil

   local pf = planet.cur():faction()
   if pf == faction.get("Pirate") then
      ship_choices = {
         { ship = "Hyena", royalty = 0.1 },
         { ship = "Pirate Shark", royalty = 0.15 },
         { ship = "Pirate Vendetta", royalty = 0.2 },
         { ship = "Pirate Ancestor", royalty = 0.25 },
         { ship = "Pirate Admonisher", royalty = 0.35 },
         { ship = "Pirate Phalanx", royalty = 0.35 },
      }
      fac = faction.get("Pirate")
      def_ai = "pirate"
      name_func = pirate_name
      portrait_arg = "Pirate"
   elseif pf == faction.get("FLF") then
      ship_choices = {
         { ship = "Hyena", royalty = 0.1 },
         { ship = "Vendetta", royalty = 0.2 },
         { ship = "Lancelot", royalty = 0.2 },
         { ship = "Ancestor", royalty = 0.25 },
         { ship = "Pacifier", royalty = 0.5 },
      }
      fac = faction.get("FLF")
      def_ai = "flf"
      portrait_arg = "FLF"
   elseif pf == faction.get("Thurion") then
      ship_choices = {
         { ship = "Thurion Ingenuity", royalty = 0.15 },
         { ship = "Thurion Scintillation", royalty = 0.25 },
         { ship = "Thurion Virtuosity", royalty = 0.35 },
         { ship = "Thurion Apprehension", royalty = 0.5 },
      }
      fac = faction.get("Thurion")
      def_ai = "thurion"
      portrait_arg = "Thurion"
   elseif planet.cur():faction() == faction.get("Proteron") then
      fac = faction.get("Proteron")
      def_ai = "proteron"
      portrait_arg = "Proteron"
   end

   if fac == nil or fac:playerStanding() < 0 then
      return
   end

   for i=1, num_pilots do
      local newpilot = {}
      local shipchoice = ship_choices[rnd.rnd(1, #ship_choices)]
      local p = pilot.add(shipchoice.ship, fac)
      local n, deposit = p:ship():price()
      newpilot.outfits = {}
      newpilot.outfits["__save"] = true

      for j, o in ipairs(p:outfits()) do
         deposit = deposit + o:price()
         newpilot.outfits[#newpilot.outfits + 1] = o:nameRaw()
      end

      deposit = math.floor((deposit + 0.2*deposit*rnd.sigma()) / 2)
      if deposit <= player.credits() then
         newpilot.ship = shipchoice.ship
         newpilot.deposit = deposit
         newpilot.royalty = (
               shipchoice.royalty + 0.1*shipchoice.royalty*rnd.sigma())
         newpilot.name = name_func()
         newpilot.portrait = portrait.get(portrait_arg)
         newpilot.faction = fac:nameRaw()
         newpilot.def_ai = def_ai
         newpilot.approachtext = npctext[rnd.rnd(1, #npctext)]
         local id = evt.npcAdd(
               "approachPilot", _("Pilot"), newpilot.portrait,
               _("This pilot seems to be looking for work."), 90)
         npcs[id] = newpilot
      end
   end

   
end


function getTotalRoyalties ()
   local royalties = 0
   for i, edata in ipairs(escorts) do
      if edata.alive then
         royalties = royalties + edata.royalty
      end
   end
   return royalties
end


function land ()
   lastplanet = planet.cur()
   npcs = {}
   if standing_hook ~= nil then
      hook.rm(standing_hook)
      standing_hook = nil
   end

   -- Clean up dead escorts so it doesn't build up, and create NPCs for
   -- existing escorts.
   local new_escorts = {}
   new_escorts["__save"] = true
   for i, edata in ipairs(escorts) do
      if edata.alive then
         local j = #new_escorts + 1
         edata.pilot = nil
         edata.temp = nil
         edata.armor = nil
         edata.shield = nil
         edata.stress = nil
         edata.energy = nil
         spawnNPC(edata)
         new_escorts[j] = edata
      end
   end
   escorts = new_escorts

   if #escorts <= 0 then
      evt.save(false)
   end

   -- No sense continuing is there is no bar on the planet.
   if not planet.cur():services()["bar"] then return end

   -- Create NPCs for pilots you can hire.
   createPilotNPCs()
end


function land_bar ()
   if next(npcs) ~= nil and not var.peek("tutorial_escorts_done") then
      if var.peek("_tutorial_passive_active") then
         tk.msg("", tutorial_text)
      end
      addTutLog(tutorial_log, N_("Escorts"))

      var.push("tutorial_escorts_done", true)
   end
end


function jumpout ()
   for i, edata in ipairs(escorts) do
      if edata.alive then
         if edata.pilot ~= nil and edata.pilot:exists() then
            edata.temp = edata.pilot:temp()
            edata.armor, edata.shield, edata.stress = edata.pilot:health()
            edata.energy = edata.pilot:energy()
            edata.pilot:rm()
         else
            edata.temp = nil
            edata.armor = nil
            edata.shield = nil
            edata.stress = nil
            edata.energy = nil
         end
         edata.pilot = nil
      else
         edata.alive = false
      end
   end
end


function enter ()
   local spawnpoint
   if lastsys == system.cur() then
      spawnpoint = lastplanet
   else
      spawnpoint = player.pos()
      for i, sys in ipairs(lastsys:adjacentSystems(true)) do
         if sys == system.cur() then
            spawnpoint = lastsys
         end
      end
   end
   lastsys = system.cur()

   local vname = string.format("_escort_disable_%s", system.cur():nameRaw())
   if var.peek(vname) then
      -- Disabling escorts for this system has been requested.
      var.pop(vname)
      return
   end

   if standing_hook == nil then
      standing_hook = hook.standing("standing")
   end

   hook.pilot(player.pilot(), "attacked", "player_attacked")

   local pp = player.pilot()
   for i, edata in ipairs(escorts) do
      if edata.alive and not edata.docked then
         local f = faction.get(edata.faction)

         edata.pilot = pilot.add(edata.ship, f, spawnpoint, edata.name,
               {naked=true})
         for j, o in ipairs(edata.outfits) do
            edata.pilot:outfitAdd(o)
         end
         edata.pilot:fillAmmo()
         edata.pilot:setFriendly()

         local temp = 250
         local armor = 100
         local shield = 100
         local stress = 0
         local energy = 100
         if edata.temp ~= nil then
            temp = edata.temp
         end
         if edata.armor ~= nil then
            armor = edata.armor
         end
         if edata.shield ~= nil then
            shield = edata.shield
         end
         if edata.stress ~= nil then
            -- Limit this to 99 so we don't have the weirdness of a
            -- disabled ship warping in.
            stress = math.min(edata.stress, 99)
         end
         if edata.energy ~= nil then
            energy = edata.energy
         end
         edata.pilot:setTemp(temp, true)
         edata.pilot:setHealth(armor, shield, stress)
         edata.pilot:setEnergy(energy)
         edata.pilot:setFuel(true)

         if f == nil or f:playerStanding() >= 0 then
            edata.pilot:changeAI("escort_player")
            edata.pilot:memory().carrier = false
            edata.pilot:setLeader(pp)
            edata.pilot:setVisplayer(true)
            edata.pilot:setInvincPlayer(true)
            edata.pilot:setNoClear(true)
            hook.pilot(edata.pilot, "death", "pilot_death", i)
            hook.pilot(edata.pilot, "attacked", "pilot_attacked", i)
            hook.pilot(edata.pilot, "hail", "pilot_hail", i)
         else
            edata.alive = false
         end
      end
   end
end


function pay(amount, reason)
   if amount <= 0 or reason == "adjust" then return end

   local royalty = 0
   for i, edata in ipairs(escorts) do
      if edata.alive and edata.royalty then
         royalty = royalty + amount * edata.royalty
      end
   end
   player.pay(-royalty, nil, true)
end


function standing()
   for i, edata in ipairs(escorts) do
      if edata.alive and edata.faction ~= nil and edata.pilot ~= nil
            and edata.pilot:exists() then
         local f = faction.get(edata.faction)
         if f ~= nil and f:playerStanding() < 0 then
            pilot_disbanded(edata)
            player.msg(fmt.f(
               _("{escort} has left your wing because you now have a negative standing with the {faction} faction."),
               {escort=edata.name, faction=f:name()}))
         end
      end
   end
end


-- Pilot is no longer employed by the player
function pilot_disbanded(edata)
   edata.alive = false
   local p = edata.pilot
   if p ~= nil and p:exists() then
      if edata.def_ai ~= nil then
         p:changeAI(edata.def_ai)
      else
         p:changeAI("mercenary")
      end
      p:setLeader(nil)
      p:setVisplayer(false)
      p:setInvincPlayer(false)
      p:setNoClear(false)
      p:setFriendly(false)
      p:hookClear()
   end
end


-- Pilot was hailed by the player
function pilot_hail(p, arg)
   local edata = escorts[arg]
   if not edata.alive then
      return
   end

   player.commClose()
   local credits, scredits = player.credits(2)
   local approachtext = (
         pilot_action_text .. "\n\n" .. credentials:format(
            edata.name, edata.ship, fmt.credits(edata.deposit),
            edata.royalty * 100, scredits, getTotalRoyalties() * 100))

   local n, s = tk.choice("", approachtext, _("Fire pilot"), _("Do nothing"))

   if s == _("Fire pilot") and tk.yesno("", fmt.f(
            _("Are you sure you want to fire {pilot}? This cannot be undone."),
            {pilot=edata.name})) then
      pilot_disbanded(edata)
      player.msg(fmt.f(_("You have fired {pilot}."), {pilot=edata.name}))
   end
end


function player_attacked(p, attacker, dmg)
   -- Must have an attacker
   if attacker == nil or not attacker:exists() then
      return
   end

   for i, edata in ipairs(escorts) do
      if attacker == edata.pilot then
         if edata.alive then
            pilot_disbanded(edata)
            player.msg(fmt.f(
                  _("{pilot} has left your wing and turned against you!"),
                  {pilot=edata.name}))
         end
         return
      end
   end
end


-- Check if player attacked his own escort
function pilot_attacked(p, attacker, dmg, arg)
   -- Must have an attacker
   if attacker == nil or not attacker:exists() then
      return
   end

   local pp = player.pilot()
   if attacker == pp or attacker:leader() == pp then
      -- Since all the escorts will turn on the player, we might as well
      -- just have them all disband at once and attack.
      for i, edata in ipairs(escorts) do
         pilot_disbanded(edata)
         edata.pilot:setHostile()
      end
      player.msg(_("You have caused infighting within your wing, causing all of your escorts to quit and turn on you in retaliation!"))
   end
end


-- Escort got killed
function pilot_death(p, attacker, arg)
   escorts[arg].alive = false
end


function spawnNPC(edata)
   local name = edata.name
   if edata.docked then
      name = fmt.f(_("{pilot} [docked]"), {pilot=edata.name})
   end

   local id = evt.npcAdd("approachEscort", name, edata.portrait,
         _("This is one of the pilots currently under your wing."), 80)
   npcs[id] = edata
end


function approachEscort(npc_id)
   local edata = npcs[npc_id]
   if edata == nil then
      evt.npcRm(npc_id)
      return
   end

   local credits, scredits = player.credits(2)
   local approachtext = (
         pilot_action_text .. "\n\n" .. credentials:format(
            edata.name, edata.ship, fmt.credits(edata.deposit),
            edata.royalty * 100, scredits, getTotalRoyalties() * 100))

   local dock_choice = _("Dock pilot")
   if edata.docked then
      dock_choice = _("Undock pilot")
   end

   local n, s = tk.choice("", approachtext,
         dock_choice, _("Fire pilot"), _("Do nothing"))
   if s == _("Dock pilot") then
      if tk.yesno("", fmt.f(
               _("Are you sure you want to dock {pilot}? They will still be paid royalties, but will not join you in space until you undock them."),
               {pilot=edata.name})) then
         edata.docked = true
         evt.npcRm(npc_id)
         npcs[npc_id] = nil
         spawnNPC(edata)
      end
   elseif s == _("Undock pilot") then
      edata.docked = false
      evt.npcRm(npc_id)
      npcs[npc_id] = nil
      spawnNPC(edata)
   elseif s == _("Fire pilot") then
      if tk.yesno("", fmt.f(
               _("Are you sure you want to fire {pilot}? This cannot be undone."),
               {pilot=edata.name})) then
         evt.npcRm(npc_id)
         npcs[npc_id] = nil
         -- We just set alive to false for now and let them get cleaned
         -- up next time we land.
         edata.alive = false
      end
   end
end


function approachPilot(npc_id)
   local pdata = npcs[npc_id]
   if pdata == nil then
      evt.npcRm(npc_id)
      return
   end

   local credits, scredits = player.credits(2)
   local cstr = credentials:format(
         pdata.name, pdata.ship, fmt.credits(pdata.deposit),
         pdata.royalty * 100, scredits, getTotalRoyalties() * 100)

   if tk.yesno("", pdata.approachtext .. "\n\n" .. cstr) then
      if pdata.deposit and pdata.deposit > player.credits() then
         tk.msg("", _("You don't have enough credits to pay for this pilot's deposit."))
         return
      end
      if getTotalRoyalties() + pdata.royalty > 1 then
         if not tk.yesno("", _("Hiring this pilot will lead to you paying more in royalties than you earn from missions, meaning you will lose credits when doing missions. Are you sure you want to hire this pilot?")) then
            return
         end
      end

      if pdata.deposit then
         player.pay(-pdata.deposit, "adjust")
      end

      local i = #escorts + 1
      pdata.alive = true
      escorts[i] = pdata
      evt.npcRm(npc_id)
      npcs[npc_id] = nil
      spawnNPC(pdata)
      evt.save(true)
   end
end

