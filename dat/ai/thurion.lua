require("ai/tpl/generic")
require("ai/personality/civilian")


mem.shield_run = 20
mem.armour_run = 20
mem.defensive  = true
mem.enemyclose = 500
mem.distressmsgfunc = sos


-- Sends a distress signal which causes faction loss
function sos ()
   msg = {
      _("Requesting assistance. We are under attack!"),
      _("Vessel under attack! Requesting help!"),
      _("Help! Ship under fire!"),
      _("Taking hostile fire! Need assistance!"),
      _("We are under attack, require support!"),
      _("Mayday! Ship taking damage!"),
   }
   ai.settarget(ai.taskdata())
   ai.distress(msg[ rnd.rnd(1,#msg)])
end


function create ()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.05 * sprice, 0.1 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.2 * sprice)

   -- No bribe
   local bribe_msg = {
      _("\"We will not be bribed!\""),
      _("\"I have no use for your money.\""),
      _("\"Credits are no replacement for a good shield.\""),
   }
   mem.bribe_no = bribe_msg[ rnd.rnd(1,#bribe_msg) ]

   -- Refuel
   local p = player.pilot()
   if p:exists() then
      mem.refuel = 0
      mem.refuel_msg = _("\"Sure, I can spare some fuel.\"")
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system
   create_post()
end

