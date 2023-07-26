local fmt = require "fmt"
require("ai/tpl/generic")
require("ai/personality/patrol")

-- Settings
mem.control_rate = 0.5 -- Lower control rate
mem.aggressive = true
mem.atk_kill = true
mem.land_planet = false
mem.comm_no = p_("comm_no", "No response.")

function create ()
   local p = ai.pilot()
   local sprice = p:ship():price()
   mem.kill_reward = rnd.rnd(0.15 * sprice, 0.25 * sprice)

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass thru before leaving the system

   create_post()
end
