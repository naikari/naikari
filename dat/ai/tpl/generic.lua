require("ai/include/basic")
require("ai/include/attack")
local formation = require("scripts/formation")

--[[
-- Variables to adjust AI
--
-- These variables can be used to adjust the generic AI to suit other roles.
--]]
mem.nofactionhit = false -- Whether to disable standing hits for the pilot.
mem.enemyclose = nil -- Distance at which an enemy is considered close
mem.armour_run = 0 -- At which damage to run at
mem.armour_return = 0 -- At which armour to return to combat
mem.shield_run = 0 -- At which shield to run
mem.shield_return = 0 -- At which shield to return to combat
mem.armor_localjump = 0 -- At which armor to perform an escape jump
mem.aggressive = false -- Should pilot actively attack enemies?
mem.defensive = true -- Should pilot defend itself
mem.protector = true -- Should pilot protect non-aggressive pilots?
mem.cooldown = false -- Whether the pilot is currently cooling down.
mem.heatthreshold = 0.5 -- Weapon heat to enter cooldown at [0-2 or nil]
mem.safe_distance = 1200 -- Safe distance from enemies to jump
mem.land_planet = true -- Should land on planets?
mem.land_friendly = false -- Only land on friendly planets?
mem.distress = true -- AI distresses
mem.distressrate = 3 -- Number of ticks before calling for help
mem.distressmsg = nil -- Message when calling for help
mem.distressmsgfunc = nil -- Function to call when distressing
mem.weapset = "all_nonseek" -- Weapon set that should be used (tweaked based on heat).
mem.tickssincecooldown = 0 -- Prevents overly-frequent cooldown attempts.
mem.norun = false -- Do not run away.
mem.noleave = false -- Do not leave the system.
mem.careful = false -- Should the pilot try to avoid enemies?
mem.kill_reward = nil -- Credits rewarded by enemies for killing the pilot

mem.formation = "circle" -- Formation to use when commanding fleet
mem.form_pos = nil -- Position in formation (for follower)
mem.leadermaxdist = nil -- Distance from leader to run back to leader
mem.nocommand = false -- Whether a pilot will refuse to follow leader commands
mem.gather_range = 1000 -- Radius in which the pilot looks for gatherables

--[[Control parameters: mem.radius and mem.angle are the polar coordinates 
of the point the pilot has to follow when using follow_accurate.
The reference direction is the target's velocity direction.
For example, radius = 100 and angle = 180 means that the pilot will stay
behind his target at a distance of 100 units.
angle = 90 will make the pilot try to be on the left of his target,
angle = 0 means that the pilot tries to be in front of the target.]]
mem.radius = 100 --  Requested distance between follower and target
mem.angle = 180 --  Requested angle between follower and target's velocity
mem.Kp = 10 --  First control coefficient
mem.Kd = 20 -- Second control coefficient

-- Required control rate that represents the number of seconds between each
-- control() call
control_rate = 2

--[[
   Binary flags for the different states that default to nil (false).
   - attack: the pilot is attacked their target
   - fighting: the pilot is engaged in combat (including running away )
   - noattack: do not try to find new targets to attack
--]]
stateinfo = {
   attack = {
      fighting = true,
      attack = true,
   },
   attack_forced = {
      forced = true,
      fighting = true,
      attack = true,
      noattack = true,
   },
   runaway = {
      fighting = true,
      noattack = true,
   },
   runaway_nojump = {
      fighting = true,
      noattack = true,
   },
   refuel = {
      noattack = true,
   },
   hold = {
      forced = true,
      noattack = true,
   },
   flyback = {
      forced = true,
      noattack = true,
   },
}

function lead_fleet ()
   local p = ai.pilot()

   -- Leave fleet management to the highest-up pilot.
   local leader = p:leader(true)
   if leader ~= nil and leader:exists() then
      return
   end

   if #p:followers(true) > 0 then
      if mem.formation == nil then
         formation.clear(p)
         return
      end

      local form = formation[mem.formation]
      if form == nil then
         warn(string.format(_("Formation '%s' not found"), mem.formation))
      else
         form(p)
      end
   end
end

-- Run instead of "control" when under manual control; use should be limited
function control_manual ()
   lead_fleet()
end

