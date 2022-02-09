require("ai/tpl/generic")
require("ai/personality/miner")
require("ai/include/distress_behaviour")
require "numstring"


function create ()
   sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(sprice / 100, sprice / 25))

   -- Communication stuff
   mem.bribe_no = _("\"I don't want any problem.\"")

   -- Refuel
   mem.refuel = rnd.rnd( 1000, 3000 )
   local p = player.pilot()
   if p:exists() then
      mem.refuel_msg = string.format(_("\"I'll supply your ship with fuel for %s.\""),
            creditstring(mem.refuel));
   end

   create_post()
end
