--[[
-- Basic tasks for a pilot, no need to reinvent the wheel with these.
--
-- Idea is to have it all here and only really work on the "control"
-- functions and such for each AI.
--]]


--[[
-- Faces the target.
--]]
function __face( target )
   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   ai.face(target)
end
function __face_towards( target )
   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local off = ai.face(target)
   if math.abs(off) < 5 then
      ai.poptask()
   end
end


--[[
-- Brakes the ship
--]]
function brake ()
   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   ai.brake()
   if ai.isstopped() then
      ai.stop()
      ai.poptask()
      return
   end
end


--[[
-- Brakes the ship
--]]
function __subbrake ()
   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   ai.brake()
   if ai.isstopped() then
      ai.stop()
      ai.popsubtask()
      return
   end
end


--[[
-- Move in zigzag around a direction
--]]
function __zigzag ( dir, angle )
   if mem.pm == nil then
      mem.pm = 1
   end

   if (mem.pm*dir < angle-20) or (mem.pm*dir > angle+25) then
      -- Orientation is totally wrong: reset timer
      ai.settimer(0, 2)
   end

   if (mem.pm*dir < angle) then
      ai.turn(-mem.pm)
   else
      ai.turn(mem.pm)
      if (mem.pm*dir < angle+5) then -- Right orientation, wait for max vel
         --if ai.ismaxvel() then -- TODO : doesn't work well
         if ai.timeup(0) then
            mem.pm = -mem.pm
         end
      end
   end
   ai.accel()
end


--[[
-- Goes to a target position without braking
--]]
function __moveto_nobrake( target )
   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local dir = ai.face(target, nil, true)
   __moveto_generic(target, dir, false)
end


--[[
-- Goes to a target position without braking
--]]
function __moveto_nobrake_raw( target )
   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local target = ai.taskdata()
   local dir = ai.face(target)
   __moveto_generic(target, dir, false)
end


--[[
-- Goes to a precise position.
--]]
function __moveto_precise ()
   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local target = ai.taskdata()
   local dir = ai.face(target, nil, true)
   local dist = ai.dist(target)

   -- Handle finished
   if ai.isstopped() and dist < 10 then
      ai.poptask() -- Finished
      return
   end

   local bdist    = ai.minbrakedist()

   -- Need to get closer
   if dir < 10 and dist > bdist then
      ai.accel()

   -- Need to start braking
   elseif dist <= bdist then
      ai.pushsubtask("__subbrake")
   end
end




--[[
-- Goes to a target position roughly
--]]
function moveto ()
   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local target = ai.taskdata()
   local dir = ai.face(target, nil, true)
   __moveto_generic(target, dir, true)
end


--[[
-- Goes to a point in order to inspect (same as moveto, but pops when attacking)
--]]
function inspect_moveto( target )
   __moveto_nobrake( target )
end


--[[
-- moveto without velocity compensation.
--]]
function moveto_raw ()
   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local target = ai.taskdata()
   local dir = ai.face( target )
   __moveto_generic(target, dir, true)
end


--[[
-- Generic moveto function.
--]]
function __moveto_generic( target, dir, brake, subtask )
   local dist     = ai.dist( target )
   local bdist
   if brake then
      bdist    = ai.minbrakedist()
   else
      bdist    = 50
   end

   -- Need to get closer
   if dir < 10 and dist > bdist then
      ai.accel()

   -- Need to start braking
   elseif dist <= bdist then
      ai.poptask()
      if brake then
         ai.pushtask("brake")
      end
      return
   end
end


--[[
-- Goes to a point as fast as possible (for racers).
--]]
function moveto_race()
   local p = ai.pilot()
   local target = ai.taskdata()
   local dir = ai.face(target, false, true)
   __moveto_generic(target, dir, false)

   -- Afterburner handling.
   if ai.hasafterburner() and p:energy() > 10 then
      ai.weapset(8, true)
   end
end


