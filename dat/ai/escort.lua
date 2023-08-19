require "ai.tpl.generic"


-- Settings
mem.distress = false
mem.aggressive = true
mem.protector = false
mem.norun = true
mem.carrier = true
mem.comm_no = p_("comm_no", "No response.")
mem.enemyclose = 6000
mem.leadermaxdist = 16000


function create()
   local p = ai.pilot()
   local leader = p:leader()

   if leader ~= nil and leader:exists() then
      local leadermem = leader:memory()
      mem.protector = leadermem.protector
   end

   -- Player escorts perform local jumps, others don't.
   if leader == player.pilot() then
      mem.armor_localjump = 70
   end

   attack_choose()
end


function idle()
   -- Just tries to guard mem.escort
   ai.pushtask("follow_fleet")
end
