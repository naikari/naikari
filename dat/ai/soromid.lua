require("ai/tpl/generic")
require("ai/personality/patrol")
require "numstring"

-- Settings
mem.armour_run = 40
mem.armour_return = 70
mem.aggressive = true


function create ()
   sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(sprice / 200, sprice / 50))

   -- Get refuel chance
   local p = player.pilot()
   if p:exists() then
      local standing = ai.getstanding( p ) or -1
      mem.refuel = rnd.rnd( 2000, 4000 )
      if standing < 20 then
         mem.refuel_no = _("\"The warriors of Sorom are not your personal refueller.\"")
      elseif standing < 70 then
         if rnd.rnd() > 0.2 then
            mem.refuel_no = _("\"The warriors of Sorom are not your personal refueller.\"")
         end
      else
         mem.refuel = mem.refuel * 0.6
      end
      -- Most likely no chance to refuel
      mem.refuel_msg = string.format( _("\"I suppose I could spare some fuel for %s.\""), creditstring(mem.refuel) )
   end

   -- Handle bribing
   if rnd.rnd() > 0.4 then
      mem.bribe_no = _("\"I shall especially enjoy your death.\"")
   else
      bribe_no = {
         _("\"Snivelling waste of carbon.\""),
         _("\"Money won't save your hide.\""),
         _("\"We do not consort with vermin.\""),
         _("\"I have nothing further to say to scum like you.\""),
         _("\"Who do you take us for, the Empire?\""),
      }
      mem.bribe_no = bribe_no[ rnd.rnd(1,#bribe_no) ]
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
         _("You insult me with your presence!"),
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


