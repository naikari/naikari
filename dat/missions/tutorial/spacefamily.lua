--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="The Space Family">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>4</priority>
  <chance>100</chance>
  <location>None</location>
 </avail>
 <notes>
  <done_evt name="Shipwreck" />
  <campaign>Tutorial</campaign>
 </notes>
</mission>
--]]
--[[
-- This is the mission part of the shipwrecked Space Family mission, started from a random event.
-- See dat/events/neutral/shipwreck
--]]

local fmt = require "fmt"
require "jumpdist"
require "missions/neutral/common"


board_text = _([[The airlock opens, and you are greeted by a nervous-looking man, an upset woman, and three scared children.

"Thank God you are here," the man says. "I don't know how much longer we could've held out. A group of pirates attacked us, disabled our ship with ion cannons, and then boarded us and stole everything we had! They left us for dead, you know. No fuel, no food, and only auxiliary power to sustain us." He then begins to incoherently tell you how much his group has suffered in the past few hours, but you cut him short, not willing to put up with his endless babbling.

With a few to-the-point questions you learn that the man's name is Harrus and his wife's name is Luna. They live, or at least used to live, aboard their trading vessel. "It was a good life, you know," Harrus tells you. "You get to see the galaxy, meet people and see planets, and all that while working from home because, haha, you take your home with you!"]])
board_text2 = _([["Some great life," Luna interjects. "I told you we needed more weapons, but no, you thought we were safe because 'there's so many patrol ships nearby'! You're lucky you didn't get us killed with your damn arrogance!"

Harrus is about to launch into a retort when you defuse the situation by reminding both of them that they're safe now and offering to drop them off at a nearby planet so they can start over. At this, Harrus brightens up. "Everything's going to be fine now," he says cheerfully.]])

directions = {}
directions[1] = _([["Thank you for your generous offer, captain. I know just the place," Harrus tells you. "Take us to {planet} in the {system} system. I'm sure a man of my caliber can find everything he needs there. Please notify me when we arrive." With a plan settled, the family makes themselves comfortable in your quarters and you cross your fingers hoping another argument doesn't break out.]])

directions[2] = _([[Harrus and Luna both step out of your ship and take a look around. Harris looks around seemingly pleased with what he sees, but Luna frowns. "No, no. This won't do at all," she says disapprovingly. "This place is a mess! How are we supposed to make a decent living in a place like this?" Harrus and Luna argue as one of their older children looks at you apologetically from inside your ship.

Eventually, Luna turns her attention to you. "Look, I'm sorry to do this, but could you please take us to a different place, maybe {planet} in the {system} system? I'm sure we can live a comfortable life there." Harrus begrudgingly agrees to the plan and they both stomp back into your ship. You heave a sigh and proceed to get the docking formalities out of the way with the worker who has been awkwardly standing there the whole time.]])
directions[3] = _([["The sky! Have you LOOKED at it?" Harrus rounds on Luna with a furious expression. He clearly isn't happy. "It's completely the wrong color! It's a mockery of our standards of living, and it's right there overhead! Do you want the children to grow up believing the sky is supposed to look like, like… like THAT?" Harrus again looks up at the heavens that offend him so.

"It's just a damn sky!" Luna retorts. "Look at how great this place is! Forget the color of the sky, everything here is perfect!"

Before Harrus can offer a retort, one of their kids speaks up. "Why can't we just go to {planet}?" Hearing this, Harrus and Luna both in unison let out a sigh and agree to the plan, much to your relief. Hopefully this should be the last stop, finally.]])

pay_text = _([[You land at your final stop in your quest to take the space family home. Harrus and Luna sheepishly thank you as they leave, and the kids follow behind them and also thank you.

Surveying your now deserted quarters, you see that the place is spotless, as if Harrus and Luna felt ashamed for acting like children thruout the journey while their own children remained patient all thruout.

As you admire their workmanship, your eye falls on a small box that you don't remember seeing here before. Inside the box, you find a sum of credits and a note written in neat handwriting. It says simply, "Sorry for the trouble."]])

-- Mission details
misn_title = _("The Space Family")
misn_reward = _("A clear conscience.")
misn_desc = {}
misn_desc[1] = _("A shipwrecked space family has enlisted your aid.")
osd_text = _("Land on {planet} ({system} system) to drop off the space family")

-- Aborted mission
msg_abort_space = _([[Sick of their bullshit, you unceremoniously shove the space family out of the airlock and into the coldness of space.]])
msg_abort_landed = _([[Sick of their bullshit, you force the space family out of your ship and lock them out, leaving them to their fate on this planet.]])

log_text = _([[You rescued a bad-tempered man and his family who were stranded aboard their ship. After a lot of annoying complaints, the man and his family finally left your ship, the man's wife leaving a generous payment for the trouble.]])


function create ()
   -- Note: this mission does not make any system claims. 
   misn.accept() -- You boarded their ship, now you're stuck with them.
   misn.setTitle(misn_title)
   misn.setReward(misn_reward)
   misn.setDesc(misn_desc[1])

   inspace = true -- For lack of a test, we'll just have to keep track ourselves.

   -- Intro text, player meets family
   tk.msg("", board_text)
   tk.msg("", board_text2)

   local commod = misn.cargoNew(N_("Space Family"), N_("An obnoxious family that you rescued from a shipwreck and are trying to get off your back."))
   carg_id = misn.cargoAdd(commod, 0)

   -- First stop; subsequent stops will be handled in the land function
   nextstop = 1
   targsys = getsysatdistance(nil, 3) -- Populate the array
   targsys = getlandablesystems(targsys)
   if #targsys == 0 then targsys = {system.get("Apez")} end -- In case no systems were found.
   destsys = targsys[rnd.rnd(1, #targsys)]
   destplanet = getlandable(destsys) -- pick a landable planet in the destination system
   tk.msg("", fmt.f(directions[nextstop],
         {planet=destplanet:name(), system=destsys:name()}))
   misn.osdCreate(misn_title, {
            fmt.f(osd_text,
               {planet=destplanet:name(), system=destsys:name()})
         })
   misn_marker = misn.markerAdd(destsys, "low", destplanet)

   -- Force unboard
   player.unboard()

   hook.land("land")
   hook.takeoff("takeoff")
end

function islandable(p)
   return (p:services()["inhabited"] and p:canLand() and p:class() ~= "0"
         and p:class() ~= "1" and p:class() ~= "2" and p:class() ~= "3"
         and p:nameRaw() ~= "The Stinker" and p:nameRaw() ~= "Blossom")
end

-- Given a system, return the first landable planet found, or nil if none are landable (shouldn't happen in this script)
function getlandable(sys)
   for a, b in pairs(sys:planets()) do
      if islandable(b) then
         return b
      end
   end
   return nil
end

function land()
   if planet.cur() == destplanet then -- We've arrived!
      if nextstop >= 3 then -- This is the last stop
         tk.msg("", string.format(pay_text, destsys:name())) -- Final message
         player.pay(500000)
         misn.cargoJet(carg_id)
         addMiscLog(log_text)
         misn.finish(true)
      else
         nextstop = nextstop + 1
         targsys = getsysatdistance(nil, nextstop+1) -- Populate the array
         targsys = getlandablesystems(targsys)
         if #targsys == 0 then targsys = {system.get("Apez")} end -- In case no systems were found.
         destsys = targsys[rnd.rnd(1, #targsys)]
         destplanet = getlandable(destsys) -- pick a landable planet in the destination system
         tk.msg("", fmt.f(directions[nextstop],
               {planet=destplanet:name(), system=destsys:name()}))
         misn.osdCreate(misn_title, {
                  fmt.f(osd_text,
                     {planet=destplanet:name(), system=destsys:name()}),
               })
         misn.markerMove(misn_marker, destsys, destplanet)
      end
   end
   inspace = false
end

-- Only gets landable systems
function getlandablesystems(systems)
   t = {}
   for k,v in ipairs(systems) do
      for k,p in ipairs(v:planets()) do
         if islandable(p) then
            t[#t+1] = v
            break
         end
      end
   end
   return t
end

function takeoff()
   inspace = true
end

function abort ()
   if inspace then
      tk.msg("", msg_abort_space)
   else
      tk.msg("", msg_abort_landed)
   end
   misn.cargoJet(carg_id)
end
