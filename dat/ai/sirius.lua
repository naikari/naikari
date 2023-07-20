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
   mem.refuel = rnd.rnd(1000, 2000)
   if standing < 70 then
      mem.refuel_no = p_("refuel_no", "\"I do not have fuel to spare.\"")
   else
      mem.refuel = mem.refuel * 0.6
   end
   -- Most likely no chance to refuel
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I would be able to refuel your ship for {credits}.\""),
      {credits=fmt.credits(mem.refuel)})

   -- Can't be bribed
   bribe_no = {
      p_("bribe_no", "\"Your money is of no interest to me.\""),
      p_("bribe_no", "\"No amount of money can steer me from the will of Sirichana.\""),
      p_("bribe_no", "\"May Sirichana cleanse your soul after I kill you.\""),
      p_("bribe_no", "\"You cannot buy your way out of this, heathen.\""),
   }
   mem.bribe_no = bribe_no[rnd.rnd(1, #bribe_no)]

   mem.loiter = 2 -- This is the amount of waypoints the pilot will pass thrû before leaving the system

   -- Finish up creation
   create_post()
end


-- taunts
local taunts_offense = {
   p_("taunt", "Die, heathen!"),
   p_("taunt", "Sirichana wishes for your death!"),
   p_("taunt", "Say your prayers!"),
   p_("taunt", "Die and face Sirichana's divine judgment!"),
}
local taunts_defense = {
   p_("taunt_defensive", "Sirichana protect me!"),
   p_("taunt_defensive", "You have made a grave error!"),
   p_("taunt_defensive", "You do wrong in your provocations!"),
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


