--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Tutorial System Claimer">
 <priority>98</priority>
 <trigger>enter</trigger>
 <chance>100</chance>
 <cond>player.misnActive("Combat Practice")</cond>
</event>
--]]
--[[
   Tutorial System Claimer

   Attempts to claim the current system if a tutorial mission needs one.
   If successful, sets a flag indicating to the mission that it may
   proceed.
--]]


function create()
   if evt.claim(system.cur()) then
      if player.misnActive("Combat Practice") then
         naik.hookTrigger("tutcombat_start")
      end
   end

   -- Finish on the safe hook to ensure that the system claim blocks
   -- lower-priority events (namely the mercenary event).
   hook.safe("safe_finish")
end


function safe_finish()
   evt.finish()
end
