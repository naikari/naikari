--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Prowling baron">
 <trigger>enter</trigger>
 <priority>99</priority>
 <chance>100</chance>
 <cond>system.cur() == system.get("Ingot")</cond>
 <notes>
  <campaign>Baron Sauterfeldt</campaign>
 </notes>
</event>
--]]
--[[
-- Prowl Event for the Baron mission string. Only used when NOT doing any Baron missions.
--]]

function create()
    pla, sys = planet.get("Ulios")
    if not evt.claim(sys) then
        evt.finish(false)
    end

    baronship = pilot.add("Proteron Kahan", "Civilian",
            pla:pos() + vec2.new(-400,-400), _("Pinnacle"), {ai="trader"})
    baronship:setInvincible(true)
    baronship:setFriendly()
    baronship:setSpeedLimit(100)
    baronship:control()
    baronship:moveto(pla:pos() + vec2.new( 500, -500), false, false)
    hook.pilot(baronship, "idle", "idle")
end

function idle()
    baronship:moveto(pla:pos() + vec2.new( 500,  500), false, false)
    baronship:moveto(pla:pos() + vec2.new(-500,  500), false, false)
    baronship:moveto(pla:pos() + vec2.new(-500, -500), false, false)
    baronship:moveto(pla:pos() + vec2.new( 500, -500), false, false)
end