--[[
-- Follows it's target.
--]]
function follow ()
   local target = ai.taskdata()

   -- Will just float without a target to escort.
   if not target:exists() then
      ai.poptask()
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local dir = ai.face(target)
   local dist = ai.dist(target)

   -- Must approach
   if dir < 10 and dist > 300 then
      ai.accel()
   end
end
function follow_accurate ()
   local target = ai.taskdata()
   local p = ai.pilot()

   -- Will just float without a target to escort.
   if not target:exists() then
      ai.poptask()
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local goal = ai.follow_accurate(target, mem.radius,
         mem.angle, mem.Kp, mem.Kd)

   local mod = vec2.mod(goal - p:pos())

   --  Always face the goal
   local dir = ai.face(goal)

   if dir < 10 and mod > 300 then
      ai.accel()
   end

end

-- Default action for non-leader pilot in fleet
function follow_fleet ()
   local plt = ai.pilot()
   local leader = plt:leader(true)

   if leader == nil or not leader:exists() then
      ai.poptask()
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   if mem.form_pos == nil then -- Simply follow unaccurately
      local dir = ai.face(leader)
      local dist = ai.dist(leader)
      if dist > 300 and dir < 10 then -- Must approach
         ai.accel()
      end

   else -- Ship has a precise position in formation
      if mem.app == nil then
         mem.app = 2
      end

      local angle, radius, method = table.unpack(mem.form_pos)
      local goal  = ai.follow_accurate(leader, radius, angle, mem.Kp, mem.Kd, method) -- Standard controller
      local dist  = ai.dist(goal)

      if mem.app == 2 then
         local dir   = ai.face(goal)
         if dist > 300 then
            if dir < 10 then  -- Must approach
               ai.accel()
            end
         else  -- Toggle precise positioning controller
            mem.app = 1
         end

      elseif mem.app == 1 then -- only small corrections to do
         if dist > 300 then -- We're much too far away, we need to toggle large correction
            mem.app = 2
         else  -- Derivative-augmented controller
            local goal0 = ai.follow_accurate(leader, radius, angle, 2*mem.Kp, 10*mem.Kd, method)
            local dist0 = ai.dist(goal0)
            local dir = ai.face(goal0)
            if dist0 > 300 then
               if dir < 10 then  -- Must approach
                  ai.accel()
               end
            else  -- No need to approach anymore
               mem.app = 0
            end
         end

      else
         local dir   = ai.face(goal)
         if dist > 300 then   -- Must approach
            mem.app = 1
         else   -- Face forward
            goal = plt:pos() + leader:vel()
            ai.face(goal)
         end
      end
   end
end

--[[
-- Tries to runaway and jump asap.
--]]
function __runaway ()
   runaway()
end

--[[
-- Runaway without jumping
--]]
function __runaway_nojump ()
   runaway_nojump()
end


--[[
-- Tries to hyperspace asap.
--]]
function __hyperspace ()
   hyperspace()
end
function __hyperspace_shoot ()
   local target = ai.taskdata()
   if target == nil then
      target = ai.rndhyptarget()
      if target == nil then
         return
      end
   end
   local pos = ai.sethyptarget(target)
   ai.pushsubtask( "__hyp_approach_shoot", pos )
end
function __hyp_approach_shoot ()
   -- Shoot and approach
   __move_shoot()
   __hyp_approach()
end


function __land()
   land()
end

function __land_shoot ()
   local dest = ai.taskdata() or __choose_land_target()
   if dest == nil then
      warn(string.format(_("Pilot '%s' tried to land with no landable assets!"),
            ai.pilot():name()))
      ai.poptask()
      return
   end

   ai.pushsubtask("__landgo_shoot", dest)
end

function __landgo_shoot()
   __move_shoot()
   __landgo()
end