function handle_messages()
   local p = ai.pilot()
   local l = p:leader()
   local messages = ai.messages()
   for i = 1, #messages do
      local sender, msgtype, data = table.unpack(messages[i])
      if sender == l or sender == p:leader(true) then
         if msgtype == "form-pos" then
            mem.form_pos = data
         elseif msgtype == "hyperspace" then
            if p:stats().jumps >= 1 then
               ai.pushtask("hyperspace", data)
            end
         elseif msgtype == "land" then
            local pnt, pos = table.unpack(data)
            -- We have to re-get the planet this way to make sure it's
            -- targeted.
            local pnt = ai.planetfrompos(pos)
            ai.pushtask("land", {pnt, pos})
         -- Escort commands
         elseif not mem.nocommand then
            -- Attack target
            if msgtype == "e_attack" then
               if data ~= nil and data:exists() then
                  -- Only attack a target who isn't in the same fleet.
                  if data:leader(true) ~= p:leader(true) then
                     clean_task(ai.taskname())
                     ai.pushtask("attack_forced", data)
                  end
               end
            -- Hold position
            elseif msgtype == "e_hold" then
               p:taskClear()
               ai.pushtask("hold")
            -- Return to carrier
            elseif msgtype == "e_return" then
               p:taskClear()
               ai.pushtask("flyback", p:flags().carried)
            -- Clear orders
            elseif msgtype == "e_clear" then
               p:taskClear()
            end
         end
      end
   end
end

function control_attack( si )
   local target = ai.taskdata()
   -- Needs to have a target
   if not target:exists() then
      ai.poptask()
      return
   end

   local p = ai.pilot()
   local target_parmour, target_pshield = target:health()
   local parmour, pshield = p:health()

   -- Pick an appropriate weapon set.
   choose_weapset()

   if not mem.norun
         and ((mem.shield_run > 0 and pshield < mem.shield_run
               and pshield < target_pshield)
            or (mem.armour_run > 0 and parmour < mem.armour_run
               and parmour < target_parmour)) then
      -- Run away.
      ai.pushtask("runaway", target)
   else
      -- Cool down, if necessary.
      should_cooldown()

      attack_think(target, si)
   end

   -- Handle distress
   if mem.distress then
      gen_distress()
   end
end

-- Required "control" function
function control ()
   local p = ai.pilot()
   local enemy = ai.getenemy()

   lead_fleet()
   handle_messages()

   -- Task information stuff
   local task = ai.taskname()
   local si = stateinfo[task] or {}

   -- Select new leader
   local l = p:leader()
   if l ~= nil and not l:exists() then
      local candidate = ai.getBoss()
      if candidate ~= nil and candidate:exists() then
         p:setLeader( candidate )
      else -- Indicate this pilot has no leader
         p:setLeader( nil )
      end
   end

   -- If command is forced we basically override everything
   if si.forced then
      if si.attack then
         control_attack( si )
      end
      return
   end

   -- Cooldown completes silently.
   if mem.cooldown then
      mem.tickssincecooldown = 0

      local cooldown, braking = p:cooldown()
      if not (cooldown or braking) then
         mem.cooldown = false
      end
   else
      mem.tickssincecooldown = mem.tickssincecooldown + 1
   end

   -- Always launch fighters ASAP
   ai.weapset("fighter_bay")

   -- Reset distress if not fighting/running
   if not si.fighting then
      mem.attacked = nil

      -- Cooldown shouldn't preempt boarding, either.
      if task ~= "board" then
         -- Cooldown preempts everything we haven't explicitly checked for.
         if mem.cooldown then
            return
         -- If the ship is hot, consider cooling down.
         elseif p:temp() > 300 then
            -- Ship is quite hot, better cool down.
            if p:temp() > 400 then
               mem.cooldown = true
               p:setCooldown(true)
               return
            -- Cool down if the current weapon set is suffering from >= 20% accuracy loss.
            -- This equates to a temperature of 560K presently.
            elseif (p:weapsetHeat() > .2) then
               mem.cooldown = true
               p:setCooldown(true)
               return
            end
         end
      end
   end

   -- Pilots return if too far away from leader
   local lmd = mem.leadermaxdist
   if lmd ~= nil and not mem.attacked then
      local l = p:leader()
      if l then
         local dist = ai.dist( l )
         if lmd < dist then
            if task ~= "follow_fleet" and task ~= "hyperspace"
                  and task ~= "land" and task ~= "refuel" then
               if task ~= nil then
                  ai.poptask()
               end
               ai.pushtask("follow_fleet", false)
            end
            return
         end
      end
   end

   -- Get new task
   if task == nil then
      local attack = false

      -- We'll first check enemy.
      if enemy ~= nil and mem.aggressive and not ai.isbribed(enemy) then
         -- Check if we have minimum range to engage
         if mem.enemyclose then
            local dist = ai.dist( enemy )
            if mem.enemyclose > dist then
               attack = true
            end
         else
            attack = true
         end
      end

      -- See what decision to take
      if attack then
         ai.hostile(enemy) -- Should be done before taunting
         taunt(enemy, true)
         ai.pushtask("attack", enemy)
      elseif p:leader() and p:leader():exists() then
         ai.pushtask("follow_fleet")
      else
         idle()
      end

   -- Don't stop boarding
   elseif task == "board" then
      -- Needs to have a target
      local target = ai.taskdata()
      if not target or not target:exists() then
         ai.poptask()
         return
      end
      -- We want to think in case another attacker gets close
      attack_think( ai.taskdata(), si )

   -- Think for attacking
   elseif si.attack then
      control_attack( si )

   -- Pilot is running away
   elseif task == "runaway" then
      if mem.norun or ai.pilot():leader() ~= nil then
         ai.poptask()
         return
      end
      local target = ai.taskdata()

      -- Needs to have a target
      if not target:exists() then
         ai.poptask()
         return
      end

      local dist = ai.dist(target)

      -- Should return to combat?
      local parmour, pshield = p:health()
      if mem.aggressive
            and ((mem.shield_return > 0 and pshield >= mem.shield_return)
               or (mem.armour_return > 0 and parmour >= mem.armour_return)) then
         ai.poptask() -- "attack" should be above "runaway"
      elseif dist >= mem.safe_distance then
         -- Try to jump
         ai.hyperspace()
      end

      -- Handle distress
      gen_distress()

   -- Enemy sighted, handled after running away
   elseif enemy ~= nil and mem.aggressive then
      -- Don't start new attacks while refueling.
      if si.noattack or ai.isbribed(enemy) then
         return
      end

      local attack = false

      -- See if enemy is close enough to attack
      if mem.enemyclose then
         local dist = ai.dist( enemy )
         if mem.enemyclose > dist then
            attack = true
         end
      else
         attack = true
      end

      -- See if really want to attack
      if attack then
         taunt(enemy, true)
         clean_task( task )
         ai.pushtask("attack", enemy)
      end
   end
