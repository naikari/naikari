require("ai/tpl/generic")
require("ai/personality/civilian")
require "numstring"


mem.shield_run = 20
mem.armour_run = 20
mem.defensive  = true
mem.enemyclose = 500
mem.distressmsgfunc = sos


-- Sends a distress signal which causes faction loss
function sos ()
   msg = {
      _("Local security: requesting assistance!"),
      _("Requesting assistance. We are under attack!"),
      _("Vessel under attack! Requesting help!"),
      _("Help! Ship under fire!"),
      _("Taking hostile fire! Need assistance!"),
      _("We are under attack, require support!"),
      _("Mayday! Ship taking damage!"),
      _("0x556e6465722061747461636b21") -- "Under attack!" in hexadecimal
   }
   ai.settarget( ai.taskdata() )
   ai.distress( msg[ rnd.int(1,#msg) ])
end


function create ()

   -- Credits.
   ai.setcredits( rnd.int(ai.pilot():ship():price()/500, ai.pilot():ship():price()/200) )

   -- No bribe
   local bribe_msg = {
      _("\"The Thurion will not be bribed!\""),
      _("\"I have no use for your money.\""),
      _("\"Credits are no replacement for a good shield.\"")
   }
   mem.bribe_no = bribe_msg[ rnd.int(1,#bribe_msg) ]

   -- Refuel
   mem.refuel = 0
   local p = player.pilot()
   if p:exists() then
      standing = ai.getstanding( p ) or -1
      mem.refuel_msg = string.format(_("\"I'll supply your ship with fuel for %s.\""),
            creditstring(mem.refuel));
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system
   create_post()
end

