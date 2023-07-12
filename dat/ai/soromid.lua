require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

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
      mem.refuel_no = p_("refuel_no", "\"The warriors of Sorom are not your personal refueller.\"")
   elseif standing < 70 then
      if rnd.rnd() < 0.8 then
         mem.refuel_no = p_("refuel_no", "\"The warriors of Sorom are not your personal refueller.\"")
      end
   else
      mem.refuel = mem.refuel * 0.6
   end
   -- Most likely no chance to refuel
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I suppose I could spare some fuel for {credits}.\""),
      {credits=fmt.credits(mem.refuel)})

   -- Handle bribing
   if rnd.rnd() < 0.2 then
      mem.bribe = math.sqrt(p:stats().mass) * (500.*rnd.rnd() + 1750.)
      mem.bribe_prompt = fmt.f(
         p_("bribe_prompt", "\"I'll let you go free for {credits}.\""),
         {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = _("\"Very well, away with you before I change my mind.\"")
   else
      bribe_no = {
         p_("bribe_no", "\"Money won't save your hide.\""),
         p_("bribe_no", "\"I have nothing further to say to you.\""),
         p_("bribe_no", "\"I have no interest in your money.\""),
         p_("bribe_no", "\"Who do you take us for, the Empire?\""),
         p_("bribe_no", "\"You can't buy your way out of this.\""),
      }
      mem.bribe_no = bribe_no[rnd.rnd(1, #bribe_no)]
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass thrû before leaving the system

   -- Finish up creation
   create_post()
end

-- taunts
function taunt(target, offense)

   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   -- some taunts
   if offense then
      taunts = {
         p_("taunt", "You give humanity a bad name!"),
         p_("taunt", "Enjoy your last moments!"),
         p_("taunt", "You're a discrace to all of humanity! Now you die!"),
         p_("taunt", "Enemies of Sorom do not belong here!"),
         p_("taunt", "Prepare to feel the wrath of the warriors of Sorom!"),
         p_("taunt", "The warriros of Sorom won't let you get away with your crimes!"),
      }
   else
      taunts = {
         p_("taunt_defensive", "A reckless move!"),
         p_("taunt_defensive", "How dare you attack the warriors of Sorom?!"),
         p_("taunt_defensive", "You'll regret that!"),
         p_("taunt_defensive", "That was a fatal mistake!"),
         p_("taunt_defensive", "You dare harm my precious ship?!"),
      }
   end

   ai.pilot():comm(target, taunts[ rnd.rnd(1,#taunts) ])
end