end

-- Required "attacked" function
function attacked(attacker)
   local task = ai.taskname()
   local si = stateinfo[task] or {}
   if si.forced then
      return
   end

   -- Notify that pilot has been attacked before
   mem.attacked = true

   local p = ai.pilot()
   local parmor, pshield = p:health()

   -- Cooldown should be left running if not taking heavy damage.
   if mem.cooldown then
      if pshield < 90 then
         mem.cooldown = false
         p:setCooldown(false)
      else
         return
      end
   end

   -- Ignore hits from dead pilots.
   if not attacker:exists() then
      return
   end

   if not si.fighting then
      if mem.defensive then
         -- Some taunting
         ai.hostile(attacker) -- Should be done before taunting
         taunt( attacker, false )

         -- Now pilot fights back
         clean_task( task )
         ai.pushtask("attack", attacker)
      elseif not mem.noleave then
         -- Runaway
         ai.pushtask("runaway", attacker)
      else
         -- Runaway, but don't jump
         ai.pushtask("runaway_nojump", attacker)
      end
   elseif si.attack then
      -- Let attacker profile handle it.
      attack_attacked(attacker)
   elseif task == "runaway" then
      if ai.taskdata() ~= attacker then
         ai.poptask()
         ai.pushtask("runaway", attacker)
      end
   elseif task == "runaway_nojump" then
      if ai.taskdata() ~= attacker then
         ai.poptask()
         ai.pushtask("runaway_nojump", attacker)
      end
   end

   -- Check whether we should local jump.
   if not mem.norun and mem.armor_localjump > 0
         and parmor < mem.armor_localjump and pshield <= 10 then
      -- Perform a local jump.
      ai.localjump()
   end
end

-- Delays the ship when entering systems so that it doesn't leave right away
function enterdelay ()
   if ai.timeup(0) then
      local p = ai.pilot()
      if p:stats().jumps >= 1 then
         ai.pushtask("hyperspace")
      else
         ai.poptask()
      end
   end
end

function create ()
   create_post()
end

-- Finishes create stuff like choose attack and prepare plans
function create_post ()
   mem.tookoff = ai.pilot():flags().takingoff
   attack_choose()
end

-- taunts
function taunt ( target, offensive )
   -- Empty stub
end


