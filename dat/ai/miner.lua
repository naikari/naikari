require("ai/tpl/generic")
require("ai/personality/miner")
require("ai/include/distress_behaviour")
local fmt = require "fmt"

mem.armor_localjump = 40


function create()
   local sprice = ai.pilot():value()
   ai.setcredits(rnd.rnd(0.25 * sprice, 0.75 * sprice))
   mem.kill_reward = rnd.rnd(0.01 * sprice, 0.02 * sprice)

   -- No bribe
   local bribe_msg = {
      p_("bribe_no", "\"Just leave me alone!\""),
      p_("bribe_no", "\"What do you want from me!?\""),
      p_("bribe_no", "\"Get away from me!\"")
   }
   mem.bribe_no = bribe_msg[rnd.rnd(1, #bribe_msg)]

   -- Refuel
   mem.refuel = rnd.rnd(1000, 3000)
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I'll supply your ship with fuel for {credits}.\""),
      {credits=fmt.credits(mem.refuel)})

   create_post()
end
