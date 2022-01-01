--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Shadowcomm">
 <trigger>enter</trigger>
 <chance>3</chance>
 <cond>system.cur():presence("hostile") &lt; 300 and player.misnDone("Shadowrun") and not (player.misnDone("Shadow Vigil") or player.misnActive("Shadow Vigil")) and system.cur() ~= system.get("Pas")</cond>
 <notes>
  <done_misn name="Shadowrun"/>
  <campaign>Shadow</campaign>
 </notes>
</event>
--]]
--[[
-- Comm Event for the Shadow missions
--]]

local fmt = require "fmt"
require "proximity"
require "missions/shadow/common"


ask_text = _([["Greetings, {player}," the pilot of the Vendetta says to you as soon as you answer his hail. "I have been looking for you on behalf of an acquaintance of yours. She wishes to meet with you at a place of her choosing, and a time of yours. It involves a proposition that you might find interesting if you don't mind sticking your neck out." You frown at that, but ask the pilot where this acquaintance wishes you to go anyway.

"Fly to the {system} system," he replies. "She will meet you there. There's no rush, but I suggest you go see her at the earliest opportunity." The screen blinks out and the Vendetta goes about its business, paying you no more attention. It seems there's someone out there who wants to see you, and there's only one way to find out what about. Will you respond to the invitation?]])

log_text = _([[Someone has invited you to meet with her in the Pas system, supposedly an acquaintance of yours. The pilot who told you this said that there's no rush, "but I suggest you go see her at the earliest opportunity".]])


function create ()
     -- Claim: duplicates the claims in the mission.
    misssys = {system.get("Qex"), system.get("Shakar"), system.get("Borla"), system.get("Doranthex")}
    if not evt.claim(misssys) then
        abort()
    end

    sys = system.get("Pas")

    -- Create a Vendetta who hails the player after a bit
    hail_time = nil
    vendetta = pilot.add( "Vendetta", "Four Winds", true, _("Four Winds Vendetta"), {ai="trader"} )
    vendetta:control()
    vendetta:follow(player.pilot())
    hook.timer(0.5, "proximityScan", {focus = vendetta, funcname = "hailme"})

    -- Clean up on events that remove the Vendetta from the game
    hook1 = hook.pilot(vendetta, "jump", "leave")
    hook2 = hook.pilot(vendetta, "death", "leave")
    hook3 = hook.land("leave")
    hook4 = hook.jumpout("leave")
end

-- Make the ship hail the player
function hailme()
    vendetta:hailPlayer()
    hailhook = hook.pilot(vendetta, "hail", "hail")
end

-- Triggered when the player hails the ship
function hail(p)
    player.commClose()
    hook.rm(hailhook)
    vendetta:control()
    vendetta:hyperspace()

    if tk.yesno("", fmt.f(ask_text,
                {player=player.name(), system=sys:name()})) then
        shadow_addLog( log_text )
        naev.missionStart("Shadow Vigil")
    end
    evt.finish()
end

function leave()
    evt.finish()
end
