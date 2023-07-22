require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

-- We’ll consider the Za'lek prefer to turn a bad (i.e. battle) situation into
-- a profitable one by getting money and selling fuel if possible if the player
-- hasn’t been too hostile in the past.

-- Settings
mem.armour_run = 75 -- Za'lek armour is pretty crap. They know this, and will dip when their shields go down.
mem.aggressive = true


function create()
   local p = ai.pilot()
   -- See if a drone
   local shiptype = p:ship():nameRaw()
   if shiptype == "Za'lek Light Drone" or shiptype == "Za'lek Scout Drone"
         or shiptype == "Za'lek Heavy Drone"
         or shiptype == "Za'lek Bomber Drone" then
      mem.comm_no = p_("comm_no", "No response.")
      mem.norun = true
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
      mem.refuel_no = p_("refuel_no", "\"I do not have fuel to spare.\"")
   else
      mem.refuel = mem.refuel * 0.6
   end
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I will agree to refuel your ship for {credits}.\""),
      {credits=fmt.credits(mem.refuel)})

   -- See if can be bribed
   if rnd.rnd() < 0.3 then
      mem.bribe = math.sqrt(p:stats().mass) * (500*rnd.rnd() + 1750)
      mem.bribe_prompt = fmt.f(
         p_("bribe_prompt", "\"We will agree to end the battle for {credits}.\""),
         {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = p_("bribe_paid", "\"Temporarily stopping fire.\"")
   else
      local bribe_no = {
         p_("bribe_no", "\"Keep your cash.\""),
         p_("bribe_no", "\"Don't make me laugh!\""),
         p_("bribe_no", "\"My drones aren't interested in your money and neither am I!\""),
         p_("bribe_no", "\"Hahaha! Nice one! Oh, you're actually serious? Of course not, dumbass!\""),
         p_("bribe_no", "\"While I admire the spirit of it, testing my patience is not science.\""),
      }
      mem.bribe_no = bribe_no[rnd.rnd(1, #bribe_no)]
   end

   mem.loiter = 2 -- This is the amount of waypoints the pilot will pass thru before leaving the system

   -- Finish up creation
   create_post()
end


local taunts_offense = {
   p_("taunt", "I will show you the power of the Za'lek fleet!"),
   p_("taunt", "Commencing battle test by eradicating outlaw pilots."),
   p_("taunt", "Your days are over!"),
   p_("taunt", "You interfere with the progress of science!"),
   p_("taunt", "Feel the wrath of our combat drones!"),
   p_("taunt", "Die, you brainless worm!"),
}
local taunts_defense = {
   p_("taunt_defensive", "You just made a big mistake!"),
   p_("taunt_defensive", "You wanna do this? Have it your way."),
   p_("taunt_defensive", "How dare you?! I just got this ship customized!"),
   p_("taunt_defensive", "Idiots! How dare you attack the Za'lek?!"),
   p_("taunt_defensive", "Attacking me was a stupid mistake!"),
}
function taunt(target, offense)
   local p = ai.pilot()
   -- See if a drone
   local shiptype = p:ship():nameRaw()
   if shiptype == "Za'lek Light Drone" or shiptype == "Za'lek Scout Drone"
         or shiptype == "Za'lek Heavy Drone"
         or shiptype == "Za'lek Bomber Drone" then
      return
   end

   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   local taunts
   if offense then
      taunts = taunts_offense
   else
      taunts = taunts_defense
   end

   p:comm(target, taunts[rnd.rnd(1, #taunts)])
end