function __move_shoot ()
   -- Shoot while going somewhere
   -- The difference with run_turret is that we pick a new enemy in this one
   if ai.hasturrets() then
      enemy = ai.getenemy()
      if enemy ~= nil then
         ai.weapset("all_nonseek")
         ai.settarget( enemy )
         ai.shoot( true )
         ai.weapset("turret_seek")
      end
   end

   -- Always launch fighters ASAP
   ai.weapset("fighter_bay")
end


function __choose_land_target()
   local landplanet = ai.landplanet()
   if landplanet ~= nil then
      return landplanet:pos()
   end

   return nil
end

--[[
-- Attempts to land on a planet.
--]]
function land ()
   if mem.noleave then
      ai.poptask()
      return
   end

   local dest = ai.taskdata() or __choose_land_target()
   if dest == nil then
      warn(string.format(_("Pilot '%s' tried to land with no landable assets!"),
            ai.pilot():name()))
      ai.poptask()
      return
   end

   ai.pushsubtask("__landgo", dest)
end
function __landgo ()
   local dest = ai.subtaskdata()
   local dist = ai.dist(dest)
   local bdist = ai.minbrakedist()

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   -- 2 methods depending on mem.careful
   local dir
   if not mem.careful or dist < 3*bdist then
      dir = ai.face(dest)
   else
      dir = ai.careful_face(dest)
   end

   if dir < 10 and dist > bdist then
      -- Need to get closer
      ai.accel()
   elseif dist <= bdist then
      -- Need to start braking
      ai.pushsubtask("__landstop", dest)
   end

end
function __landstop()
   if not ai.canLand() then
      local p = ai.pilot()
      warn(string.format(_("'%s' cannot land. Popping '%s' task."),
            p:name(), ai.taskname()))
      ai.poptask()
      return
   end

   ai.brake()
   if ai.isstopped() then
      local dest = ai.subtaskdata()

      ai.stop()
      if ai.land() then
         local p = ai.pilot()
         p:msg(p:followers(), "land", dest)
      end

      -- Either we're done, or landing failed; either way, pop the task.
      ai.poptask()
   end
end


--[[
-- Attempts to run away from the target.
--]]
function runaway()
   -- Target must exist
   local p = ai.pilot()
   local target = ai.taskdata()
   if not target:exists() then
      -- Make sure afterburner is off.
      ai.weapset(8, false)

      ai.poptask()
      return
   end

   -- See if there's a target to use when running
   local hyp = ai.nearhyptarget()
   local pnt = ai.nearestplanet()

   if (pnt == nil and hyp == nil) or mem.noleave or p:stats().jumps < 1 then
      ai.pushsubtask("__run_target")
   elseif pnt == nil then
      local pos = ai.sethyptarget(hyp)
      ai.pushsubtask("__run_hyp", {hyp, pos})
   elseif hyp == nil then
      ai.pushsubtask("__landgo", pnt:pos())
   else
      -- find which one is the closest
      local pilpos = p:pos()
      local modt = vec2.mod(hyp:pos() - pilpos)
      local modp = vec2.mod(pnt:pos() - pilpos)
      if modt < modp then
         local pos = ai.sethyptarget(hyp)
         ai.pushsubtask("__run_hyp", {hyp, pos})
      else
         ai.pushsubtask("__run_landgo", pnt:pos())
      end
   end
end
function runaway_nojump()
   -- Target must exist
   local target = ai.taskdata()
   if not target:exists() then
      -- Make sure afterburner is off.
      ai.weapset(8, false)

      ai.poptask()
      return
   end

   ai.pushsubtask("__run_target")
