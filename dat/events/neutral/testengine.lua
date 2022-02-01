--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Test Engine Troubles">
 <priority>0</priority>
 <trigger>enter</trigger>
 <chance>20</chance>
 <cond>
   (function()
      if player.evtActive("Test Engine Troubles") then
         return false
      end
      for i, o in ipairs(player.pilot():outfits()) do
         if o == outfit.get("Za'lek Test Engine") then
            return true
         end
      end
      return false
   end)()
 </cond>
</event>
--]]
--[[
-- Test Engine event
--
-- Causes glitchy flying behavior when the player has a Za'lek Test
-- Engine equipped.
--]]

local fmt = require "fmt"
require "jumpdist"


teleport_text = {
   _([[You suddenly feel a huge jolt of acceleration, as if your ship was entering hyperspace, causing you to pass out. When you regain consciousness, you find that you have somehow ended up in the {system} system with an empty battery.]]),
}

slow_start_text = {
   _([[Your engine sputters and bangs loudly. You notice that it has lost its ability to propel you through space at the speed it's supposed to.]]),
}

slow_end_text = {
   _([[Suddenly, you hear a loud crack from your engine, and it starts to operate more quietly and at its full capacity again.]]),
}

slow_land_text = {
   _([[As you land, you immediately take a look at the faulty test engine. It turns out that it had some kind of debris stuck inside of it. You breathe a sigh of relief knowing that this could have easily caused a much more catastrophic problem.]]),
}

nopower_text = {
   _([[You see your lights flicker, then moments later, all of your ship's systems are offline. On the bright side, emergency backup and recovery systems immediately kick in and work to restore the power. You just hope no pirates come across your ship and take advantage of its vulnerable state.]]),
}

haywire_start_text = {
   _([[You brace yourself for an explosion or something as your engine makes strange noises, but you instead find your ship careening out of control. Your controls are unresponsive. This isn't good.…]]),
}

haywire_end_text = {
   _([[You regain control of your ship as suddenly and as you lost them. Confused but happy to be alive, you breathe a sigh of relief.]])
}

falsealarm_text = {
   _([[You prepare for the worst as your engine makes noises and refuses to jump and land, but it soon quiets down and returns to normal. You breathe a sigh of relief.]]),
}


function create()
   if not evt.claim(system.cur()) then
      evt.finish(false)
   end

   player.pilot():setNoJump()
   player.pilot():setNoLand()
   player.autonavAbort(_("Jumping and landing systems have gone offline."))

   local choices = {"teleport", "slow", "nopower", "haywire", "falsealarm"}
   hook.timer(5 + 2*rnd.sigma(), choices[rnd.rnd(1, #choices)])
end


function restore_exit()
   player.pilot():setNoJump(false)
   player.pilot():setNoLand(false)
end


function teleport()
   -- Chance to avoid this since it's quite a bad one.
   if rnd.rnd() < 0.8 then
      falsealarm()
   end

   -- TODO: teleportation isn't in a state where it can be used in
   -- player-facing applications yet, so blocking it out for now.
   falsealarm()

   hook.safe("do_teleport")
end


function do_teleport()
   local choices = getsysatdistance(system.cur(), 1, 3)
   if #choices <= 0 then
      -- Rare circumstance of a system having no nearby non-hidden-jump
      -- systems; in this case, make it a false alarm.
      falsealarm()
   end

   restore_exit()
   player.autonavAbort()

   local dest = choices[rnd.rnd(1, #choices)]
   player.teleport(dest)

   player.pilot():setEnergy(0)

   local t = fmt.f(teleport_text[rnd.rnd(1, #teleport_text)],
         {system=dest:name()})
   tk.msg("", t)
   evt.finish(true)
end


function slow()
   restore_exit()
   player.autonavAbort()
   local speed = player.pilot():stats().speed
   speed = 0.7*speed + 0.1*speed*rnd.sigma()
   player.pilot():setSpeedLimit(speed)
   tk.msg("", slow_start_text[rnd.rnd(1, #slow_start_text)])

   if rnd.rnd() < 0.2 then
      hook.timer(20 + 5*rnd.sigma(), "slow_end")
   end
   hook.land("slow_land")
end


function slow_end()
   player.pilot():setSpeedLimit(0)
   tk.msg("", slow_end_text[rnd.rnd(1, #slow_end_text)])
   evt.finish(true)
end


function slow_land()
   player.pilot():setSpeedLimit(0)
   tk.msg("", slow_land_text[rnd.rnd(1, #slow_land_text)])
   evt.finish(true)
end


function nopower()
   restore_exit()
   player.autonavAbort()
   player.pilot():disable(true)
   tk.msg("", nopower_text[rnd.rnd(1, #nopower_text)])
   evt.finish(true)
end


function haywire()
   restore_exit()
   player.cinematics(true, {gui=true})
   tk.msg("", haywire_start_text[rnd.rnd(1, #haywire_start_text)])
   player.pilot():control()
   haywire_fly()
   hook.timer(7 + 2*rnd.sigma(), "haywire_continue")
end


function haywire_fly()
    -- Fly off in a random direction
    dist = 1000
    -- Never deviate more than 90 degrees from the current direction.
    angle = rnd.rnd()*90 + player.pilot():dir()
    newlocation = vec2.newP(dist, angle)

    player.pilot():taskClear()
    player.pilot():moveto(player.pilot():pos() + newlocation, false, false)
end


function haywire_continue()
   if rnd.rnd() < 0.3 then
      tk.msg("", haywire_end_text[rnd.rnd(1, #haywire_end_text)])
      player.cinematics(false)
      player.pilot():control(false)
      evt.finish(true)
   end
   haywire_fly()
   hook.timer(7 + 2*rnd.sigma(), "haywire_continue")
end


function falsealarm()
   restore_exit()
   tk.msg("", falsealarm_text[rnd.rnd(1, #falsealarm_text)])
   evt.finish(false)
end
