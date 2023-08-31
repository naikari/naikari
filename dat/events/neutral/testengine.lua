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
         if o == outfit.get("Za'lek S300 Test Engine")
               or o == outfit.get("Za'lek M1200 Test Engine")
               or o == outfit.get("Za'lek L6500 Test Engine") then
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
   _([[You are slammed into a wall and knocked unconscious from a sudden unexpected acceleration. When you regain consciousness in a daze, you slowly remember what happened and check your console to see what's going on. You find that you've somehow ended up in the {system} system and that your battery is now empty.]]),
}

slow_start_text = {
   _([[Your engine sputters and bangs loudly. You notice that it has lost its ability to propel you thru space at the speed it's supposed to.]]),
   _([[Suddenly you are dizzied as you feel a shockwave as a small explosion happens in your engine. When you recover, you realize that the engine is still working, but operating at a much slower maximum speed than it should.]]),
}

slow_end_text = {
   _([[Suddenly, you hear a loud crack from your engine, and it starts to operate more quietly and at its full capacity again.]]),
   _([[Suddenly you feel a jolt and hear a strange noise coming from your engine. Shortly after, the engine returns to normal.]]),
   _([[Your engine gets even louder and you brace yourself for an explosion or something, but then it quiets down and returns to normal, much to your surprise, confusion, and relief.]]),
}

slow_land_text = {
   _([[As you land, you immediately take a look at the faulty test engine. It turns out that it had some kind of debris stuck inside of it. You breathe a sigh of relief knowing that this could have easily caused a much more catastrophic problem.]]),
   _([[You land with the intention of fixing the faulty engine, but as you land, your ship starts suddenly accelerating at an alarming speed before returning to normal. Confused, you do some investigating and find that the engine is working normally now. When you look at the engine, you don't see anything obviously wrong with it.]]),
   _([[You investigate the cause of the engine malfunction as you land, finding that some kind of strange gluey substance has clogged up the engine's internal mechanisms. You groan, but ultimately painstakingly clean off the substance, wrinkling your nose in disgust.]]),
}

nopower_text = {
   _([[You see your lights flicker, then moments later, all of your ship's systems are offline. On the bright side, emergency backup and recovery systems immediately kick in and work to restore the power. You just hope no pirates come across your ship and take advantage of its vulnerable state.]]),
   _([[You look around in confusion as your lights suddenly go out, then your eyes widen as you realize how deadly this circumstance is: your ship's power has gone offline. Thankfully, emergency backup and recovery systems come online and work to restore the power. You're not out of the woods yet, but you breathe a sigh of relief knowing that you just have to wait for a little while and hope no pirates come along to steal your credits.]]),
}

haywire_start_text = {
   _([[You brace yourself for an explosion or something as your engine makes strange noises, but you instead find your ship careening out of control. Your controls are unresponsive. This isn't good.…]]),
   _([[You curse under your breath as your controls suddenly stop working. You look for a problem with the electronics, but conclude it must be an engine problem when the ship starts flying randomly on its own. You frantically try to restore control before it's too late.]]),
}

haywire_end_text = {
   _([[You regain control of your ship as suddenly and as you lost it. Confused but happy to be alive, you breathe a sigh of relief.]]),
   _([[Suddenly, you see sparks coming from your console. Your lights flicker and you prepare for the worst, but then everything quiets down and control of your ship is restored.]]),
}

falsealarm_text = {
   _([[You prepare for the worst as your engine makes noises and refuses to jump or land, but it soon quiets down and returns to normal. You breathe a sigh of relief.]]),
   _([[You brace yourself for an explosion or something as your engine starts acting up, but it settles down and starts working properly again anticlimactically.]]),
   _([[Your engine sputters and refuses to jump or land. You begin attempting to work on the problem, but before you can start, the engine suddenly starts working normally again.]]),
   _([[You curse under your breath as your engine stops working properly, but just as you're running thru the engine failure checklist, it starts working again inexplicably. You find that you are now unable to reproduce the problem.]]),
   _([[You mentally prepare yourself for some difficult troubleshooting when you see your engine starts acting up, but then find yourself baffled as it suddenly starts working perfectly again.]]),
   _([[Just as soon as you notice a serious problem with your engine and try to work on it, the problem ends as if by magic. You find yourself even more frustrated by the inexplicable return to normal operation than by the occurrence of the original problem, but you ultimately conclude that you're best off leaving things as they are and hoping the problem doesn't return.]]),
}


function create()
   local choices = {"teleport", "slow", "nopower", "haywire", "falsealarm"}
   local choice = choices[rnd.rnd(1, #choices)]

   -- We need to claim the current system since we'll be messing around
   -- with the player's controls and such.
   if not evt.claim(system.cur()) then
      evt.finish(false)
   end

   hook.timer(5 + 2*rnd.sigma(), choice)

   player.pilot():setNoJump()
   player.pilot():setNoLand()
   player.autonavAbort(_("Jumping and landing systems have gone offline."))
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
   if dest == nil then
      -- Shouldn't happen.
      warn(_("Attempted to teleport without setting a destination."))
      falsealarm()
   end

   restore_exit()
   player.autonavAbort()
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
   local nebu_dens, nebu_volat = system.cur():nebula()
   if nebu_volat > 0 then
      -- Disabling the player in a volatile nebula can be an instant
      -- death sentence, so if we're there, pivot to false alarm to
      -- avoid frustration.
      falsealarm()
   end

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
    angle = player.pilot():dir() + rnd.uniform(-90, 90)
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
