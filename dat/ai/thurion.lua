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
      p_("sos", "Requesting assistance! We are under attack!"),
      p_("sos", "Vessel under attack! Requesting help!"),
      p_("sos", "Help! Ship under fire!"),
      p_("sos", "Taking hostile fire! Need assistance!"),
      p_("sos", "We are under attack, require support!"),
      p_("sos", "Mayday! Ship taking damage!"),
   }
   ai.settarget(ai.taskdata())
   ai.distress(msg[ rnd.rnd(1,#msg)])
end


function create ()
   local p = ai.pilot()
   local sprice = p:ship():price()
   ai.setcredits(rnd.rnd(0.05 * sprice, 0.1 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.2 * sprice)

   -- No bribe
   local bribe_msg = {
      p_("bribe_no", "\"We will not be bribed!\""),
      p_("bribe_no", "\"I have no use for your money.\""),
      p_("bribe_no", "\"Credits are no replacement for a good shield.\""),
   }
   mem.bribe_no = bribe_msg[ rnd.rnd(1,#bribe_msg) ]

   -- Refuel
   mem.refuel = 0
   mem.refuel_msg = p_("refuel", "\"Sure, I can spare some fuel.\"")

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system
   create_post()
end

