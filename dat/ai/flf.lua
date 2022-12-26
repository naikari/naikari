require("ai/tpl/generic")
require("ai/personality/patrol")
require "numstring"

-- Settings
mem.aggressive     = true
mem.safe_distance  = 300
mem.armour_run     = 100
mem.shield_return  = 20
mem.land_planet    = false
mem.careful       = true


function create()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.05 * sprice, 0.1 * sprice))
   mem.kill_reward = rnd.rnd(0.1 * sprice, 0.2 * sprice)

   -- Get standing.
   local p = player.pilot()
   local standing
   if p:exists() then
      standing = ai.getstanding( p ) or -1
   else
      standing = -1
   end

   -- Handle bribes.
   if standing < -30 then
      mem.bribe_no = _("\"The only way to deal with scum like you is with cannons!\"")
   else
      mem.bribe = math.sqrt( ai.pilot():stats().mass ) * (300. * rnd.rnd() + 850.)
      mem.bribe_prompt = string.format(_("\"It'll cost you %s for me to ignore your dirty presence.\""), creditstring(mem.bribe))
      mem.bribe_paid = _("\"Begone before I change my mind.\"")
   end

   -- Handle refueling.
   if standing < 30 then
      mem.refuel_no = _("\"I can't spare fuel for you.\"")
   elseif standing < 70 then
      mem.refuel = rnd.rnd(1000, 2000)
      mem.refuel_msg = string.format(_("\"I should be able to spare some fuel for %s.\""), creditstring(mem.refuel))
   else
      mem.refuel = 0
      mem.refuel_msg = string.format(_("Sure thing, %s. On my way."), player.name())
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   -- Finish up creation
   create_post()
end


function taunt ( target, offense )

   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   -- some taunts
   if offense then
      taunts = {
         _("For the Frontier!"),
         _("You'll make great target practice!"),
         _("Purge the oppressors!"),
      }
   else
      taunts = {
         _("You are no match for the FLF!"),
         _("I've killed scum far more dangerous than you!"),
         _("You'll regret that!"),
         _("Death to enemies of the Frontier!"),
      }
   end

   ai.pilot():comm(target, taunts[ rnd.rnd(1,#taunts) ])
end

