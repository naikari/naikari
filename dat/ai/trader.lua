require("ai/tpl/generic")
require("ai/personality/trader")
require("ai/include/distress_behaviour")
require "numstring"


function create ()
   sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(sprice / 100, sprice / 25))

   -- Communication stuff
   mem.bribe_no = _("\"The Space Traders do not negotiate with criminals.\"")
   mem.refuel = rnd.rnd( 3000, 5000 )
   p = player.pilot()
   if p:exists() then
      mem.refuel_msg = string.format(_("\"I'll supply your ship with fuel for %s.\""),
            creditstring(mem.refuel));
   end

   -- Finish up creation
   create_post()
end
