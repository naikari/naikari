require("ai/tpl/generic")
require("ai/personality/civilian")
require("ai/include/distress_behaviour")
local fmt = require "fmt"


mem.careful = false


function create ()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.35 * sprice, 0.85 * sprice))
   mem.kill_reward = rnd.rnd(0.01 * sprice, 0.05 * sprice)

   -- No bribe
   local bribe_msg = {
      p_("bribe_no", "\"Just leave me alone!\""),
      p_("bribe_no", "\"What do you want from me!?\""),
      p_("bribe_no", "\"Get away from me!\"")
   }
   mem.bribe_no = bribe_msg[rnd.rnd(1,#bribe_msg)]

   -- Refuel
   mem.refuel = rnd.rnd(1000, 3000)
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I'll supply your ship with fuel for {credits}.\""),
      {credits=fmt.credits(mem.refuel)})

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system
   create_post()
end

