--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Warlords battle">
 <trigger>enter</trigger>
 <chance>20</chance>
 <cond>system.cur():faction() == faction.get("Coälition") and not player.evtActive("Warlords battle")</cond>
</event>
--]]
--  A battle between two Coälition warlords. The player can join one of them and get a reward

local fmt = require "fmt"
local fleet = require "fleet"
require "proximity"
local formation = require "formation"


local explain_text = _([["Hey, you," the captain of the ship says. "You don't seem to know what's going to happen here. A mighty warlord from {system} is going to attack {planet}. You shouldn't stay here, unless you are a mercenary. Do you know how it works? If you attack a warlord's ship and they lose the battle, the other warlord will reward you. But if the warlord you attacked wins, you will be hunted down."]])

local reward_text = _([["Hello captain," a Coälition soldier from the ship that hailed you says. "You helped us in this battle. I am authorized to give you {credits} as a reward."]])


function create()
   source_system = system.cur()
   jumphook = hook.jumpin("begin")
   hook.land("leave")
end

function begin()
   local thissystem = system.cur()

   -- thissystem and source_system must be adjacent (for those who use player.teleport)
   local areAdj = false
   for i, s in ipairs(source_system:adjacentSystems()) do
      if thissystem == s then
         areAdj = true
         break
      end
   end

   if not areAdj then
      evt.finish(false)
   end

   --choose 1 particular planet 
   plan = thissystem:planets()
   cand = {}
   k = 1

   for i, p in ipairs(plan) do
      if p:faction() == faction.get("Coälition") then
         cand[k] = p
         k = k+1
      end
   end

   --If no planet matches the specs...
   if #cand <= 0 then
      evt.finish(false)
   end

   source_planet = cand[rnd.rnd(1,#cand)]

   hook.timer(3, "merchant")
   hook.timer(12, "attack")

   inForm = true

   hook.rm(jumphook)
   hook.jumpout("leave")
end

--Spawns a merchant ship that explains what happens
function merchant()
   if faction.get("Coälition"):playerStanding() < 0 then
      return
   end
   if var.peek("warlords_battle_explained") then
      -- Don't repeat the explanation if the player has already heard it.
      return
   end
   trader = pilot.add("Llama", "Civilian", source_system, _("Civilian Llama"))
   trader:setNoClear()
   hook.timer(2, "hailme")
end

function hailme()
   if not trader:exists() then
      return
   end
   if trader:hostile() then
      return
   end

   trader:hailPlayer()
   hailhook = hook.pilot(trader, "hail", "hail")
end

function hail(p)
   hook.rm(hailhook)

   if p:hostile() then
      return
   end

   player.commClose()
   tk.msg("", fmt.f(explain_text,
         {system=source_system:name(), planet=source_planet:name()}))

   var.push("warlords_battle_explained", true)
end

function hailmeagain(reward)
   hook.rm(hailhook)
   if warrior == nil or not warrior:exists() then
      return
   end
   warrior:setVisplayer()
   warrior:hailPlayer()
   hailhook = hook.pilot(warrior, "hail", "hailagain", reward)
end

function hailagain(p, reward)
   hook.rm(hailhook)
   tk.msg("", fmt.f(reward_text, {credits=fmt.credits(reward)}))
   player.pay(reward)
   player.commClose()
   evt.finish(true)
end

function attack()
   local f1 = faction.dynAdd("Coälition", N_("Invaders"), nil,
         {clear_allies=true})
   local f2 = faction.dynAdd("Coälition", N_("Locals"), nil,
         {clear_allies=true})
   f1:dynEnemy(f2)
   f2:dynEnemy(f1)

   goda = pilot.add("Coälition Legion", f1, source_system,
         _("Invading Warlord"))
   attackers = fleet.add({rnd.rnd(1, 2), rnd.rnd(2, 3), rnd.rnd(3, 6),
            rnd.rnd(3, 10)},
         {"Coälition Vigilance", "Coälition Phalanx", "Coälition Ancestor",
            "Coälition Vendetta"}, f1, source_system,
         _("Invading Warlord Force"), nil, goda)

   form = formation.random_key()

   for i, p in ipairs(attackers) do
      p:setHilight()
      p:setNoClear()
      p:memory().formation = form
      p:memory().aggressive = false
      p:memory().kill_reward = nil

      hook.pilot(p, "attacked", "attackerAttacked")
      hook.pilot(p, "death", "attackerDeath")
      hook.pilot(p, "jump", "attackerDeath")
      hook.pilot(p, "land", "attackerDeath")
   end

   attnum = #attackers
   attdamage = 0

   godd = pilot.add("Coälition Legion", f2, source_planet, _("Local Warlord"))
   defenders = fleet.add({rnd.rnd(1, 2), rnd.rnd(2, 3), rnd.rnd(3, 6),
            rnd.rnd(3, 10)},
         {"Coälition Vigilance", "Coälition Phalanx", "Coälition Ancestor",
            "Coälition Vendetta"}, f2, source_planet,
         _("Local Warlord Force"), nil, godd)

   form = formation.random_key()

   for i, p in ipairs(defenders) do
      p:setHilight()
      p:setNoClear()
      local mem = p:memory()
      mem.formation = form
      mem.aggressive = false
      mem.kill_reward = nil

      hook.pilot(p, "attacked", "defenderAttacked")
      hook.pilot(p, "death", "defenderDeath")
      hook.pilot(p, "jump", "defenderDeath")
      hook.pilot(p, "land", "defenderDeath")
   end

   defnum = #defenders
   defdamage = 0

   goda:setVisible()
   goda:setHilight()
   goda:control()

   godd:setVisible()
   godd:setHilight()
   godd:control()

   goda:attack(godd)
   godd:attack(goda)

   hook.timer(0.5, "proximity", {anchor=goda, radius=10000,
            funcname="startBattle", focus=godd})
end

-- Both fleets are close enough: start the epic battle
function startBattle()
   if inForm then
      for i, p in ipairs(attackers) do
         if p:exists() then
            p:memory().aggressive = true
         end
      end
      local attleader = getLeader(attackers)
      if attleader ~= nil and attleader:exists() then
         attleader:control(false)
      end

      for i, p in ipairs(defenders) do
         if p:exists() then
            p:memory().aggressive = true
         end
      end
      local defleader = getLeader(defenders)
      if defleader ~= nil and defleader:exists() then
         defleader:control(false)
      end
      inForm = false
   end
end

function defenderAttacked(victim, attacker, damage)
   if attacker == nil then
      return
   end

   if inForm then
      for i, p in ipairs(defenders) do
         if p == attacker then
            startBattle()
            return
         end
      end
   end

   if attacker == player.pilot() or attacker:leader(true) == player.pilot() then
      startBattle()

      if not playerAttackedDefenders then
         for i, p in ipairs(defenders) do
            if p:exists() then
               p:setHostile()
            end
         end
      end

      playerAttackedDefenders = true
      defdamage = defdamage + damage
   end
end

function attackerAttacked(victim, attacker, damage)
   if attacker == nil then
      return
   end

   if inForm then
      for i, p in ipairs(attackers) do
         if p == attacker then
            startBattle()
            return
         end
      end
   end

   local player_p = player.pilot()
   if attacker == player_p or attacker:leader(true) == player_p then
      startBattle()

      if not playerAttackedAttackers then
         for i, p in ipairs(attackers) do
            if p:exists() then
               p:setHostile()
            end
         end
      end

      playerAttackedAttackers = true
      attdamage = attdamage + damage
   end
end

function attackerDeath(victim, attacker)
   attnum = attnum - 1
   if attnum <= 0 then
      -- Make the winners into normal Coälition pilots.
      for i, p in ipairs(defenders) do
         if p:exists() then
            p:control(false)
            p:setHilight(false)
            p:setVisible(false)
            p:hookClear()
            p:taskClear()
            local mem = p:memory()
            mem.aggressive = true
         end
      end

      --Time to get rewarded
      if playerAttackedAttackers and playerIsFriendly(defenders) then
         warrior = chooseInList(defenders)
         local reward = computeReward(attdamage)
         hook.timer(1.0, "hailmeagain", reward)
      end
   elseif inForm and victim == goda then
      startBattle()
      for i, p in ipairs(attackers) do
         if p:exists() then
            p:setHilight()
            p:setVisible()
         end
      end
   end
end

function defenderDeath(victim, attacker)
   defnum = defnum - 1
   if defnum <= 0 then
      -- Make the winners into normal Coälition pilots.
      for i, p in ipairs(attackers) do
         if p:exists() then
            p:control(false)
            p:setHilight(false)
            p:setVisible(false)
            p:hookClear()
            p:taskClear()
            local mem = p:memory()
            mem.aggressive = true
         end
      end

      --Time to get rewarded
      if playerAttackedDefenders and playerIsFriendly(attackers) then
         warrior = chooseInList(attackers)
         local reward = computeReward(defdamage)
         hook.timer(1.0, "hailmeagain", reward)
      end
   elseif inForm and victim == godd then
      startBattle()
      for i, p in ipairs(defenders) do
         if p:exists() then
            p:setHilight()
            p:setVisible()
         end
      end
   end
end

--Computes the reward
function computeReward(damage)
   local reward = 20000 + 100*damage
   reward = reward + rnd.sigma() * (reward/3)
   return reward
end

-- Returns leader of fleet
function getLeader(list)
   local p = chooseInList(list)
   if p == nil then
      return nil
   end

   if p:leader() == nil or not p:leader():exists() then
      return p
   else
      return p:leader()
   end
end

-- Chooses the first alive pilot in a list, or nil if all are dead
function chooseInList(list)
   for i, p in ipairs(list) do
      if p:exists() then
         local armor = p:health()
         if armor > 0 then
            return p
         end
      end
   end
   return nil
end

-- Returns true if player is friendly to the fleet, false otherwise
function playerIsFriendly(list)
   if faction.get("Coälition"):playerStanding() < 0 then
      return false
   end

   for i, p in ipairs(list) do
      if p:exists() and p:hostile() then
         return false
      end
   end

   return true
end


function leave ()
   evt.finish()
end
