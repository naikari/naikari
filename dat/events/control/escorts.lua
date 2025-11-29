--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Escort Handler">
 <trigger>load</trigger>
 <priority>100</priority>
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
local pilotname = require "pilotname"
local portrait = require "portrait"


local npctext = {
   _([["Hi there! I'm looking to get some piloting experience. Here are my credentials. Would you be interested in hiring me?"]]),
   _([["Hello! I'm looking to join someone's fleet. Here's my credentials. What do you say, would you like me on board?"]]),
   _([["Hi! You look like you could use a pilot! I'm available and charge some of the best rates in the galaxy, and I promise you I'm perfect for the job! Here's my info. Well, what do you think? Would you like to add me to your fleet?"]]),
   _([["Ah, you look like you could use a pilot! Well, as it happens, I'm available to fill that need! I promise you my performance won't disappoint, and as you can see from my credentials here, I offer reasonable rates. What do you say, will you take me aboard and boost the power of your fleet today?"]]),
   _([["You need a co-pilot? Well, you're talking to just the one for the job! I have a fantastic track-record, having successfully dispatched hundreds of hostiles in my years of service, and as you can see, my credentials speak for themselves. Are you ready to take me on and bolster your fleet?"]]),
   _([["Hello, friend! If what you're looking for is a reliable pilot, I'm just the one for the job. I promise if you hire me, I'll never let you down. What do you say?"]]),
   _([["Ha, ha, ha! You've a good eye for a good pilot, I see! As you can see from my credentials, my rates can't be beat! Are you ready to bolster your fleet with me today?"]]),
   _([["Do you want your fleet to swell with power? Well, am I just the pilot for you! I can assure you that by adding me to your fleet, you will be nigh-invincible! Will you make a good choice and hire me today?"]]),
}

local pilot_action_text = _([[Would you like to do something with this pilot?

Pilot credentials:]])

