--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Shipwreck">
 <trigger>enter</trigger>
 <chance>100</chance>
 <cond>system.cur():presence("Pirate") &gt; 0 and not player.misnDone("The Space Family") and not player.misnActive("The Space Family")</cond>
 <notes>
  <campaign>Tutorial</campaign>
 </notes>
</event>
--]]
--[[
-- Shipwreck Event
-- 
-- Creates a wrecked ship that asks for help. If the player boards it, the event switches to the Space Family mission.
-- See dat/missions/neutral/spacefamily
-- 
-- 12/02/2010 - Added visibility/highlight options for use in big systems (Anatolis)
--]]

-- Text
broadcastmsg = _("Mayday! This is the August. We are shipwrecked. Please #bboard#0 us by #bdouble-clicking#0 on our ship.")

function create()
    local nebu_dens, nebu_vol = system.cur():nebula()
    if nebu_vol > 0 then
        evt.finish()
    end

    -- This non-standard way of checking chance ensures that it always
    -- shows up immediately when entering pirate-infested space at least
    -- once.
    if var.peek("shipwreck_repeated") and rnd.rnd() >= 0.25 then
        evt.finish()
    end

    -- Choose position and make sure it's not too close to a planet or
    -- jump.
    local cursys = system.cur()
    local angle = rnd.rnd() * 2 * math.pi
    local dist = rnd.rnd(0, cursys:radius() / 2)
    local pos = vec2.new(dist * math.cos(angle), dist * math.sin(angle))
    local planets = cursys:planets()
    for i = 1, #planets do
        local pnt = planets[i]
        if vec2.dist(pos, pnt:pos()) < pnt:radius() * 3 then
            evt.finish()
        end
    end
    local jumps = cursys:jumps()
    for i = 1, #jumps do
        local jmp = jumps[i]
        if vec2.dist(pos, jmp:pos()) < jmp:radius() * 3 then
            evt.finish()
        end
    end

    var.push("shipwreck_repeated", true)

    -- The shipwreck will be a random trader vessel.
    r = rnd.rnd()
    if r > 0.8 then
        ship = "Mule"
    elseif r > 0.5 then
        ship = "Koäla"
    else 
        ship = "Llama"
    end

    -- Create the derelict.
    local f = faction.dynAdd(nil, "Derelict", N_("Trader"), {ai="trader"})
    local p = pilot.add(ship, f, pos, _("Shipwrecked August"),
            {ai="dummy"})
    p:disable()
    -- Added extra visibility for big systems (A.)
    p:setVisplayer()
    p:setHilight()
    p:setNoClear()

    hook.timer(3, "broadcast", p)

    -- Set hooks
    hook.pilot(p, "board", "rescue")
    hook.pilot(p, "death", "endevent")
    hook.enter("endevent")
    hook.land("endevent")
end

function broadcast(p)
    if p == nil or not p:exists() then
        return
    end
    p:broadcast(broadcastmsg, true)
    bctimer = hook.timer(15, "broadcast", p)
end

function rescue(p, boarder)
    if boarder ~= player.pilot() then
        return
    end
    -- Player boards the shipwreck and rescues the crew, this spawns a new mission.
    hook.rm(bctimer)
    naik.missionStart("The Space Family")
    p:setVisplayer(false)
    p:setHilight(false)
    evt.finish()
end


function endevent ()
    evt.finish()
end
