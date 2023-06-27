require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

-- Settings
mem.aggressive = true


-- Create function
function create ()
   local p = ai.pilot()
   local sprice = p:value()
   ai.setcredits(rnd.rnd(0.35 * sprice, 0.85 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.15 * sprice)

   -- Bribing
   if rnd.rnd() < 0.2 then
      mem.bribe = math.sqrt(p:stats().mass) * (500*rnd.rnd() + 1750)
      mem.bribe_prompt = fmt.f(
         p_("bribe_prompt", "\"Hm, transfer over {credits} and I'll forget I saw you.\""),
         {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = p_("bribe_paid", "\"Get out of my sight before I change my mind.\"")
   else
      bribe_no = {
         p_("bribe_no", "\"You insult my honor.\""),
         p_("bribe_no", "\"I find your lack of honor disturbing.\""),
         p_("bribe_no", "\"You disgust me.\""),
         p_("bribe_no", "\"Bribery carries a harsh penalty.\""),
         p_("bribe_no", "\"We do not lower ourselves to common scum.\""),
         p_("bribe_no", "\"I will especially enjoy your death!\""),
      }
      mem.bribe_no = bribe_no[rnd.rnd(1, #bribe_no)]
   end

   -- Refueling
   local standing = p:faction():playerStanding()
   mem.refuel = rnd.rnd(2000, 4000)
   if standing > 60 then mem.refuel = mem.refuel * 0.7 end
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I could do you the favor of refueling for {credits}.\""),
      {credits=fmt.credits(mem.refuel)})

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   -- Finish up creation
   create_post()
end

-- taunts
function taunt(target, offense)
   -- Offense is not actually used
   taunts = {
      p_("taunt", "Prepare to face annihilation!"),
      p_("taunt", "Your head will make a great trophy!"),
      p_("taunt", "These moments will be your last!"),
      p_("taunt", "Parasite! You die!"),
      p_("taunt", "Prepare to face the wrath of House Goddard!"),
   }
   ai.pilot():comm(target, taunts[rnd.rnd(1,#taunts)])
end

