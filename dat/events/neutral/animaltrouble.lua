--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Animal trouble">
 <trigger>enter</trigger>
 <chance>20</chance>
 <cond>var.peek("shipinfested") == true</cond>
 <flags>
  <unique />
 </flags>
 <notes>
  <done_misn name="Animal transport">The rodents sabotage your ship</done_misn>
 </notes>
</event>
--]]
--[[
-- Animal Trouble event
--
-- Temporarily makes the player's ship behave erratically.
-- This event occurs after the player has done the "Animal transport" mission.
--]]

require "missions/neutral/common"


start_text = _([[You look at your instruments in confusion as you realize that your ship isn't able to jump or land. Before you can make sense of it, your instruments go haywire and your ship careens out of control. Uh-oh.

You frantically try to work the controls to regain control of your ship, but it's no use. You swear to yourself and hurriedly exit your cockpit to look for the problem, hoping you don't get attacked in your defenseless state while you do so.]])

end_text = _([[You've found the cause of the problem. One of the little rodents you transported for that Siriusite apparently got out of the crate on the way, and gnawed thrû some of your ship's circuitry. The creature died in the ensuing short-circuit. You've fixed the damage, and your ship is under control again.]])

log_text = _([[You found that one of the rodents you transported for that Siriusite got out of the crate on the way, gnawed thrû some of your ship's circuitry, and died from short-circuit caused by said gnawing, which also caused your ship to go haywire. After you fixed the damage, your ship's controls were brought back to normal.]])


function create ()
    if not evt.claim(system.cur()) then
        evt.finish(false)
    end

    pilot.toggleSpawn(false)
    pilot.clear()
    player.pilot():setNoJump()
    player.pilot():setNoLand()
    player.autonavAbort(_("Jumping and landing systems have gone offline."))

    hook.timer(5.0, "startProblems")
    bucks = 3
end


function startProblems()
    tk.msg("", start_text)

    player.cinematics(true, {gui=true})
    player.pilot():control()

    hook.timer(7.0, "buck")
    hook.pilot(player.pilot(), "idle", "continueProblems")
    continueProblems()
end


function continueProblems()
    -- Fly off in a random direction
    dist = 1000
    -- Never deviate more than 90 degrees from the current direction.
    angle = player.pilot():dir() + rnd.uniform(-90, 90)
    newlocation = vec2.newP(dist, angle)

    player.pilot():taskClear()
    player.pilot():moveto(player.pilot():pos() + newlocation, false, false)
end


function buck()
    bucks = bucks - 1
    if bucks == 0 then
        endProblems()
    end
    hook.timer(7.0, "buck")
    continueProblems()
end


function endProblems()
    tk.msg("", end_text)

    pilot.toggleSpawn(true)
    player.cinematics(false)
    player.pilot():control(false)
    player.pilot():setNoJump(false)
    player.pilot():setNoLand(false)

    var.pop("shipinfested")

    addMiscLog(log_text)
    evt.finish(true)
end
