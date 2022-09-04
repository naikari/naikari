require("ai/tpl/generic")

-- Don't run away from master ship
mem.norun = true
mem.carrier = true -- Is a carried fighter
mem.comm_no = _("No response.")

-- Simple create function
function create ()
   attack_choose()

   -- Disable thinking
   --mem.atk_think = nil
end

-- Just tries to guard mem.escort
function idle ()
   ai.pushtask("follow_fleet")
end
