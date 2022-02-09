local fmt = require "fmt"
require "ai/tpl/generic"
require "ai/personality/civilian"


mem.shield_run = 100
mem.armour_run = 100
mem.defensive = false
mem.enemyclose = 500
mem.careful = true


function create ()
   sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(sprice / 500, sprice / 200))

   -- No bribe
   local bribe_msg = {
      _("\"Just leave me alone!\""),
      _("\"What do you want from me!?\""),
      _("\"Get away from me!\"")
   }
   mem.bribe_no = bribe_msg[ rnd.rnd(1,#bribe_msg) ]

   -- Refuel
   mem.refuel = rnd.rnd( 1000, 3000 )
   local p = player.pilot()
   if p:exists() then
      mem.refuel_msg = fmt.f(
            _("\"I'll supply your ship with fuel for {credits}.\""),
            {credits=fmt.credits(mem.refuel)})
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system
   create_post()
end