local credentials_text = _([[
#nPilot name:#0 {name}
#nShip:#0 {ship}
#nSpeed:#0 {speed} mAU/s
#nDeposit:#0 {deposit}
#nRoyalty:#0 {royalty:.1f}% of earnings

#nYour speed:#0 {plspeed:.0f} mAU/s
#nMoney:#0 {plmoney}
#nCurrent total royalties:#0 {plroyalties:.1f}% of earnings]])

local credentials_refundable_text = _([[
#nPilot name:#0 {name}
#nShip:#0 {ship}
#nSpeed:#0 {speed} mAU/s
#nDeposit:#0 {deposit} ({refundable} refundable)
#nRoyalty:#0 {royalty:.1f}% of earnings

#nYour speed:#0 {plspeed:.0f} mAU/s
#nMoney:#0 {plmoney}
#nCurrent total royalties:#0 {plroyalties:.1f}% of earnings]])

local explain_text = _([["Of course. There are two parts: the deposit, and the royalty.

"The royalty is simply a percentage of your earnings I will take as payment each time you get paid for something like a mission or a bounty hunt. So for example, since my royalty is {royalty:.1f}%, that means if you earn {credits} from a mission while I am employed by you, you will have to pay me {payment}.

"The deposit is paid up-front when you hire me. It's partially refundable if you terminate my employment while landed, with the refund amount based on how much in total I have been paid in royalties. To put it another way, after you terminate my employment, the deposit ensures that you will have paid me at least {deposit} for my services in total, and it also insures my family in the event that I die under your wing."]])


function create ()
   lastplanet = nil
   lastsys = system.cur()
   npcs = {}
   escorts = {}
   escorts["__save"] = true

   hook.land("land")
   hook.load("land")
   hook.jumpout("jumpout")
   hook.enter("enter")
   hook.pay("pay")
end


function createPilotNPCs ()
   local ship_choices = {
      {ship = "Llama", royalty = 0.025, deposit_mod = 1/10},
      {ship = "Hyena", royalty = 0.05, deposit_mod = 1/10},
      {ship = "Shark", royalty = 0.075, deposit_mod = 1/10},
      {ship = "Vendetta", royalty = 0.1, deposit_mod = 1/7},
      {ship = "Lancelot", royalty = 0.1, deposit_mod = 1/7},
      {ship = "Ancestor", royalty = 0.15, deposit_mod = 1/6},
      {ship = "Admonisher", royalty = 0.2, deposit_mod = 1/5},
      {ship = "Phalanx", royalty = 0.2, deposit_mod = 1/5},
      {ship = "Pacifier", royalty = 0.3, deposit_mod = 1/4},
      {ship = "Vigilance", royalty = 0.3, deposit_mod = 1/4},
   }
   local num_pilots = rnd.rnd(0, 5)
   local fac = faction.get("Mercenary")
   local def_ai = "mercenary"
   local name_func = pilotname.generic
   local portrait_func = portrait.get
   local portrait_arg = nil

   local pf = planet.cur():faction()
   local pr = planet.cur():restriction()
   if pf == faction.get("Pirate") then
      ship_choices = {
         {ship = "Hyena", royalty = 0.05, deposit_mod = 1/10},
         {ship = "Pirate Shark", royalty = 0.075, deposit_mod = 1/10},
         {ship = "Pirate Vendetta", royalty = 0.1, deposit_mod = 1/7},
         {ship = "Pirate Ancestor", royalty = 0.15, deposit_mod = 1/6},
         {ship = "Pirate Admonisher", royalty = 0.2, deposit_mod = 1/5},
         {ship = "Pirate Phalanx", royalty = 0.2, deposit_mod = 1/5},
      }
      fac = faction.get("Pirate")
      def_ai = "pirate"
      name_func = pilotname.pirate
      portrait_arg = "Pirate"
   elseif pf == faction.get("FLF") then
      ship_choices = {
         {ship = "Hyena", royalty = 0.05, deposit_mod = 1/10},
         {ship = "Vendetta", royalty = 0.1, deposit_mod = 1/7},
         {ship = "Lancelot", royalty = 0.1, deposit_mod = 1/7},
         {ship = "Ancestor", royalty = 0.15, deposit_mod = 1/6},
         {ship = "Pacifier", royalty = 0.3, deposit_mod = 1/4},
      }
      fac = faction.get("FLF")
      def_ai = "flf"
      portrait_arg = "FLF"
   elseif pr == "emp_mil_restricted" or pr == "emp_mil_omega"
         or pr == "emp_mil_eye" then
      ship_choices = {
         {ship = "Imperial Shark", royalty = 0.075, deposit_mod = 1/10},
         {ship = "Imperial Lancelot", royalty = 0.1, deposit_mod = 1/7},
         {ship = "Imperial Admonisher", royalty = 0.2, deposit_mod = 1/5},
         {ship = "Imperial Pacifier", royalty = 0.3, deposit_mod = 1/4},
      }
      fac = faction.get("Empire")
      def_ai = "empire"
      portrait_func = portrait.getMil
      portrait_arg = "Empire"
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
         table.insert(newpilot.outfits, o:nameRaw())
      end

      local mod = shipchoice.deposit_mod or 0.5
      deposit = math.floor((deposit + 0.2*deposit*rnd.sigma()) * mod)
      if deposit <= player.credits() then
         newpilot.ship = shipchoice.ship
         newpilot.speed = p:stats().speed_max
         newpilot.deposit = deposit
         newpilot.royalty = (
               shipchoice.royalty + 0.1*shipchoice.royalty*rnd.sigma())
         newpilot.name = name_func()
         newpilot.portrait = portrait_func(portrait_arg)
         newpilot.faction = fac:nameRaw()
         newpilot.def_ai = def_ai
         newpilot.approachtext = npctext[rnd.rnd(1, #npctext)]
         local id = evt.npcAdd(
               "approachPilot", _("Pilot for Hire"), newpilot.portrait,
               _("This pilot seems to be looking for work."), 90)
         npcs[id] = newpilot
      end
   end
end


function getCredentials(edata)
   local credits, scredits = player.credits(2)
   local plspeed = player.pilot():stats().speed_max
   local speed
   if edata.speed then
      local color = edata.speed > plspeed and "#0" or "#r!! "
      speed = string.format("%s%.0f#0", color, edata.speed)
   else
      speed = "?"
   end

   if edata.total_paid ~= nil then
      local refund = math.min(math.floor(edata.total_paid / 2), edata.deposit)
      return fmt.f(credentials_refundable_text,
            {name=edata.name, ship=edata.ship, speed=speed,
               deposit=fmt.credits(edata.deposit),
               refundable=fmt.credits(refund),
               royalty=edata.royalty*100,
               plspeed=plspeed, plmoney=scredits,
               plroyalties=getTotalRoyalties()*100})
   else
      return fmt.f(credentials_text,
            {name=edata.name, ship=edata.ship, speed=speed,
               deposit=fmt.credits(edata.deposit), royalty=edata.royalty*100,
               plspeed=plspeed, plmoney=scredits,
               plroyalties=getTotalRoyalties()*100})
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
         edata.pilot = nil
         edata.temp = nil
         edata.armor = nil
         edata.shield = nil
         edata.stress = nil
         edata.energy = nil
         spawnNPC(edata)
         table.insert(new_escorts, edata)
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


function land_bar()
end


function jumpout()
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
      end
   end
end


function enter()
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

         -- For older saves: populate the speed value now.
         if edata.speed == nil then
            edata.speed = edata.pilot:stats().speed_max
         end

         if f == nil or f:playerStanding() >= 0 then
            edata.pilot:setLeader(pp)
            edata.pilot:changeAI("escort")
            local mem = edata.pilot:memory()
            mem.carrier = false
            mem.comm_no = nil
            edata.pilot:setVisplayer(true)
            edata.pilot:setInvincPlayer(true)
            edata.pilot:setNoClear(true)
            hook.pilot(edata.pilot, "death", "pilot_death", i)
            hook.pilot(edata.pilot, "attacked", "pilot_attacked", i)
            hook.pilot(edata.pilot, "hail", "pilot_hail", i)
            hook.pilot(edata.pilot, "board", "pilot_board", i)

            -- Trigger a hook to allow missions to do things with the
            -- escorts.
            naik.hookTrigger("escort_spawn", edata.pilot)
         else
            edata.alive = false
         end
      end
   end
end


function pay(amount, reason)
   if amount <= 0 or reason == "adjust" then
      return
   end

   local plcredits = player.credits()
   local royalty = 0
   local paid_escorts = {}
   for i, edata in ipairs(escorts) do
      if edata.alive and edata.royalty then
         local this_royalty = amount * edata.royalty
         royalty = royalty + this_royalty
         if edata.total_paid == nil then
            edata.total_paid = 0
         end
         edata.total_paid = edata.total_paid + this_royalty
         paid_escorts[#paid_escorts + 1] = edata
      end
   end
   player.pay(-royalty, nil, true)

   -- If the player failed to pay the full royalty, cause an escort to
   -- disband.
   if plcredits < royalty and rnd.rnd() < 0.5 and #paid_escorts > 0 then
      local edata = paid_escorts[rnd.rnd(1, #paid_escorts)]
      pilot_disbanded(edata)
      local s = fmt.f(_("{escort} has left your wing because of your failure to pay the agreed upon royalty."),
            {escort=edata.name})
      if player.isLanded() then
         tk.msg("", s)
      else
         player.msg(s)
      end
   end
end


function standing()
   for i, edata in ipairs(escorts) do
      if edata.alive and edata.faction ~= nil and edata.pilot ~= nil
            and edata.pilot:exists() then
         local f = faction.get(edata.faction)
         if f ~= nil and f:playerStanding() < 0 then
            pilot_disbanded(edata)
            local s =fmt.f(_("{escort} has left your wing because you now have a negative standing with the {faction} faction."),
               {escort=edata.name, faction=f:name()})
            if player.isLanded() then
               tk.msg("", s)
            else
               player.msg(s)
            end
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

   clearNPCs()
end


-- Pilot was hailed by the player
function pilot_hail(p, arg)
   local edata = escorts[arg]
   if not edata.alive then
      return
   end

   player.commClose()
   local approachtext = pilot_action_text .. "\n\n" .. getCredentials(edata)

   local c_fire_pilot = _("&Fire pilot")
   local c_issue_order = _("Issue &Order")
   local c_do_nothing = _("Do &nothing")
   local n, s = tk.choice("", approachtext,
         c_fire_pilot, c_issue_order, c_do_nothing)

   if s == c_fire_pilot and tk.yesno("", fmt.f(
            _("Are you sure you want to fire {pilot}? This cannot be undone and you will not get any of the deposit back."),
            {pilot=edata.name})) then
      pilot_disbanded(edata)
      player.msg(fmt.f(_("You have fired {pilot}."), {pilot=edata.name}))
   elseif s == c_issue_order then
      local c_formation = _("Hold &Formation")
      local c_return = _("&Return To Ship")
      local c_clear = _("Cl&ear Orders")
      local c_cancel = _("&Cancel")
      local n, s = tk.choice(_("Escort Orders"),
            _("Select the order to give to this escort."),
            c_formation, c_return, c_clear, c_cancel)
      if s == c_formation then
         player.pilot():msg(p, "e_hold", 0)
         player.msg(string.format(_("#F%s:#0 Holding formation."), p:name()))
      elseif s == c_return then
         player.pilot():msg(p, "e_return", 0)
         player.msg(string.format(_("#F%s:#0 Returning to ship."), p:name()))
      elseif s == c_clear then
         player.pilot():msg(p, "e_clear", 0)
         player.msg(string.format(_("#F%s:#0 Clearing orders."), p:name()))
      end
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
         if edata.pilot ~= nil and edata.pilot:exists() then
            edata.pilot:setHostile()
         end
      end
      player.msg(_("You have caused infighting within your wing, causing all of your escorts to quit and turn on you in retaliation!"))
   end
end


-- Escort got killed
function pilot_death(p, attacker, arg)
   escorts[arg].alive = false
end


-- Escort got boarded
function pilot_board(p, boarder, arg)
   if boarder ~= player.pilot() then
      return
   end

   local edata = escorts[arg]
   if not edata.alive then
      return
   end

   player.unboard()

   local armor, shield, stress, disabled = p:health()
   if disabled then
      p:setHealth(armor, shield, 0)
      player.msg(fmt.f(_("You have rescued {pilot}."), {pilot=edata.name}))
   end
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


function clearNPCs()
   if not player.isLanded() then
      return
   end

   local dead_npcs = {}
   for id, edata in pairs(npcs) do
      if not edata.alive then
         dead_npcs[#dead_npcs + 1] = id
      end
   end

   for i, id in ipairs(dead_npcs) do
      evt.npcRm(id)
      npcs[id] = nil
   end
end


function approachEscort(npc_id)
   local edata = npcs[npc_id]
   if edata == nil then
      evt.npcRm(npc_id)
      return
   end

   local approachtext = pilot_action_text .. "\n\n" .. getCredentials(edata)

   local c_dock = _("&Dock pilot")
   local c_undock = _("Un&dock pilot")
   local c_fire = _("&Fire pilot")
   local c_do_nothing = _("Do &nothing")
   local dock_choice = c_dock
   if edata.docked then
      dock_choice = c_undock
   end
   local n, s = tk.choice("", approachtext,
         dock_choice, c_fire, c_do_nothing)

   if s == c_dock then
      if tk.yesno("", fmt.f(
               _("Are you sure you want to dock {pilot}? They will still be paid royalties, but will not join you in space until you undock them."),
               {pilot=edata.name})) then
         edata.docked = true
         evt.npcRm(npc_id)
         npcs[npc_id] = nil
         spawnNPC(edata)
      end
   elseif s == c_undock then
      edata.docked = false
      evt.npcRm(npc_id)
      npcs[npc_id] = nil
      spawnNPC(edata)
   elseif s == c_fire then
      local paid = edata.total_paid or 0
      local refund = math.floor(paid / 2)
      local deposit_s
      if refund >= edata.deposit then
         deposit_s = fmt.f(
               _("You will be refunded the full {deposit} deposit."),
               {deposit=fmt.credits(edata.deposit)})
      elseif refund > 0 then
         deposit_s = fmt.f(
               _("You will be refunded {refund} of the {deposit} deposit."),
               {refund=fmt.credits(refund),
                  deposit=fmt.credits(edata.deposit)})
      else
         deposit_s = fmt.f(
               _("You will not be refunded any of the {deposit} deposit."),
               {deposit=fmt.credits(edata.deposit)})
      end

      if tk.yesno("", fmt.f(
               _("Are you sure you want to fire {pilot}? This cannot be undone. {deposit_sentence}"),
               {pilot=edata.name, deposit_sentence=deposit_s})) then
         evt.npcRm(npc_id)
         npcs[npc_id] = nil
         -- We just set alive to false for now and let them get cleaned
         -- up next time we land.
         edata.alive = false
         player.pay(math.min(refund, edata.deposit), "adjust")
      end
   end
end


function approachPilot(npc_id)
   local pdata = npcs[npc_id]
   if pdata == nil then
      evt.npcRm(npc_id)
      return
   end

   local cstr = getCredentials(pdata)

   local hire = false
   local c_hire = _("&Hire pilot")
   local c_explain_rates = _("Explain &rates")
   local c_do_nothing = _("Do &nothing")
   local n, s
   repeat
      n, s = tk.choice("", pdata.approachtext .. "\n\n" .. cstr,
            c_hire, c_explain_rates, c_do_nothing)
      if s == c_hire then
         hire = true
      elseif s == c_explain_rates then
         local credits = 100000
         local payment = credits * pdata.royalty
         tk.msg("", fmt.f(explain_text,
               {credits=fmt.credits(credits), payment=fmt.credits(payment),
                  royalty=pdata.royalty*100,
                  deposit=fmt.credits(pdata.deposit)}))
      end
   until s ~= c_explain_rates

   if hire then
      if pdata.deposit and pdata.deposit > player.credits() then
         tk.msg("", _("You don't have enough credits to pay for this pilot's deposit."))
         return
      end
      if getTotalRoyalties() + pdata.royalty > 1 then
         if not tk.yesno("", _("Hiring this pilot will lead to you paying more in royalties than you earn, meaning you will lose credits any time you get paid. Are you sure you want to hire this pilot?")) then
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

