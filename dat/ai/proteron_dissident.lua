local fmt = require "fmt"
require "ai/tpl/generic"
require "ai/personality/civilian"


mem.shield_run = 100
mem.armour_run = 100
mem.defensive = false
mem.enemyclose = 500
mem.careful = true


function create()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.05 * sprice, 0.1 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.2 * sprice)

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

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass thru before leaving the system
   create_post()
end

