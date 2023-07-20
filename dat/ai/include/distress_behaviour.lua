-- Basic behaviour for non-combat ships when in distress
local fmt = require "fmt"

mem.shield_run = 100
mem.armour_run = 100
mem.defensive = false
mem.enemyclose = 500
mem.careful = true


-- Send a distress signal which causes faction loss
function sos()
   local plt = ai.pilot()
   local f = plt:faction():name()
   local shipclass = _(plt:ship():class())
   local msg = {
      p_("sos", "Local security: requesting assistance!"),
      p_("sos", "Mayday! We are under attack!"),
      p_("sos", "Requesting assistance. We are under attack!"),
      fmt.f(p_("sos", "{faction} vessel under attack! Requesting help!"),
         {faction=f}),
      p_("sos", "Help! Ship under fire!"),
      p_("sos", "Taking hostile fire! Need assistance!"),
      p_("sos", "We are under attack, require support!"),
      p_("sos", "Mayday! Ship taking damage!"),
      fmt.f(p_("sos", "Mayday! {faction} {shipclass} being assaulted!"),
         {faction=f, shipclass=shipclass}),
   }
   ai.settarget(ai.taskdata())
   ai.distress(msg[rnd.rnd(1, #msg)])
end
mem.distressmsgfunc = sos
