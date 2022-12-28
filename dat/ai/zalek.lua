require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

-- We’ll consider the Za'lek prefer to turn a bad (i.e. battle) situation into
-- a profitable one by getting money and selling fuel if possible if the player
-- hasn’t been too hostile in the past.

-- Settings
mem.armour_run = 75 -- Za'lek armour is pretty crap. They know this, and will dip when their shields go down.
mem.aggressive = true

local drones = {
   ["Za'lek Heavy Drone"] = true,
   ["Za'lek Bomber Drone"] = true,
   ["Za'lek Light Drone"] = true,
   ["Za'lek Scout Drone"] = true,
}

function create()
   local p = ai.pilot()
   -- See if a drone
   mem.isdrone = drones[p:ship():nameRaw()] or false
   if mem.isdrone then
      mem.comm_no = _("No response.")
      mem.armour_run = 0 -- Drones don't run
      create_post()
      return
   end

   local sprice = p:ship():price()
   ai.setcredits(rnd.rnd(0.35 * sprice, 0.85 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.15 * sprice)

   -- Get refuel chance
   local standing = p:faction():playerStanding()
   mem.refuel = rnd.rnd(1000, 2000)
   if standing < -10 then
      mem.refuel_no = _("\"I do not have fuel to spare.\"")
   else
      mem.refuel = mem.refuel * 0.6
   end
   mem.refuel_msg = fmt.f(
         _("\"I will agree to refuel your ship for {credits}.\""),
         {credits=fmt.credits(mem.refuel)})

   -- See if can be bribed
   if rnd.rnd() < 0.3 then
      mem.bribe = math.sqrt(p:stats().mass) * (500*rnd.rnd() + 1750)
      mem.bribe_prompt = fmt.f(
            _("\"We will agree to end the battle for {credits}.\""),
            {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = _("\"Temporarily stopping fire.\"")
   else
      local bribe_no = {
         _("\"Keep your cash.\""),
         _("\"Don't make me laugh.!\""),
         _("\"My drones aren't interested in your money and neither am I!\""),
         _("\"Hahaha! Nice one! Oh, you're actually serious? Of course not, fool!\""),
         _("\"While I admire the spirit of it, testing my patience is not science.\""),
      }
      mem.bribe_no = bribe_no[rnd.rnd(1, #bribe_no)]
   end

   mem.loiter = 2 -- This is the amount of waypoints the pilot will pass through before leaving the system

   -- Finish up creation
   create_post()
end

function taunt ( target, offense )
   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   if offense then
      taunts = {
         _("I will show you the power of the Za'lek fleet!"),
         _("Commencing battle test by eradicating outlaw pilots."),
         _("Your days are over!"),
         _("You interfere with the progress of science!"),
         _("Feel the wrath of our combat drones!"),
      }
   else
      taunts = {
         _("You just made a big mistake!"),
         _("You wanna do this? Have it your way."),
         _("How dare you?! I just got this ship customized!"),
         _("Aggressor! How dare you attack the Za'lek?!"),
      }
   end

   ai.pilot():comm(target, taunts[ rnd.rnd(1,#taunts) ])
end


