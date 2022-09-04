require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

-- Settings
mem.aggressive = true


-- Create function
function create ()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.35 * sprice, 0.85 * sprice))
   mem.kill_reward = rnd.rnd(0.25 * sprice, 0.75 * sprice)

   -- Bribing
   if rnd.rnd() < 0.2 then
      mem.bribe = math.sqrt(ai.pilot():stats().mass) * (500*rnd.rnd() + 1750)
      mem.bribe_prompt = fmt.f(
            _("\"Hm, transfer over {credits} and I'll forget I saw you.\""),
            {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = _("\"Get out of my sight before I change my mind.\"")
   else
      bribe_no = {
         _("\"You insult my honor.\""),
         _("\"I find your lack of honor disturbing.\""),
         _("\"You disgust me.\""),
         _("\"Bribery carries a harsh penalty.\""),
         _("\"We do not lower ourselves to common scum.\""),
         _("\"I will especially enjoy your death!\""),
      }
      mem.bribe_no = bribe_no[rnd.rnd(1, #bribe_no)]
   end

   -- Refueling
   local p = player.pilot()
   if p:exists() then
      local standing = ai.getstanding( p ) or -1
      mem.refuel = rnd.rnd( 2000, 4000 )
      if standing > 60 then mem.refuel = mem.refuel * 0.7 end
      mem.refuel_msg = fmt.f(
            _("\"I could do you the favor of refueling for {credits}.\""),
            {credits=fmt.credits(mem.refuel)})
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   -- Finish up creation
   create_post()
end

-- taunts
function taunt(target, offense)
   -- Offense is not actually used
   taunts = {
         _("Prepare to face annihilation!"),
         _("Your head will make a great trophy!"),
         _("These moments will be your last!"),
         _("Parasite! You die!"),
         _("Prepare to face the wrath of House Goddard!"),
   }
   ai.pilot():comm(target, taunts[rnd.rnd(1,#taunts)])
end

