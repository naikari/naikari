--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Baroncomm_baron">
 <trigger>enter</trigger>
 <chance>20</chance>
 <cond>
  player.misnDone("Teddy Bears from Space")
  and not var.peek("baron_hated")
  and not player.misnDone("Baron")
  and not player.misnActive("Baron")
  and (system.cur():faction() == faction.get("Empire")
     or system.cur():faction() == faction.get("Dvaered")
     or system.cur():faction() == faction.get("Sirius"))
 </cond>
 <flags>
 </flags>
 <notes>
  <done_misn name="Teddy Bears from Space"/>
  <campaign>Baron Sauterfeldt</campaign>
 </notes>
</event>
--]]
--[[
-- Comm Event for the Baron mission string
--]]


function create ()
    local lastcomm = var.peek("baroncomm_last")
    if lastcomm == nil then
        var.push("baroncomm_last", time.get():tonumber())
    else
        if time.get() - time.fromnumber(lastcomm) < time.create(0, 50, 0) then
            evt.finish(false)
        else
            var.push("baroncomm_last", time.get():tonumber())
        end
    end

    hyena = pilot.add("Hyena", "Civilian", true, _("Civilian Hyena"))

    hyena:setNoClear()
    
    hook.pilot(hyena, "jump", "finish")
    hook.pilot(hyena, "death", "finish")
    hook.land("finish")
    hook.jumpout("finish")

    hailie = hook.timer(3.0, "hailme");
end

-- Make the ship hail the player
function hailme()
    hyena:hailPlayer()
    hook.pilot(hyena, "hail", "hail")
end

-- Triggered when the player hails the ship
function hail()
    player.commClose()
    naik.missionStart("Baron")
    evt.finish(true)
end

function finish()
    hook.rm(hailie)
    evt.finish()
end
