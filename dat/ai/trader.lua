require("ai/tpl/generic")
require("ai/personality/trader")
require("ai/include/distress_behaviour")
local fmt = require "fmt"

mem.armor_localjump = 40


function create()
   local p = ai.pilot()
   local sprice = p:ship():price()
   ai.setcredits(rnd.rnd(0.25 * sprice, 0.75 * sprice))
   mem.kill_reward = rnd.rnd(0.01 * sprice, 0.05 * sprice)

   -- No bribe
   local bribe_msg = {
      p_("bribe_no", "\"Just leave me alone!\""),
      p_("bribe_no", "\"What do you want from me!?\""),
      p_("bribe_no", "\"Get away from me!\"")
   }
   mem.bribe_no = bribe_msg[rnd.rnd(1, #bribe_msg)]

   -- Communication stuff
   mem.refuel = rnd.rnd(3000, 5000)
   if player.pilot():exists() and player.jumps() < 1 then
      mem.refuel = math.min(mem.refuel, player.credits())
   end
   if mem.refuel > 0 then
      mem.refuel_msg = fmt.f(
         p_("refuel_prompt", "\"I'll supply your ship with fuel for {credits}.\""),
         {credits=fmt.credits(mem.refuel)})
   else
      mem.refuel_msg = p_("refuel", "\"Alright, I'll give you some fuel.\"")
   end

   -- Finish up creation
   create_post()
end