end
function __run_target ()
   local target = ai.taskdata()
   local plt = ai.pilot()

   -- Target must exist
   if not target:exists() then
      -- Make sure afterburner is off.
      ai.weapset(8, false)

      ai.poptask()
      return true
   end

   -- Good to set the target for distress calls
   ai.settarget( target )

   -- See whether we have a chance to outrun the attacker
   local relspe = plt:stats().speed_max/target:stats().speed_max
   if plt:stats().mass <= 400 and relspe <= 1.01 and ai.hasprojectile() and (not ai.hasafterburner()) then
      -- Pilot is agile, but too slow to outrun the enemy: dodge
      local dir = ai.dir(target) + 180      -- Reverse (run away)
      if dir > 180 then dir = dir - 360 end -- Because of periodicity
      __zigzag(dir, 70)
   else
      ai.face(target, true)
      ai.accel()
   end

   -- Afterburner handling.
   if ai.hasafterburner() and plt:energy() > 10 then
      ai.weapset(8, true)
   end

   -- Shoot the target
   __run_turret(target)

   return false
end
function __run_turret(target)
   -- Shoot the target
   if target:exists() then
      ai.hostile(target)
      ai.settarget(target)
      local dist = ai.dist(target)
      -- See if we have some turret to use
      if ai.hasturrets() then
         if dist < ai.getweaprange("turret_nonseek") then
            ai.weapset("turret_nonseek")
            ai.shoot()
            ai.weapset("turret_seek")
         end
      end
   end

   -- Always launch fighters ASAP
   ai.weapset("fighter_bay")
end
function __run_hyp ()
   -- Go towards jump
   local target = ai.taskdata()
   local hyp, hyp_pos = table.unpack(ai.subtaskdata())
   local jdir
   local bdist = ai.minbrakedist()
   local jdist = ai.dist(hyp_pos)
   local plt = ai.pilot()

   -- Shoot the target
   __run_turret(target)

   if jdist > bdist then
      local dozigzag = false
      if target:exists() then
         local relspe = plt:stats().speed_max / target:stats().speed_max
         if plt:stats().mass <= 400 and relspe <= 1.01 and ai.hasprojectile()
               and not ai.hasafterburner() and jdist > 3*bdist then
            dozigzag = true
         end
      end

      if dozigzag then
         -- Pilot is agile, but too slow to outrun the enemy: dodge
         local dir = ai.dir(hyp_pos)
         __zigzag(dir, 70)
      else
         if jdist > 3*bdist and plt:stats().mass < 600 then
            jdir = ai.careful_face(hyp_pos)
         else --Heavy ships should rush to jump point
            jdir = ai.face(hyp_pos, nil, true)
         end
         if jdir < 10 then
            ai.accel()
         end
      end

      -- Afterburner: activate while far away from jump
      if ai.hasafterburner() and plt:energy() > 10 then
         if jdist > 3 * bdist then
            ai.weapset(8, true)
         else
            ai.weapset(8, false)
         end
      end
   else
      ai.pushsubtask("__hyp_brake", {hyp, hyp_pos})
   end
end

function __run_landgo ()
   local target = ai.taskdata()
   local dest = ai.subtaskdata()
   local dist = ai.dist(dest)
   local bdist = ai.minbrakedist()
   local plt = ai.pilot()

   if dist <= bdist then -- Need to start braking
      ai.pushsubtask("__landstop", dest)
   else
      local dozigzag = false
      if target:exists() then
         local relspe = plt:stats().speed_max / target:stats().speed_max
         if plt:stats().mass <= 400 and relspe <= 1.01 and ai.hasprojectile() and
            (not ai.hasafterburner()) and dist > 3*bdist then
            dozigzag = true
         end

         -- Shoot the target
         __run_turret(target)
      end

      if dozigzag then
         -- Pilot is agile, but too slow to outrun the enemy: dodge
         local dir = ai.dir(dest)
         __zigzag(dir, 70)
      else

         -- 2 methods depending on mem.careful
         local dir
         if not mem.careful or dist < 3*bdist then
            dir = ai.face(dest)
         else
            dir = ai.careful_face(dest)
         end
         if dir < 10 then
            ai.accel()
         end
      end

      -- Afterburner
      if ai.hasafterburner() and plt:energy() > 10 then
         if dist > 3 * bdist then
            ai.weapset(8, true)
         else
            ai.weapset(8, false)
         end
      end
   end
