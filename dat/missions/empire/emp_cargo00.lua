--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Empire Recruitment">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <chance>100</chance>
  <location>Bar</location>
  <faction>Empire</faction>
  <done>Tutorial Part 4</done>
 </avail>
</mission>
--]]
--[[

   Simple cargo mission that opens up the Empire cargo missions.

   Author: bobbens
      minor edits by Infiltrator

]]--

local fmt = require "fmt"
require "jumpdist"
require "missions/empire/common"

bar_desc = _("You see an Imperial Lieutenant who seems to be looking at you.")
misn_title = _("Empire Recruitment")
misn_desc = _("You are being recruited to the Imperial Armada Shipping Division by Liutenant Chesc. Your first task is to deliver some parcels to {planet}.")

text = {}
ask_text = _([[You approach the Imperial Lieutenant.

"Hello, I'm Lieutenant Chesc from the Imperial Armada Shipping Division. We're having another recruitment operation and would be interested in having another skilled pilot among us. We've heard of the work you've done for Mr. Ian Structure and think you would be a perfect candidate. Would you be interested in working for the Empire?"]])
yes_text = _([["Welcome aboard," says Chesc before giving you a firm handshake. "At first you'll just be tested with cargo missions while we gather data on your flying skills. Later on, you could get called upon for more important missions. Who knows? You could be the next Yao Pternov, greatest pilot we ever had in the armada."

He hits a couple buttons on his wrist computer, which springs into action. "It looks like we already have a simple task for you. Deliver these parcels to {planet}. The best pilots started delivering papers and ended up flying into combat against gigantic warships with the Interception Division. Good luck!"]])
pay_text = _([[You deliver the parcels to the Empire Shipping station at the {planet} spaceport. Afterwards, they make you do some paperwork to formalise your participation with the Empire. They tell you to keep an eye out in the mission computer for missions labeled ES, which stands for Empire Shipping, to which you now have access. You can go to the mission computer by clicking on the #bMissions tab#0.
 
You aren't too sure of what to make of your encounter with the Empire. Only time will tell.…]])

log_text = _([[You were recruited into the Empire's shipping division and can now do missions labeled ES, which stands for Empire Shipping. You aren't too sure of what to make of your encounter with the Empire. Only time will tell.…]])


function create ()
   -- Note: this mission does not make any system claims.
   local landed, landed_sys = planet.cur()

   -- target destination
   local planets = {} 
   getsysatdistance(system.cur(), 1, 2,
      function(s)
         for i, pnt in ipairs(s:planets()) do
            local services = pnt:services()
            if s ~= system.get("Hakoi")
                  and pnt:faction() == faction.get("Empire") and pnt:canLand()
                  and services.missions and services.commodity then
               planets[#planets + 1] = {pnt, s}
            end
         end 
         return false
      end) 
   if #planets == 0 then
      misn.finish(false)
   end

   -- Use a non-standard method of creating a random chance of the
   -- mission showing up to ensure that it's guaranteed to show up at
   -- least once.
   if var.peek("es_initiated") and rnd.rnd() >= 0.4 then
      misn.finish(false)
   end
   var.push("es_initiated", true)

   local index = rnd.rnd(1, #planets)
   dest = planets[index][1]
   sys = planets[index][2]

   misn.setNPC(_("Lieutenant"), "empire/unique/czesc.png", bar_desc)
end


function accept ()
   if not tk.yesno("", ask_text) then
      misn.finish()
   end

   misn.markerAdd(sys, "high", dest)

   misn.accept()

   reward = 30000
   misn.setTitle(misn_title)
   misn.setReward(fmt.credits(reward))
   misn.setDesc(fmt.f(misn_desc, {planet=dest:name()}))

   tk.msg("", fmt.f(yes_text, {planet=dest:name()}))

   local osd_desc = {
      fmt.f(_("Land on {planet} ({system} system)"),
         {planet=dest:name(), system=sys:name()}),
   }
   misn.osdCreate(misn_title, osd_desc)

   local c = misn.cargoNew(N_("Parcels"), N_("A bunch of Empire parcels."))
   parcels = misn.cargoAdd(c, 0)
   hook.land("land")
end


function land()

   local landed = planet.cur()
   if landed == dest then
      if misn.cargoRm(parcels) then
         player.pay(reward)
         tk.msg("", fmt.f(pay_text, {planet=dest:name()}))
         var.push("es_cargo", true)
         faction.modPlayer("Empire", 3)
         emp_addShippingLog(log_text)
         misn.finish(true)
      end
   end
end

function abort()
   misn.finish(false)
end
