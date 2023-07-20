require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

-- Settings
mem.armour_run = 40
mem.armour_return = 70
mem.aggressive = true
mem.atk_kill = true


function create()
   local p = ai.pilot()
   local sprice = p:ship():price()
   ai.setcredits(rnd.rnd(0.35 * sprice, 0.85 * sprice))
   mem.kill_reward = rnd.rnd(0.15 * sprice, 0.2 * sprice)

   -- Get refuel chance
   local standing = p:faction():playerStanding()
   mem.refuel = rnd.rnd(2000, 4000)
   if standing < 20 then
      mem.refuel_no = p_("refuel_no", "\"Begone. My fuel isn't for sale.\"")
   elseif standing < 70 then
      if rnd.rnd() < 0.8 then
         mem.refuel_no = p_("refuel_no", "\"My fuel isn't for sale.\"")
      end
   else
      mem.refuel = mem.refuel * 0.6
   end
   -- Most likely no chance to refuel
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I can transfer some fuel for {credits}.\""),
      {credits=fmt.credits(mem.refuel)})

   -- See if can be bribed
   if rnd.rnd() < 0.4 then
      mem.bribe = math.sqrt(p:stats().mass) * (500*rnd.rnd() + 1750)
      mem.bribe_prompt = fmt.f(
         p_("bribe_prompt", "\"I can always use some income. {credits} and you were never here.\""),
         {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = p_("bribe_paid", "\"Get lost before I have to dispose of you.\"")
   else
      bribe_no = {
         p_("bribe_no", "\"You won't buy your way out of this one.\""),
         p_("bribe_no", "\"We like to make examples out of scum like you.\""),
         p_("bribe_no", "\"You've made a huge mistake.\""),
         p_("bribe_no", "\"Bribery carries a harsh penalty, scum.\""),
         p_("bribe_no", "\"I'm not interested in your blood money!\""),
         p_("bribe_no", "\"All the money in the universe won't save you now!\""),
         p_("bribe_no", "\"Of course common scum like you would try bribery! You die!\""),
         p_("bribe_no", "\"I would never take money from degenerate scum like you!\""),
      }
      mem.bribe_no = bribe_no[rnd.rnd(1, #bribe_no)]
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass thrû before leaving the system

   -- Finish up creation
   create_post()
end


-- taunts
local taunts_offense = {
   p_("taunt", "Animals like you don't deserve to live!"),
   p_("taunt", "Begone from this universe, inferior scum!"),
   p_("taunt", "We will cleanse you and all other scum from this universe!"),
   p_("taunt", "Enemies of the state will not be tolerated!"),
   p_("taunt", "Long live the Proteron!"),
   p_("taunt", "War is peace!"),
   p_("taunt", "Freedom is slavery!"),
   p_("taunt", "Hail the great leader!"),
   p_("taunt", "It's time to make the galaxy great again!"),
   p_("taunt", "I will cleanse the galaxy of degenerate scum like you!"),
}
local taunts_defense = {
   p_("taunt_defensive", "How dare you attack the Proteron?!"),
   p_("taunt_defensive", "I will have your head!"),
   p_("taunt_defensive", "You'll regret that!"),
   p_("taunt_defensive", "Your fate has been sealed, dissident!"),
   p_("taunt_defensive", "You will pay for your treason!"),
   p_("taunt_defensive", "Die along with the old Empire!"),
   p_("taunt_defensive", "Inferior scum! How dare you attack me?!"),
   p_("taunt_defensive", "Degenerate scum! You die!"),
}
function taunt(target, offense)
   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
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