end


--[[
-- Starts heading away to try to hyperspace.
--]]
function hyperspace()
   if mem.noleave or ai.pilot():stats().jumps < 1 then
      ai.poptask()
      return
   end

   local hyp = ai.taskdata()
   if hyp == nil then
      hyp = ai.rndhyptarget()
      if hyp == nil then
         ai.poptask()
         return
      end
   end
   local pos = ai.sethyptarget(hyp)
   ai.pushsubtask("__hyp_approach", {hyp, pos})
end
function __hyp_approach ()
   local hyp, hyp_pos = table.unpack(ai.subtaskdata())
   local dir
   local dist = ai.dist(hyp_pos)
   local bdist = ai.minbrakedist()

   if mem.noleave or ai.pilot():stats().jumps < 1 then
      ai.poptask()
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   -- 2 methods for dir
   if not mem.careful or dist < 3*bdist then
      dir = ai.face(hyp_pos, nil, true)
   else
      dir = ai.careful_face(hyp_pos)
   end

   -- Need to get closer
   if dir < 10 and dist > bdist then
      ai.accel()
   -- Need to start braking
   elseif dist <= bdist then
      ai.pushsubtask("__hyp_brake", {hyp, hyp_pos})
   end
end
function __hyp_brake()
   local p = ai.pilot()

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   -- Handle instant jump capable ships differently.
   if ai.instantJump() then
      local hyp, hyp_pos = table.unpack(ai.subtaskdata())

      -- Rotate to match the jump exit angle.
      ai.rotate(-hyp:angle())

      local result = ai.hyperspace()
      if result == nil then
         p:msg(p:followers(), "hyperspace", ai.nearhyptarget())
         ai.poptask()
         return
      elseif result == -2 then
         -- Hyperdrive is offline. Print a debug message to possibly
         -- debug this, except for the player's carrier fighters
         -- (since those have hyperdrive disabled on purpose).
         if not mem.carrier or p:leader() ~= player.pilot() then
            debug_print(
               string.format("'%s' cannot jump for task '%s' (hyperdrive disabled).",
                     p:name(), ai.taskname()))
         end
         ai.poptask()
         return
      elseif result == -3 then
         -- Fuel too low. Print a debug message to possibly debug this.
         debug_print(
            string.format("'%s' cannot jump for task '%s' (not enough fuel).",
                  p:name(), ai.taskname()))
         ai.poptask()
         return
      end

      -- If we're moving away from the jump point, treat it as a
      -- failure and pop the task.
      local ppos = p:pos()
      local pvel = p:vel()
      local dist2 = vec2.dist2(ppos, hyp_pos)
      if vec2.dist2(ppos + pvel, hyp_pos) > dist2 then
         ai.poptask()
      end

      return
   end

   ai.brake()
   if ai.isstopped() then
      ai.stop()
      local result = ai.hyperspace()
      if result == nil then
         p:msg(p:followers(), "hyperspace", ai.nearhyptarget())
      elseif result == -2 then
         -- Hyperdrive is offline. Print a debug message to possibly
         -- debug this, except for the player's carrier fighters
         -- (since those have hyperdrive disabled on purpose).
         if not mem.carrier or p:leader() ~= player.pilot() then
            debug_print(
               string.format("'%s' cannot jump for task '%s' (hyperdrive disabled).",
                     p:name(), ai.taskname()))
         end
      elseif result == -3 then
         -- Fuel too low. Print a debug message to possibly debug this.
         debug_print(
            string.format("'%s' cannot jump for task '%s' (not enough fuel).",
                  p:name(), ai.taskname()))
      end

      -- Either we're done, or hyperspace failed; either way, pop task.
      ai.poptask()
   end
end


--[[
-- Performs an escape jump (called a "local jump" internally).
--]]
function localjump()
   if ai.localjump() then
      ai.poptask()
   end
