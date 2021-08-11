require("ai/tpl/generic")
require("ai/personality/patrol")
require "numstring"

-- Settings
mem.aggressive = true


-- Create function
function create ()

   -- Credits.
   local price = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(price / 300, price / 100))

   -- Handle bribing
   local bribe_no = {
         _("\"The only way to deal with scum like you is with cannons!\""),
         _("\"I don't want your money.\""),
         _("\"I'm here for the Frontier, not money.\""),
         _("\"Not interested.\""),
         _("\"I won't let you off that easily.\""),
   }
   mem.bribe_no = bribe_no[rnd.rnd(1,#bribe_no)]

   -- Handle refueling
   local p = player.pilot()
   if p:exists() then
      local standing = ai.getstanding( p ) or -1
      local flf_standing = faction.get("FLF"):playerStanding()

      mem.refuel = rnd.rnd( 1000, 3000 )
      if flf_standing < 50 then
         mem.refuel_no = _("\"Sorry, I can't spare fuel for you.\"")
      elseif standing < 50 then
         mem.refuel_msg = string.format(
               _("\"For you I could make an exception for %s.\""),
               creditstring(mem.refuel))
      else
         mem.refuel = 0
         mem.refuel_msg = _("\"Sure, friend, I can refuel you. On my way.\"")
      end
   end

   -- Handle misc stuff
   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   create_post()
end

-- taunts
function taunt ( target, offense )

   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   if offense then
      taunts = {
         _("For the Frontier!"),
         _("You'll make great target practice!"),
         _("You won't get away with your actions!"),
      }
   else
      taunts = {
         _("You'll regret that!"),
         _("Death to enemies of the Frontier!"),
         _("I won't go down without a fight!"),
         _("To hell with you!"),
      }
   end
   ai.pilot():comm( target, taunts[ rnd.rnd(1,#taunts) ] )
end

