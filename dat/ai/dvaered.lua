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

   -- Handle bribing
   if rnd.rnd() < 0.4 then
      mem.bribe = math.sqrt(ai.pilot():stats().mass) * (500*rnd.rnd() + 1750)
      mem.bribe_prompt = fmt.f(
            _("\"For {credits} I'll pretend I didn't see you.\""),
            {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = _("\"Good. Now get out of my face.\"")
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

   -- Handle refueling
   local p = player.pilot()
   if p:exists() then
      local standing = ai.getstanding(p) or -1
      mem.refuel = rnd.rnd(1000, 3000)
      if standing < 50 then
         mem.refuel_no = _("\"You are not worthy of my attention.\"")
      else
         mem.refuel_msg = fmt.f(
               _("\"For you, I could make an exception for {credits}.\""),
               {credits=fmt.credits(mem.refuel)})
      end
   end

   -- Handle misc stuff
   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   create_post()
end

-- taunts
function taunt ( target, offense )

   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   -- Offense is not actually used
   taunts = {
       _("Prepare to face annihilation!"),
       _("I shall wash my hull in your blood!"),
       _("Your head will make a great trophy!"),
       _("You're no match for the Dvaered!"),
       _("Death awaits you!"),
       _("You have once again intruded on the territory of the Dvaered!"),
   }
   ai.pilot():comm(target, taunts[rnd.rnd(1, #taunts)])
end

