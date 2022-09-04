require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

-- Settings
mem.armour_run = 0
mem.armour_return = 0
mem.aggressive = true


function create()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.35 * sprice, 0.85 * sprice))
   mem.kill_reward = rnd.rnd(0.25 * sprice, 0.75 * sprice)

   -- Get refuel chance
   local p = player.pilot()
   if p:exists() then
      local standing = ai.getstanding( p ) or -1
      mem.refuel = rnd.rnd( 1000, 2000 )
      if standing < 70 then
         mem.refuel_no = _("\"I do not have fuel to spare.\"")
      else
         mem.refuel = mem.refuel * 0.6
      end
      -- Most likely no chance to refuel
      mem.refuel_msg = fmt.f(
            _("\"I would be able to refuel your ship for {credits}.\""),
            {credits=fmt.credits(mem.refuel)})
   end

   -- Can't be bribed
   bribe_no = {
          _("\"Your money is of no interest to me.\""),
          _("\"No amount of money can steer me from the will of Sirichana.\""),
          _("\"May Sirichana cleanse your soul after I kill you.\""),
          _("\"You cannot buy your way out of this, heathen.\""),
   }
   mem.bribe_no = bribe_no[rnd.rnd(1, #bribe_no)]

   mem.loiter = 2 -- This is the amount of waypoints the pilot will pass through before leaving the system

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
            _("Die, heathen!"),
            _("Sirichana wishes for your death!"),
            _("Say your prayers!"),
            _("Die and face Sirichana's divine judgment!"),
      }
   else
      taunts = {
            _("Sirichana protect me!"),
            _("You have made a grave error!"),
            _("You do wrong in your provocations!"),
      }
   end

   ai.pilot():comm(target, taunts[ rnd.rnd(1,#taunts) ])
end