end


--[[
-- Boards the target
--]]
function board ()
   local target = ai.taskdata()

   -- Make sure pilot exists
   if not target:exists() then
      ai.poptask()
      return
   end

   -- Must be able to board
   if not ai.canboard(target) then
      ai.poptask()
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   -- Get ready to board
   ai.settarget(target)
   local dir   = ai.face(target)
   local dist  = ai.dist(target)
   local bdist = ai.minbrakedist(target)

   -- See if must brake or approach
   if dist <= bdist then
      ai.pushsubtask( "__boardstop", target )
   elseif dir < 10 then
      ai.accel()
   end
end


--[[
-- Attempts to brake on the target.
--]]
function __boardstop ()
   target = ai.taskdata()

   -- make sure pilot exists
   if not target:exists() then
      ai.poptask()
      return
   end

   -- Make sure can board
   if not ai.canboard(target) then
      ai.poptask()
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   -- Set target
   ai.settarget(target)
   local vel = ai.relvel(target)

   if vel < 10 then
      -- Try to board
      if ai.board(target) then
         ai.poptask()
         return
      end
   end

   -- Just brake
   ai.brake()

   -- If stopped try again
   if ai.isstopped() then
      ai.popsubtask()
   end
end



--[[
-- Boards the target
--]]
function refuel ()

   -- Get the target
   local target = ai.taskdata()

   -- make sure pilot exists
   if not target:exists() then
      ai.poptask()
      return
   end

   -- See if finished refueling
   if not ai.pilot():flags().refueling then
      ai.poptask()
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   -- Get ready to board
   ai.settarget(target)
   local dir = ai.face(target)
   local dist = ai.dist(target)
   local bdist = ai.minbrakedist(target)

   -- See if must brake or approach
   if dist <= bdist then
      ai.pushsubtask("__refuelstop", target)
   elseif dir < 10 then
      ai.accel()
   end
end

--[[
-- Attempts to brake on the target.
--]]
function __refuelstop ()
   local target = ai.taskdata()

   -- make sure pilot exists
   if not target:exists() then
      ai.poptask()
      return
   end

   -- Set the target
   ai.settarget(target)

   -- See if finished refueling
   local p = ai.pilot()
   if not p:flags().refueling then
      p:comm(target, _("Finished fuel transfer."))
      ai.poptask()

      -- Untarget
      ai.settarget( p )
      return
   end

   -- Try to board
   if ai.refuel(target) then
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   -- Just brake
   ai.brake()

   -- If stopped try again
   if ai.isstopped() then
      ai.popsubtask()
   end
end

--[[
-- Mines an asteroid
--]]
function mine ()
   ai.weapset("all_nonseek")
   local fieldNast = ai.taskdata()
   local field = fieldNast[1]
   local ast = fieldNast[2]
   local p = ai.pilot()
   local wrange = ai.getweaprange("all_nonseek")
   local trange = math.min(mem.gather_range * 3 / 4, wrange * 0.9)
   local mbd = ai.minbrakedist()

   -- If the asteroid has been destroyed, pop the task and gather.
   if system.asteroidDestroyed(field, ast) then
      ai.poptask()
      ai.pushtask("gather")
      return
   end

   -- See if there's a gatherable; if so, pop this task and gather instead
   local gat = ai.getgatherable(mem.gather_range)
   if gat ~= nil and ai.gatherablepos(gat) ~= nil then
      ai.poptask()
      ai.pushtask("gather")
      return
   end

   ai.setasterotarget(field, ast)

   local target, vel = system.asteroidPos(field, ast)
   local dist, angle = vec2.polar(p:pos() - target)

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   -- First task : place the ship close to the asteroid
   local goal = ai.face_accurate(target, vel, trange, angle, mem.Kp, mem.Kd)

   local dir  = ai.face(goal)
   local mod  = ai.dist(goal)

   if dir < 10 and mod > mbd then
      ai.accel()
   end

   local relpos = vec2.add(p:pos(), target * -1):mod()
   local relvel = vec2.add(p:vel(), vel * -1):mod()

   if relpos < wrange and relvel < 10 then
      ai.pushsubtask("__killasteroid")
   end
