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

   -- Refuel available if the player is at least neutral to them.
   if p:faction():playerStanding() >= 0 then
      mem.bribe_no = fmt.f(_("{pilot} does not respond."), {pilot=p:name()})
      mem.refuel = 0
      mem.refuel_msg = _("\"Fuel request accepted. Approaching for fuel transfer.\"")
      mem.refuel_cannot = _("\"Refuel request declined. Insufficient fuel available.\"")
   else
      mem.comm_no = _("No response.")
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   create_post()
end
