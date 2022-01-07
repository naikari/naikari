--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Shadowcomm2">
 <trigger>enter</trigger>
 <chance>3</chance>
 <cond>system.cur():presence("hostile") &lt; 300 and player.misnDone("Shadow Vigil") and not player.misnDone("Dark Shadow") and not player.misnActive("Dark Shadow")</cond>
 <flags>
 </flags>
 <notes>
  <done_misn name="Shadow Vigil"/>
  <campaign>Shadow</campaign>
 </notes>
</event>
--]]
--[[
-- Comm Event for the Shadow missions
--]]


function create ()
    hook.timer(20.0, "timer")

    landhook = hook.land("finish")
    jumpouthook = hook.jumpout("finish")
end


function timer()
    naev.missionStart("Dark Shadow")
    player.commClose()
    evt.finish()
end


function finish()
    evt.finish()
end
