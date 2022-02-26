--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Warlords battle">
 <trigger>enter</trigger>
 <chance>5</chance>
 <cond>system.cur():faction() == faction.get("Dvaered") and not player.evtActive ("Warlords battle")</cond>
 <flags>
 </flags>
</event>
--]]
--  A battle between two Dvaered warlords. The player can join one of them and get a reward

local fmt = require "fmt"
local fleet = require "fleet"
require "proximity"
local formation = require "formation"


explain_text = _([["Hey, you," the captain of the ship says. "You don't seem to know what's going to happen here. A mighty warlord from {system} is going to attack {planet}. You shouldn't stay here, unless you are a mercenary. Do you know how it works? If you attack a warlord's ship and they lose the battle, the other warlord will reward you. But if the warlord you attacked wins, you will be hunted down."]])

reward_text = _([["Hello captain," a Dvaered officer says, "You helped us in this battle. I am authorized to give you {credits} as a reward."]])


function create()
   source_system = system.cur()
   jumphook = hook.jumpin("begin")
   landhook = hook.land("leave")
end

function begin()  
   thissystem = system.cur()

   -- thissystem and source_system must be adjacent (for those who use player.teleport)
   areAdj = false
   for _,s in ipairs(source_system:adjacentSystems()) do
      if thissystem == s then areAdj = true end
   end

   if not evt.claim(thissystem) or not areAdj then
      evt.finish(false)
   end

   --choose 1 particular planet 
   plan = thissystem:planets()
   cand = {}
   k = 1

   for i, j in ipairs(plan) do  --choose only Dvaered planets (and no stations)
      classofj = j:class()
      if j:faction() == faction.get("Dvaered") and classofj ~= "0" and classofj ~= "1" and classofj ~= "2" then
         cand[k] = j
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
   inForm = true -- People are in formation
   batInProcess = true -- Battle is happening

   hook.rm(jumphook)
   hook.jumpout("leave")
end

--Spawns a merchant ship that explains what happens
function merchant()
   if faction.get("Dvaered"):playerStanding() < 0 then
      return
   end
   trader = pilot.add("Llama", "Civilian", source_system, _("Civilian Llama"))
   hook.timer(2, "hailme")
end

function hailme()
    trader:hailPlayer()
    hailhook = hook.pilot(trader, "hail", "hail")
end

function hail()
   hook.rm(hailhook)
   tk.msg("", fmt.f(explain_text,
         {system=source_system:name(), planet=source_planet:name()}))
   player.commClose()
end

function hailmeagain()
    warrior:hailPlayer()
    hailhook = hook.pilot(warrior, "hail", "hailagain")
end

function hailagain()
   hook.rm(hailhook)
   tk.msg("", fmt.f(reward_text, {credits=fmt.credits(reward)}))
   player.pay(reward)
   player.commClose()
end

