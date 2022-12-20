require("ai/tpl/generic")
require("ai/personality/trader")
require("ai/include/distress_behaviour")
local fmt = require "fmt"


function create()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.25 * sprice, 0.75 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.2 * sprice)

   -- No bribe
   local bribe_msg = {
      _("\"Just leave me alone!\""),
      _("\"What do you want from me!?\""),
      _("\"Get away from me!\"")
   }
   mem.bribe_no = bribe_msg[rnd.rnd(1, #bribe_msg)]

   -- Communication stuff
   mem.refuel = rnd.rnd(3000, 5000)
   local p = player.pilot()
   if p:exists() then
      if player.jumps() < 1 then
         mem.refuel = math.min(mem.refuel, player.credits())
      end
      if mem.refuel > 0 then
         mem.refuel_msg = fmt.f(
               _("\"I'll supply your ship with fuel for {credits}.\""),
               {credits=fmt.credits(mem.refuel)})
      else
         mem.refuel_msg = _("\"Alright, I'll give you some fuel.\"")
      end
   end

   -- Finish up creation
   create_post()
end
