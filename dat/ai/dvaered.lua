require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

-- Settings
mem.armour_run = 20
mem.armour_return = 70
mem.aggressive = true
mem.atk_kill = true


-- Create function
function create ()
   local p = ai.pilot()
   local sprice = p:ship():price()
   ai.setcredits(rnd.rnd(0.35 * sprice, 0.85 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.15 * sprice)

   -- Handle bribing
   if rnd.rnd() < 0.4 then
      mem.bribe = math.sqrt(p:stats().mass) * (500*rnd.rnd() + 1750)
      mem.bribe_prompt = fmt.f(
         p_("bribe_prompt", "\"For {credits} I'll pretend I didn't see you.\""),
         {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = p_("bribe_paid", "\"Good. Now get out of my face.\"")
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

   -- Handle refueling
   local standing = p:faction():playerStanding()
   mem.refuel = rnd.rnd(1000, 3000)
   if standing < 50 then
      mem.refuel_no = p_("refuel_no", "\"You are not worthy of my attention.\"")
   else
      mem.refuel_msg = fmt.f(
         p_("refuel_prompt", "\"For you, I could make an exception for {credits}.\""),
         {credits=fmt.credits(mem.refuel)})
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

   -- Offense is not actually used
   taunts = {
      p_("taunt", "Prepare to face annihilation!"),
      p_("taunt", "I will wash my hull in your blood!"),
      p_("taunt", "Your head will make a great trophy!"),
      p_("taunt", "You're no match for us!"),
      p_("taunt", "Death awaits you!"),
      p_("taunt", "Death to all who oppose us!"),
      p_("taunt", "Eat flaming death, you gravy-sucking pig!"),
   }
   if faction.get("Dvaered"):playerStanding() < 0 then
      table.insert(taunts, p_("taunt", "Now you must pay for your crimes!"))
      table.insert(taunts, p_("taunt", "You're no match for the Dvaered!"))
      table.insert(taunts, p_("taunt", "Criminal scum! You die!"))
   end
   ai.pilot():comm(target, taunts[rnd.rnd(1, #taunts)])
end