function attack()
   local f1 = faction.dynAdd("Dvaered", N_("Invaders"))
   local f2 = faction.dynAdd("Dvaered", N_("Locals"))
   f1:dynEnemy(f2)
   f2:dynEnemy(f1)

   attAttHook = {}

   goda = pilot.add("Dvaered Goddard", f1, source_system,
         _("Invading Warlord"))
   attackers = fleet.add({rnd.rnd(1, 2), rnd.rnd(2, 3), rnd.rnd(3, 6),
            rnd.rnd(3, 10)},
         {"Dvaered Vigilance", "Dvaered Phalanx", "Dvaered Ancestor",
            "Dvaered Vendetta"}, f1, source_system,
         _("Invading Warlord Force"), nil, goda)

   attackers = arrangeList(attackers)
   form = formation.random_key()

   for i, j in ipairs(attackers) do
      j:memory().formation = form
      j:memory().aggressive = false
      j:memory().nosteal = true

      attAttHook[i] = hook.pilot(j, "attacked", "attackerAttacked")
      hook.pilot(j, "death", "attackerDeath")
      hook.pilot(j, "jump", "attackerDeath")
      hook.pilot(j, "land", "attackerDeath")
   end

   attnum = table.getn(attackers)
   attdeath = 0
   attkilled = 0 -- mass of the player's victims

   defAttHook = {}

   godd = pilot.add("Dvaered Goddard", f2, source_planet, _("Local Warlord"))
   defenders = fleet.add({rnd.rnd(1, 2), rnd.rnd(2, 3), rnd.rnd(3, 6),
            rnd.rnd(3, 10)},
         {"Dvaered Vigilance", "Dvaered Phalanx", "Dvaered Ancestor",
            "Dvaered Vendetta"}, f2, source_planet,
         _("Local Warlord Force"), nil, godd)

   defenders = arrangeList(defenders)
   form = formation.random_key()

   for i, j in ipairs(defenders) do
      j:memory().formation = form
      j:memory().aggressive = false
      j:memory().nosteal = true

      defAttHook[i] = hook.pilot(j, "attacked", "defenderAttacked")
      hook.pilot(j, "death", "defenderDeath")
      hook.pilot(j, "jump", "defenderDeath")
      hook.pilot(j, "land", "defenderDeath")
   end

   defnum = table.getn(defenders)
   defdeath = 0
   defkilled = 0 --mass of the player's victims

   goda:setVisible()
   goda:setHilight()
   goda:control()

   godd:setVisible()
   godd:setHilight()
   godd:control()

   goda:attack(godd)
   godd:attack(goda)

   hook.timer(0.5, "proximity", {anchor=goda, radius=5000,
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
      getLeader(attackers):control(false)
      for i, p in ipairs(defenders) do
         if p:exists() then
            p:memory().aggressive = true
         end
      end
      getLeader(defenders):control(false)
      inForm = false
   end
end

function defenderAttacked(victim, attacker)
   --The player chose his side
   if attacker == player.pilot() or attacker:leader() == player.pilot() then
      for i, p in ipairs(defenders) do
         hook.rm(defAttHook[i])
         if p:exists() then
            p:setHostile()
         end
      end
      if side == "defender" then
         side = nil
         elseif side == nil then
         side = "attacker"
      end
   end
end

function attackerAttacked(victim, attacker)
   --The player chose his side
   if attacker == player.pilot() or attacker:leader() == player.pilot() then
      for i, p in ipairs(attackers) do
         hook.rm(attAttHook[i])
         if p:exists() then
            p:setHostile()
         end
      end
      if side == "attacker" then
         side = nil
      elseif side == nil then
         side = "defender"
      end
   end
end

function attackerDeath(victim, attacker)
   if batInProcess then
      attdeath = attdeath + 1

      if attacker == player.pilot() or attacker:leader() == player.pilot() then
         attkilled = attkilled + victim:stats().mass
      end

      if attdeath >= attnum then  --all the enemies are dead
         local lead = getLeader(defenders)
         lead:control()
         lead:land(source_planet)
         batInProcess = false -- Battle ended

         --Time to get rewarded
         if side == "defender"
               and faction.get("Dvaered"):playerStanding() >= 0 then
            warrior = chooseInList(defenders)
            computeReward(true, attkilled)
            hook.timer(1.0, "hailmeagain")
         end
      end
   end
end

function defenderDeath(victim, attacker)
   if batInProcess then
      defdeath = defdeath + 1

      if attacker == player.pilot() or attacker:leader() == player.pilot() then
         defkilled = defkilled + victim:stats().mass
      end

      if defdeath >= defnum then  -- all the defenders died : the winner lands on his planet
         local lead = getLeader(attackers)
         lead:control()
         lead:land(source_planet)
         batInProcess = false -- Battle ended

         --Time to get rewarded
         if side == "attacker"
               and faction.get("Dvaered"):playerStanding() >= 0 then
            warrior = chooseInList(attackers)
            computeReward(true, defkilled)
            hook.timer(1.0, "hailmeagain")
         end
      end
   end
end

--Computes the reward
function computeReward(attack, massOfVictims)
   if attack == true then
      baserew = 20000
   end
   baserew = baserew + 60*massOfVictims

   reward = baserew + rnd.sigma() * (baserew/3)
end

-- Returns leader of fleet
function getLeader(list)
   local p = chooseInList(list)
   if p:leader() == nil or not p:leader():exists() then
      return p
   else
      return p:leader()
   end
end

--chooses the first non nil pilot in a list
function chooseInList(list)
   for i, p in ipairs(list) do
      if p ~= nil and p:exists() then
         return p
      end
   end
end

--Arranges a list of pilot with their mass
function arrangeList(list)
   newlist = {}

   for i, j in ipairs(list) do
      local rank = 1
      for k, l in ipairs(list) do
         if j:stats().mass < l:stats().mass then
            rank = rank + 1
         end
      end

      --Processing of the equality case
      local again = true
      while again do
         if not newlist[rank] then
            newlist[rank] = j
            again = false
            else
            rank = rank + 1
         end
      end
   end

   return newlist
end

function leave ()
   evt.finish()
end
