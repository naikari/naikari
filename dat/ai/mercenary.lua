require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

-- Settings
mem.armour_run = 40
mem.armour_return = 70
mem.aggressive = true
mem.atk_kill = true


function create ()
   local p = ai.pilot()
   local sprice = p:ship():price()
   ai.setcredits(rnd.rnd(0.5 * sprice, 1 * sprice))
   mem.kill_reward = rnd.rnd(0.05 * sprice, 0.1 * sprice)

   if rnd.rnd() < 0.3 then
      mem.bribe = math.sqrt(p:stats().mass) * (750. * rnd.rnd() + 2500.)
      mem.bribe_prompt = fmt.f(
         p_("bribe_prompt", "\"Your life is worth {credits} to me.\""),
         {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = p_("bribe_paid", "\"Beat it.\"")
   else
      if rnd.rnd() < 0.5 then
         mem.bribe_no = p_("bribe_no", "\"You won't buy your way out of this one.\"")
      else
         mem.bribe_no = p_("bribe_no", "\"I'm afraid you can't make it worth my while.\"")
      end
   end

   -- Refuel
   mem.refuel = rnd.rnd(3000, 5000)
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I'll supply your ship with fuel for {credits}.\""),
      {credits=fmt.credits(mem.refuel)})

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass thrû before leaving the system

   -- Finish up creation
   create_post()
end


-- taunts
local taunts_offense = {
   p_("taunt", "Don't take this personally."),
   p_("taunt", "It's just business."),
   p_("taunt", "Sorry."),
   p_("taunt", "Nothing personal."),
}
local taunts_defense = {
   p_("taunt_defensive", "Your skull will make a great hood ornament!"),
   p_("taunt_defensive", "I've destroyed ships twice the size of yours!"),
   p_("taunt_defensive", "I'll crush you like a grape!"),
   p_("taunt_defensive", "This isn't what I signed up for!"),
   p_("taunt_defensive", "Oh, now you're in for it!"),
}
function taunt(target, offense)
   -- Only 20% of actually taunting.
   if rnd.rnd(0,4) ~= 0 then
      return
   end

   -- some taunts
   local taunts
   if offense then
      taunts = taunts_offense
   else
      taunts = taunts_defense
   end

   ai.pilot():comm(target, taunts[rnd.rnd(1, #taunts)])
end


