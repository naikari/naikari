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
      mem.refuel_no = _("\"The warriors of Sorom are not your personal refueller.\"")
   elseif standing < 70 then
      if rnd.rnd() < 0.8 then
         mem.refuel_no = _("\"The warriors of Sorom are not your personal refueller.\"")
      end
   else
      mem.refuel = mem.refuel * 0.6
   end
   -- Most likely no chance to refuel
   mem.refuel_msg = fmt.f(
         _("\"I suppose I could spare some fuel for {credits}.\""),
         {credits=fmt.credits(mem.refuel)})

   -- Handle bribing
   if rnd.rnd() < 0.2 then
      mem.bribe = math.sqrt(p:stats().mass) * (500.*rnd.rnd() + 1750.)
      mem.bribe_prompt = fmt.f(
            _("\"I'll let you go free for {credits}.\""),
            {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = _("\"Very well, away with you before I change my mind.\"")
   else
      bribe_no = {
         _("\"Money won't save your hide.\""),
         _("\"I have nothing further to say to you.\""),
         _("\"I have no interest in your money.\""),
         _("\"Who do you take us for, the Empire?\""),
         _("\"You can't buy your way out of this.\""),
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
         _("There is no room in this universe for scum like you!"),
         _("You give humanity a bad name!"),
         _("Enjoy your last moments, you worm!"),
         _("You're a discrace to all of humanity! Now you die!"),
         _("Enemies of Sorom do not belong here!"),
      }
   else
      taunts = {
         _("Cunning, but foolish."),
         _("How dare you attack the warriors of Sorom?!"),
         _("You'll regret that!"),
         _("That was a fatal mistake!"),
         _("You dare harm my precious ship?!"),
      }
   end

   ai.pilot():comm(target, taunts[ rnd.rnd(1,#taunts) ])
end