end
function __killasteroid ()
   local fieldNast = ai.taskdata()
   local field = fieldNast[1]
   local ast = fieldNast[2]
   local wrange = ai.getweaprange("all_nonseek")

   -- If the asteroid has been destroyed, pop the task and gather.
   if system.asteroidDestroyed(field, ast) then
      ai.poptask()
      ai.pushtask("gather")
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local target = system.asteroidPos(field, ast)
   local dir = ai.face(target)

    -- See if there's a gatherable; if so, pop this task and gather instead
   local gat = ai.getgatherable(mem.gather_range)
   if gat ~= nil and ai.gatherablepos(gat) ~= nil then
      ai.poptask()
      ai.pushtask("gather")
      return
   end

   -- Have to start over if we're out of range for some reason
   if ai.dist(target) > wrange then
      ai.popsubtask()
      return
   end

   -- Second task : destroy it
   if dir < 8 then
      ai.weapset("all_nonseek")
      ai.shoot()
      ai.shoot(true)
   end
end

--[[
-- Attempts to seek and gather gatherables
--]]
function gather ()
   if ai.pilot():cargoFree() == 0 then --No more cargo
      ai.poptask()
      return
   end

   local gat = ai.getgatherable(mem.gather_range)

   if gat == nil then -- Nothing to gather
      ai.poptask()
      return
   end

   local target, vel = ai.gatherablepos(gat)
   if target == nil then -- gatherable disappeared
      ai.poptask()
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local goal = ai.face_accurate(target, vel, 0, 0, mem.Kp, mem.Kd)

   local dir = ai.face(goal)
   local mod = ai.dist(goal)

   if dir < 10 and mod > 100 then
      ai.accel()
   end
end


-- Holds position
function hold ()
   follow_fleet()
end


-- Flies back and tries to either dock or stops when back at leader
function flyback( dock )
   local target = ai.pilot():leader()
   if not target or not target:exists() then
      ai.poptask()
      return
   end

   -- Make sure afterburner is off, since it messes things up here.
   ai.weapset(8, false)

   local goal = ai.follow_accurate(target, 0, 0, mem.Kp, mem.Kd)
   local dir = ai.face(goal)
   local dist = ai.dist(goal)

   if dist > 300 then
      if dir < 10 then
         ai.accel()
      end
   else -- Time to dock
      if dock then
         ai.dock(target)
      else
         ai.poptask()
      end
   end
end


--[[
-- Checks to see if a pilot is visible
-- Assumes the pilot exists!
--]]
function __check_seeable( target )
   local self = ai.pilot()
   if not target:flags().invisible then
      -- Pilot still sees the target: continue attack
      if self:inrange( target ) then
         return true
      end

      -- Pilots on manual control (in missions or events) never loose target
      -- /!\ This is not necessary desirable all the time /!\
      -- TODO: there should probably be a flag settable to allow to outwit pilots under manual control
      if self:flags().manualcontrol then
         return true
      end
   end
   return false
end


--[[
-- Aborts current task and tries to see what happened to the target.
--]]
function __investigate_target( target )
   local p = ai.pilot()
   ai.settarget(p) -- Un-target
   ai.poptask()
   -- Guess the pilot will be randomly between the current position and the
   -- future position if they go in the same direction with the same velocity
   local ttl = ai.dist(target) / p:stats().speed_max
   local fpos = target:pos() + vec2.newP( target:vel()*ttl, target:dir() ) * rnd.rnd()
   ai.pushtask("inspect_moveto", fpos )
end


--[[
-- Just loitering around.
--]]
function loiter( pos )
   __moveto_nobrake( pos )
end

