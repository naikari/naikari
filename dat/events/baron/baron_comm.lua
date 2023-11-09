--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Baroncomm_baron">
 <trigger>enter</trigger>
 <chance>20</chance>
 <cond>
  player.misnDone("Teddy Bears from Space")
  and not player.misnDone("Baron")
  and not player.misnActive("Baron")
  and (system.cur():faction() == faction.get("Empire")
     or system.cur():faction() == faction.get("Dvaered")
     or system.cur():faction() == faction.get("Za'lek")
     or system.cur():faction() == faction.get("Sirius")
     or system.cur():faction() == faction.get("Goddard")
     or system.cur():faction() == faction.get("Frontier")
     or system.cur():faction() == faction.get("Soromid"))
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
    local wait_time = time.create(1, 0, 0)
    if lastcomm ~= nil
            and time.get() - time.fromnumber(lastcomm) < wait_time then
        evt.finish(false)
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
    var.push("baroncomm_last", time.get():tonumber())
    player.commClose()
    naik.missionStart("Baron")
    evt.finish(true)
end

function finish()
    hook.rm(hailie)
    evt.finish()
end
