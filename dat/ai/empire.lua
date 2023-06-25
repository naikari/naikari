local fmt = require "fmt"
require "ai/tpl/generic"
require "ai/personality/patrol"

-- Settings
mem.armour_run = 40
mem.armour_return = 70
mem.aggressive = true


function create()
   local p = ai.pilot()
   local sprice = p:ship():price()
   ai.setcredits(rnd.rnd(0.35 * sprice, 0.85 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.15 * sprice)

   -- Get refuel chance
   local standing = p:faction():playerStanding()
   mem.refuel = rnd.rnd(2000, 4000)
   if standing < 20 then
      mem.refuel_no = p_("refuel_no", "\"My fuel is property of the Empire.\"")
   elseif standing < 70 then
      if rnd.rnd() < 0.8 then
         mem.refuel_no = p_("refuel_no", "\"My fuel is property of the Empire.\"")
      end
   else
      mem.refuel = mem.refuel * 0.6
   end
   -- Most likely no chance to refuel
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I suppose I could spare some fuel for {credits}.\""),
      {credits=fmt.credits(mem.refuel)})

   -- See if can be bribed
   if rnd.rnd() < 0.3 then
      mem.bribe = math.sqrt(p:stats().mass) * (500*rnd.rnd() + 1750)
      mem.bribe_prompt = fmt.f(
         p_("bribe_prompt", "\"For {credits} I could forget about seeïng you.\""),
         {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = p_("bribe_paid", "\"Now scram before I change my mind.\"")
   else
      bribe_no = {
         p_("bribe_no", "\"You won't buy your way out of this one.\""),
         p_("bribe_no", "\"The Empire likes to make examples out of scum like you.\""),
         p_("bribe_no", "\"You've made a huge mistake.\""),
         p_("bribe_no", "\"Bribery carries a harsh penalty, scum.\""),
         p_("bribe_no", "\"I'm not interested in your blood money!\""),
         p_("bribe_no", "\"All the money in the world won't save you now!\"")
      }
      mem.bribe_no = bribe_no[rnd.rnd(1, #bribe_no)]
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   -- Finish up creation
   create_post()
end

-- taunts
function taunt ( target, offense )
   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   -- some taunts
   if offense then
      taunts = {
         p_("taunt", "There is no room in this universe for scum like you!"),
         p_("taunt", "The Empire will enjoy your death!"),
         p_("taunt", "Your head will make a fine gift for the Emperor!"),
         p_("taunt", "None survive the wrath of the Emperor!"),
         p_("taunt", "Enjoy your last moments, criminal!"),
      }
   else
      taunts = {
         p_("taunt_defensive", "You dare attack me?!"),
         p_("taunt_defensive", "You are no match for the Empire!"),
         p_("taunt_defensive", "The Empire will have your head!"),
         p_("taunt_defensive", "You'll regret that!"),
         p_("taunt_defensive", "That was a fatal mistake!"),
      }
   end

   ai.pilot():comm(target, taunts[ rnd.rnd(1,#taunts) ])
end


