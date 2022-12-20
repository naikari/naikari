require("ai/tpl/generic")
require("ai/personality/civilian")
require("ai/include/distress_behaviour")
local fmt = require "fmt"


function create()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.5 * sprice, 1 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.2 * sprice)

   -- No bribe
   local bribe_msg = {
      _("\"Just leave me alone!\""),
      _("\"What do you want from me!?\""),
      _("\"Get away from me!\"")
   }
   mem.bribe_no = bribe_msg[rnd.rnd(1, #bribe_msg)]

   -- Refuel
   mem.refuel = math.min(rnd.rnd(1000, 3000), player.credits())
   local p = player.pilot()
   if p:exists() then
      if mem.refuel > 0 then
         mem.refuel_msg = fmt.f(
               _("\"I'll supply your ship with fuel for {credits}.\""),
               {credits=fmt.credits(mem.refuel)})
      else
         mem.refuel_msg = _("\"Alright, I'll give you some fuel.\"")
      end
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system
   create_post()
end

