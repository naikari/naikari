local fmt = require "fmt"
require("ai/tpl/generic")
require("ai/personality/patrol")

-- Settings
mem.control_rate = 0.5 -- Lower control rate
mem.aggressive = true
mem.land_planet = false

function create ()
   local p = ai.pilot()
   local sprice = p:ship():price()
   mem.kill_reward = rnd.rnd(0.15 * sprice, 0.25 * sprice)

   -- No response by default.
   mem.comm_no = _("No response.")

   -- Refuel available if the player is at least neutral to them.
   local pp = player.pilot()
   if pp:exists() then
      local standing = ai.getstanding(pp) or -1
      if standing >= 0 then
         mem.comm_no = nil
         mem.bribe_no = fmt.f(_("{pilot} does not respond."), {pilot=p:name()})
         mem.refuel = 0
         mem.refuel_msg = _("\"Fuel request accepted. Approaching for fuel transfer.\"")
         mem.refuel_cannot = _("\"Refuel request declined. Insufficient fuel available.\"")
      end
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   create_post()
end
