--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Prowling baron">
 <trigger>enter</trigger>
 <priority>100</priority>
 <chance>100</chance>
 <cond>system.cur() == system.get("Ingot")</cond>
 <flags>
 </flags>
 <notes>
  <campaign>Baron Sauterfeldt</campaign>
 </notes>
</event>
--]]
--[[
-- Prowl Event for the Baron mission string. Only used when NOT doing any Baron missions.
--]]

function create()
    baronship = pilot.add("Proteron Kahan", "Civilian",
         planet.get("Ulios"):pos() + vec2.new(-400,-400), _("Pinnacle"),
         {ai="trader"})
    baronship:setInvincible(true)
    baronship:setFriendly()
    baronship:setSpeedLimit(100)
    baronship:control()
    baronship:moveto(planet.get("Ulios"):pos() + vec2.new( 500, -500), false, false)
    hook.pilot(baronship, "idle", "idle")
end

function idle()
    baronship:moveto(planet.get("Ulios"):pos() + vec2.new( 500,  500), false, false)
    baronship:moveto(planet.get("Ulios"):pos() + vec2.new(-500,  500), false, false)
    baronship:moveto(planet.get("Ulios"):pos() + vec2.new(-500, -500), false, false)
    baronship:moveto(planet.get("Ulios"):pos() + vec2.new( 500, -500), false, false)
end