-- Handle distress signals
function distress(distresser, attacker)
   local aipilot = ai.pilot()

   -- Make sure target exists
   if not attacker:exists() then
      return
   end

   -- Make sure pilot is setting their target properly
   if distresser == attacker then
      return
   end

   -- Don't help if bribed
   if ai.isbribed(attacker) then
      return
   end

   -- Player's followers don't help anyone
   if aipilot:leader() == player.pilot() then
      return
   end

   local dfact = distresser:faction()
   local afact = attacker:faction()
   local aifact = aipilot:faction()
   local d_ally = aifact:areAllies(dfact)
   local a_ally = aifact:areAllies(afact)
   local d_enemy = aifact:areEnemies(dfact)
   local a_enemy = aifact:areEnemies(afact)

   -- Chosen ally and target.
   local a
   local t

   if dfact == aifact then
      if afact == aifact then
         -- If both attacker and victim are our faction, stay out of it.
         return
      else
         -- If victim is our faction and attacker isn't, assist the
         -- victim.
         a = distresser
         t = attacker
      end
   elseif mem.aggressive then
      -- Victim is not our faction and we are aggressive.
      if afact == aifact then
         -- If attacker is our faction, assist the attacker.
         a = attacker
         t = distresser
      elseif d_ally then
         if a_ally then
            -- If our allies are fighting, stay out of it.
            return
         end

         -- Victim is an ally, but the attacker isn't.
         a = distresser
         t = attacker
      elseif a_ally then
         -- If victim isn't an ally and attacker is our ally, assist the
         -- attacker.
         a = attacker
         t = distresser
      elseif d_enemy then
         if a_enemy then
            -- If they're both enemies, may as well let them destroy
            -- each other.
            return
         end

         a = attacker
         t = distresser
      elseif a_enemy then
         a = distresser
         t = attacker
      elseif mem.protector and not distresser:memory().aggressive then
         -- If we're a protector, protect non-aggressive nutral pilots.
         a = distresser
         t = attacker
      else
         return
      end
   elseif a_enemy and not d_enemy then
      -- Non-aggressive ships will flee if their enemies attack neutral
      -- or allied vessels.
      a = distresser
      t = attacker
   else
      return
   end

   local task = ai.taskname()
   local si = stateinfo[task] or {}
   -- Already fighting
   if si.attack then
      if si.noattack then
         return
      end
      local target = ai.taskdata()

      if not target:exists() or ai.dist(target) > ai.dist(t) then
         if aipilot:inrange(t) then
            ai.pushtask("attack", t)
         end
      end
   -- If not fleeing or refueling, begin attacking
   elseif task ~= "runaway" and task ~= "refuel" then
      if not si.noattack and mem.aggressive then
         -- TODO: something to help in the other case
         if aipilot:inrange(t) then
            clean_task(task)
            ai.pushtask("attack", t)
         end
      elseif not mem.noleave then
         ai.pushtask("runaway", t)
      else
         ai.pushtask("runaway_nojump", t)
      end
   end
end


-- Handles generating distress messages
function gen_distress ( target )
   -- Must have a valid distress rate
   if mem.distressrate <= 0 then
      return
   end

   -- Only generate distress if have been attacked before
   if not mem.attacked then
      return
   end

   -- Initialize if unset.
   if mem.distressed == nil then
      mem.distressed = 1
   end

   -- Update distress counter
   mem.distressed = mem.distressed + 1

   -- See if it's time to trigger distress
   if mem.distressed > mem.distressrate then
      if mem.distressmsgfunc ~= nil then
         mem.distressmsgfunc()
      else
         ai.distress( mem.distressmsg )
      end
      mem.distressed = 1
   end

end


-- Picks an appropriate weapon set for ships with mixed weaponry.
function choose_weapset()
   if ai.hascannons() and ai.hasturrets() then
      local p = ai.pilot()
      local meant, peakt = p:weapsetHeat("turret_nonseek")
      local meanc, peakc = p:weapsetHeat("forward_nonseek")

      -- Use both if both are cool, or if both are similar in temperature.
      if meant + meanc < .1 then
         mem.weapset = "all_nonseek"
      elseif peakt == 0 then
         mem.weapset = "turret_nonseek"
      elseif peakc == 0 then
         mem.weapset = "forward_nonseek"
      -- Both sets are similarly hot.
      elseif math.abs(meant - meanc) < .15 then
         mem.weapset = "all_nonseek"
      -- An extremely-hot weapon is a good reason to pick another set.
      elseif math.abs(peakt - peakc) > .4 then
         if peakt > peakc then
            mem.weapset = "forward_nonseek"
         else
            mem.weapset = "turret_nonseek"
         end
      elseif meant > meanc then
         mem.weapset = "forward_nonseek"
      else
         mem.weapset = "turret_nonseek"
      end
   end
end

-- Puts the pilot into cooldown mode if its weapons are overly hot and its shields are relatively high.
-- This can happen during combat, so mem.heatthreshold should be quite high.
function should_cooldown()
   local p = ai.pilot()
   local mean = p:weapsetHeat()
   local parmor, pshield = p:health()

   -- Don't want to cool down again so soon.
   -- By default, 15 ticks will be 30 seconds.
   if mem.tickssincecooldown < 15 then
      return
   -- The weapons are extremely hot and cooldown should be triggered.
   -- This did not work before. However now it causes ships to just stop dead and wait for energy regen.
   -- Not sure this is better...
   elseif mean > mem.heatthreshold and pshield > 50 then
      mem.cooldown = true
      p:setCooldown(true)
   end
   if pshield == nil then
      player.msg("pshield = nil")
   end
end


-- Decide if the task is likely to become obsolete once attack is finished
function clean_task( task )
   if task == "brake" or task == "inspect_moveto" then
      ai.poptask()
   end
end

