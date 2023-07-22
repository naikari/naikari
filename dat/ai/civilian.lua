require("ai/tpl/generic")
require("ai/personality/civilian")
require("ai/include/distress_behaviour")
local fmt = require "fmt"

mem.armor_localjump = 40


function create()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.5 * sprice, 1 * sprice))

   -- No bribe
   local bribe_msg = {
      p_("bribe_no", "\"Just leave me alone!\""),
      p_("bribe_no", "\"What do you want from me!?\""),
      p_("bribe_no", "\"Get away from me!\"")
   }
   mem.bribe_no = bribe_msg[rnd.rnd(1, #bribe_msg)]

   -- Refuel
   mem.refuel = math.min(rnd.rnd(1000, 3000), player.credits())
   if mem.refuel > 0 then
      mem.refuel_msg = fmt.f(
         p_("refuel_prompt", "\"I'll supply your ship with fuel for {credits}.\""),
         {credits=fmt.credits(mem.refuel)})
   else
      mem.refuel_msg = p_("refuel", "\"Alright, I'll give you some fuel.\"")
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass thru before leaving the system
   create_post()
end

