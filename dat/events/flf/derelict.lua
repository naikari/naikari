--[[
<?xml version='1.0' encoding='utf8'?>
<event name="FLF/DV Derelicts">
 <trigger>enter</trigger>
 <priority>19</priority>
 <chance>5</chance>
 <cond>
   faction.get("Dvaered"):playerStanding() &gt;= 0
   and faction.get("Pirate"):playerStanding() &lt; 0
   and system.cur():presences()["FLF"]
   and system.cur():presences()["Dvaered"]
   and not system.cur():presences()["Frontier"]
   and not player.misnDone("Take the Dvaered crew home")
   and not player.misnDone("Deal with the FLF agent")
   and not player.misnActive("Deal with the FLF agent")
   and not player.misnActive("Take the Dvaered crew home")
   and player.numOutfit("Mercenary License") &gt; 0
 </cond>
</event>
--]]
--[[
-- Derelict Event, spawning either the FLF prelude mission string or the Dvaered anti-FLF string.
--]]


broadcastmsgDV = _("SOS! Dvaered anti-terrorist patrol ship in need of assistance. Primary systems down. Authorization given to board us for rescue.")
broadcastmsgFLF = _("Calling all ships! Frontier scout here. Engines down, ship damaged. Please help.")


function create()
    if not evt.claim(system.cur()) then
        evt.finish(false)
    end

    local firstcomm = var.peek("flfderelict_first")
    if firstcomm == nil then
        var.push("flfderelict_first", time.get():tonumber())
        evt.finish(false)
    else
        firstcomm = time.fromnumber(firstcomm)
        if time.get() - firstcomm < time.create(0, 30, 0) then
            evt.finish(false)
        end
    end

    -- Create the derelicts One Dvaered, one FLF.
    pilot.toggleSpawn(false)
    pilot.clear()
    
    posDV = vec2.new(7400, 3000)
    posFLF = vec2.new(-10500, -8500)
    
    shipDV = pilot.add("Dvaered Vendetta", "Dvaered", posDV, nil, {ai="dummy"})
    shipFLF = pilot.add("Vendetta", "FLF", posFLF, _("Frontier Vendetta"),
            {ai="dummy"})
    
    shipDV:disable()
    shipFLF:disable()
    
    shipDV:setHilight(true)
    shipFLF:setHilight(true)
    
    shipDV:setVisplayer()
    shipFLF:setVisplayer()

    timerDV = hook.timer(3.0, "broadcastDV")
    timerFLF = hook.timer(12.0, "broadcastFLF")

    boarded = false
    destroyed = false

    -- Set a bunch of vars, for no real reason
    var.push("flfbase_sysname", "Sigur") -- Caution: if you change this, change the location for base Sindbad in unidiff.xml as well!
    
    hook.pilot(shipDV, "board", "boardDV")
    hook.pilot(shipDV, "death", "deathDV")
    hook.pilot(shipFLF, "board", "boardFLF")
    hook.pilot(shipFLF, "death", "deathFLF")
    hook.enter("enter")
end

function broadcastDV()
    -- Ship broadcasts an SOS every 10 seconds, until boarded or destroyed.
    shipDV:broadcast(broadcastmsgDV, true)
    timerDV = hook.timer(20.0, "broadcastDV")
end

function broadcastFLF()
    -- Ship broadcasts an SOS every 10 seconds, until boarded or destroyed.
    shipFLF:broadcast(broadcastmsgFLF, true)
    timerFLF = hook.timer(20.0, "broadcastFLF")
end

function boardFLF(p, boarder)
    if boarder ~= player.pilot() then
        return
    end
    if shipDV:exists() then
        shipDV:setHilight(false)
        shipDV:setNoBoard(true)
    end
    shipFLF:setHilight(false)
    hook.rm(timerFLF)
    hook.rm(timerDV)
    player.unboard()
    naik.missionStart("Deal with the FLF agent")
    boarded = true
end

function deathDV()
    hook.rm(timerDV)
    destroyed = true
    if not shipFLF:exists() then
        evt.finish(true)
    end
end

function boardDV(p, boarder)
    if boarder ~= player.pilot() then
        return
    end
    if shipFLF:exists() then
        shipFLF:setHilight(false)
        shipFLF:setNoBoard(true)
    end
    shipDV:setHilight(false)
    hook.rm(timerDV)
    hook.rm(timerFLF)
    player.unboard()
    naik.missionStart("Take the Dvaered crew home")
    boarded = true
end

function deathFLF()
    hook.rm(timerFLF)
    destroyed = true
    var.push("flfbase_flfshipkilled", true)
    if not shipDV:exists() then
        evt.finish(true)
    end
end

function enter()
    if boarded == true then
        evt.finish(true)
    else
        evt.finish(false)
    end
end
