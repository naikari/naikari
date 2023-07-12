require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

-- Settings
mem.aggressive = true


-- Create function
function create()
   local p = ai.pilot()
   local sprice = p:ship():price()
   ai.setcredits(rnd.rnd(0.25 * sprice, 0.75 * sprice))
   mem.kill_reward = rnd.rnd(0.01 * sprice, 0.05 * sprice)

   -- Handle bribing
   local bribe_no = {
      p_("bribe_no", "\"The only way to deal with scum like you is with cannons!\""),
      p_("bribe_no", "\"I don't want your money.\""),
      p_("bribe_no", "\"I'm here for the Frontier, not money.\""),
      p_("bribe_no", "\"Not interested.\""),
      p_("bribe_no", "\"I won't let you off that easily.\""),
   }
   mem.bribe_no = bribe_no[rnd.rnd(1,#bribe_no)]

   -- Handle refueling
   local standing = p:faction():playerStanding()
   local flf_standing = faction.get("FLF"):playerStanding()

   mem.refuel = rnd.rnd(1000, 3000)
   if flf_standing < 50 then
      mem.refuel_no = p_("refuel_no", "\"Sorry, I can't spare fuel for you.\"")
   elseif standing < 50 then
      mem.refuel_msg = fmt.f(
         p_("refuel_prompt", "\"Sure, just {credits} and I'll give you some fuel.\""),
         {credits=fmt.credits(mem.refuel)})
   else
      mem.refuel = 0
      mem.refuel_msg = p_("refuel", "\"Sure, friend, I can refuel you. On my way.\"")
   end

   -- Handle misc stuff
   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass thrû before leaving the system

   create_post()
end

-- taunts
function taunt(target, offense)

   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   if offense then
      taunts = {
         p_("taunt", "For the Frontier!"),
         p_("taunt", "You'll make great target practice!"),
         p_("taunt", "You won't get away with your actions!"),
      }
   else
      taunts = {
         p_("taunt_defensive", "Frontier vessel under attack! Requesting assistance!"),
         p_("taunt_defensive", "You'll regret that!"),
         p_("taunt_defensive", "I won't go down without a fight!"),
         p_("taunt_defensive", "To hell with you!"),
         p_("taunt_defensive", "You won't get away with this!"),
      }
   end
   ai.pilot():comm(target, taunts[rnd.rnd(1,#taunts)])
end

