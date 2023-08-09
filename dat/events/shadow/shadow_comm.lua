--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Shadowcomm">
 <trigger>enter</trigger>
 <chance>3</chance>
 <cond>
   system.cur():presence("hostile") &lt; 300
   and player.misnDone("Shadowrun")
   and not player.misnDone("Shadow Vigil")
   and not player.misnActive("Shadow Vigil")
   and system.cur() ~= system.get("Pas")
 </cond>
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


function create ()
    -- Create a Vendetta who hails the player after a bit
    hail_time = nil
    local f = faction.dynAdd("Mercenary", N_("Four Winds"))
    vendetta = pilot.add("Vendetta", f, true, _("Four Winds Vendetta"),
            {ai="trader"})
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
    vendetta:control(false)

    naik.missionStart("Shadow Vigil")
    evt.finish()
end

function leave()
    evt.finish()
end
