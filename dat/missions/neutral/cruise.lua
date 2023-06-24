--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Luxury Cruise">
 <avail>
  <priority>59</priority>
  <cond>
   planet.cur():class() ~= "0" and planet.cur():class() ~= "1"
   and planet.cur():class() ~= "2" and planet.cur():class() ~= "3"
   and planet.cur():services()["inhabited"]
   and system.cur():presence("Civilian") &gt; 0
   and (var.peek("tut_complete") == true
      or planet.cur():faction() ~= faction.get("Empire"))
  </cond>
  <chance>960</chance>
  <location>Computer</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[
   Take passengers on a luxury cruise to and from a destination,
   stopping at as many attractions as possible.
--]]

local fmt = require "fmt"
local mh = require "misnhelper"
require "cargo_common"


osd_title = _("Cruise")
osd_msg1 = _("Land on {planet} ({system} system) before {deadline}\n({time} remaining)")
osd_timeup = _("Land on {planet} ({system} system) before {deadline}\n(deadline missed, but you can still finish the cruise late if you hurry)")

cargo_always_available = true


function create()
   -- Note: this mission does not make any system claims.

   -- Calculate the route, distance, jumps, risk of piracy, and cargo to take
   startpla, startsys = planet.cur()
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   if destplanet == nil or not misn.claim("cruise_" .. destsys:nameRaw()) then
      misn.finish(false)
   end

   -- Override tier based on distance.
   if numjumps < 1 then
      tier = 0
   elseif numjumps < 2 then
      tier = 1
   elseif numjumps < 3 then
      tier = 2
   elseif numjumps < 4 then
      tier = 3
   else
      tier = 4
   end

   -- Calculate time limit. Depends on tier and distance.
   -- The second time limit is for the reduced reward.
   stuperpx = 6.9 - 1.15*tier
   stuperjump = 103000 - 750*tier
   stupertakeoff = 103000 - 15000*tier
   takeoffsperjump = 2
   allowance = traveldist*stuperpx + numjumps*stuperjump
         + takeoffsperjump*numjumps*stupertakeoff + stupertakeoff

   -- All that calculation was for one direction, so multiply by 2 for
   -- the return trip.
   allowance = allowance * 2

   -- And randomize the allowance a bit.
   allowance = allowance * (1.1 + 0.1*rnd.sigma())

   timelimit = time.get() + time.create(0, 0, allowance)
   timelimit2 = time.get() + time.create(0, 0, allowance * 1.2)

   local piracyrisk, riskreward
   if avgrisk == 0 then
      riskreward = 0
   elseif avgrisk <= 25 then
      riskreward = 50
   elseif avgrisk > 25 and avgrisk <= 100 then
      riskreward = 100
   else
      riskreward = 200
   end

   jumpreward = (20+riskreward) / 100
   distreward = math.log(50+riskreward) / 100
   reward = (1.75^tier
         * (avgrisk*riskreward + numjumps*jumpreward + traveldist*distreward
            + 10000)
         * (1 + 0.05*rnd.twosigma()))
   stop_reward = 1.5^tier * 25000 * (1 + 0.1*rnd.sigma())

   local title, desc
   if tier <= 0 then
      title = _("Cruise: Budget tour to {planet} ({system} system)")
      desc = _("Take a group of passengers on a budget cruise to {planet} in the {system} system and back within a certain time frame, stopping at as many attractions along the way as possible. The more stops you make, the more money you can make from tips.")
   elseif tier <= 1 then
      title = _("Cruise: Value tour to {planet} ({system} system)")
      desc = _("Take a group of passengers on a value cruise to {planet} in the {system} system and back within a certain time frame, stopping at as many attractions along the way as possible. The more stops you make, the more money you can make from tips.")
   elseif tier <= 2 then
      title = _("Cruise: Modest tour to {planet} ({system} system)")
      desc = _("Take a group of passengers on a modest cruise to {planet} in the {system} system and back within a certain time frame, stopping at as many attractions along the way as possible. The more stops you make, the more money you can make from tips.")
   elseif tier <= 3 then
      title = _("Cruise: Luxury tour to {planet} ({system} system)")
      desc = _("Take a group of passengers on a luxury cruise to {planet} in the {system} system and back within a certain time frame, stopping at as many attractions along the way as possible. The more stops you make, the more money you can make from tips.")
   else
      title = _("Cruise: Exquisite tour to {planet} ({system} system)")
      desc = _("Take a group of passengers on an exquisite cruise to {planet} in the {system} system and back within a certain time frame, stopping at as many attractions along the way as possible. The more stops you make, the more money you can make from tips.")
   end

   desc = desc .. "\n\n"
         .. n_("Jumps: {numjumps}", "Jumps: {numjumps}", numjumps) .. "\n"
         .. _("Travel distance: {distance} AU") .. "\n"
         .. _("Time limit: {time}") .. "\n"
         .. _("Expected tips: {stop_reward} per extra stop")
   local dist = cargo_calculateDistance(system.cur(), planet.cur():pos(),
         destsys, destplanet)

   misn.setTitle(fmt.f(title,
         {planet=destplanet:name(), system=destsys:name()}))
   marker = misn.markerAdd(destsys, "computer")
   misn.setDesc(fmt.f(desc,
         {planet=destplanet:name(), system=destsys:name(), numjumps=numjumps,
            distance=fmt.number(dist / 1000),
            time=tostring(timelimit - time.get()),
            stop_reward=fmt.credits(stop_reward)}))
   misn.setReward(fmt.credits(reward))
end


function accept()
   local playerbest = cargoGetTransit(timelimit, numjumps * 2, traveldist * 2)
   if timelimit < playerbest then
      local tlimit = timelimit - time.get()
      local tmore = playerbest - time.get()
      if not tk.yesno("", fmt.f(
               _("This cruise must finish within {timelimit}, but it will take at least {time} for your ship to get to {planet} and back, missing the deadline. Accept the mission anyway?"),
               {timelimit=tlimit:str(), time=tmore:str(),
                  planet=destplanet:name()})) then
         misn.finish()
      end
   elseif system.cur():jumpDist(destsys, true, true) == nil
         or system.cur():jumpDist(destsys, true, true) > numjumps then
      local text = n_(
            "The fastest route to {planet} is not currently known to you. Landing to buy maps, spending time searching for unknown jumps, or taking a route longer than {jumps} jump may cause you to miss the deadline. Accept the mission anyway?",
            "The fastest route to {planet} is not currently known to you. Landing to buy maps, spending time searching for unknown jumps, or taking a route longer than {jumps} jumps may cause you to miss the deadline. Accept the mission anyway?",
            numjumps)
      if not tk.yesno("", fmt.f(text,
               {planet=destplanet:name(), jumps=numjumps})) then
         misn.finish()
      end
   end

   misn.accept()

   intime = true
   dest_landed = false
   stops_made = {}
   stops_made.__save = true

   local osd_msg = {
      fmt.f(osd_msg1,
            {planet=destplanet:name(), system=destsys:name(),
               deadline=timelimit:str(),
               time=time.str(timelimit - time.get(), 2)}),
      fmt.f(osd_msg1,
            {planet=startpla:name(), system=startsys:name(),
               deadline=timelimit:str(),
               time=time.str(timelimit - time.get(), 2)}),
      _("Land on additional planets along the way to earn extra credits"),
   }
   misn.osdCreate(osd_title, osd_msg)
   hook.land("land")
   hook.date(time.create(0, 0, 1000), "tick")
end


function cargo_selectMissionDistance()
   return rnd.rnd(0, 5)
end


function land()
   -- Start planet gets special handling.
   if planet.cur() == startpla then
      if dest_landed then
         local pay_text
         local credits
         if not intime then
            pay_text = {
               _("Passengers rush out of your ship, clearly stressed by how much longer they were out on the cruise than they hoped. Because of the delay, you are only paid {credits}."),
               _("Your now upset pasengers eagerly disembark back onto {planet}, trying to make up for the lost time you caused by returning late. By the end of it, you are only paid {credits} for the botched cruise."),
               _("Before you know it, your passengers, angry at you for your late return, are out of your ship. There are no tips, and when you count out the total of your fares, you find that you have only been paid {credits}."),
            }
            credits = reward / 2
         elseif #stops_made > 1 then
            pay_text = {
               _("Your passengers disembark and return to their homeworld after a nice and enjoyable cruise. In total, you receive {credits} from the passengers in basic fares and tips."),
               _("Your passengers disembark back onto {planet} in high spirits. The tips are good and in total, you receive {credits}."),
               _("You receive a grand total of {credits} from your happy passengers as they exit your ship, talking happily to each other about the amazing experience."),
            }
            local stops = #stops_made - 1
            credits = reward + stops*stop_reward
                  + 0.1*stops*stop_reward*rnd.sigma()
         else
            pay_text = {
               _("Your passengers disembark and return to their homeworld after a nice, albeït not terribly eventful cruise. You unfortunately don't receive any tips, but you receive the promised fare of {credits}."),
               _("Your passengers return to {planet} content that they went on a decent cruise and you receive your promised fare of {credits}."),
               _("Having completed the cruise, your passengers return to {planet} satisfied, and you receive your {credits} fare."),
            }
            credits = reward
         end

         -- Mark the initial tutorial as complete.
         var.push("tut_complete", true)

         tk.msg("", fmt.f(pay_text[rnd.rnd(1, #pay_text)],
               {planet=startpla:name(), credits=fmt.credits(credits)}))
         player.pay(credits)
         misn.finish(true)
      elseif intime then
         local text = {
            _("You see that passengers are confused about the fact that you have returned to their home planet before finishing the cruise. You reassure them that it's just a temporary stop and the cruise will go underway shortly."),
            _("A passenger complains that they didn't go on this cruise just to land on their own home planet. You apologize and promise the cruise will begin in earnest soon."),
            _("Confused as to why you landed on their home planet, passengers decide to remain in your ship, uninterested in exploring a place they already know so well."),
            _("Passengers begin to disembark onto {planet}, but soon notice that you've landed on their homeworld and return to your ship, somewhat annoyed."),
         }

         tk.msg("", fmt.f(text[rnd.rnd(1, #text)], {planet=startpla:name()}))
         return
      else
         local text = {
            _("Your passengers are furious that you not only failed to take them to {destplanet} as promised, but were also late to return them to {startplanet}. Your passengers refuse to pay anything."),
            _("Everyone is furious at you for your poor performance. They hurriedly storm out of your ship, no doubt hoping to make up for the scheduling problems you caused for them by returning so late."),
         }

         tk.msg("", fmt.f(text[rnd.rnd(1, #text)],
               {startplanet=startpla:name(), destplanet=destplanet:name()}))
         misn.finish(false)
      end
   end

   if not intime then
      local text = {
         _("Furious that you still haven't returned them to their homeworld, your passengers storm out of your ship to seek a ferry."),
         _("Your passengers storm out of your ship, visibly upset that you still haven't taken them home. One passenger spits in your face as they exit."),
      }

      tk.msg("", fmt.f(text[rnd.rnd(1, #text)],
            {startplanet=startpla:name(), destplanet=destplanet:name()}))
      misn.finish(false)
   end

   -- Duplicate planets don't impress the passengers.
   for i, p in ipairs(stops_made) do
      if p == planet.cur() then
         local text = {
            _("Passengers disembark onto {planet}, but as they notice they've already been here on this cruise, most of them quickly grow bored and return to your ship."),
            _("Passengers yawn with disinterest as you land on {planet} again. Some disembark for a short while, but most decide to just stay behind on your ship."),
            _("You hear a collective sigh of disapproval as you land on {planet} yet again. None of your passengers choose to visit."),
         }

         tk.msg("", fmt.f(text[rnd.rnd(1, #text)],
                  {planet=planet.cur():name()}))
         return
      end
   end

   local text
   if planet.cur() == destplanet then
      text = {
         _("Passengers disembark, excited to see what {planet} has to offer. They seem to be having a good time."),
         _("Passengers excitedly begin to explore {planet}, marveling at all the sights and sounds."),
         _("You can see the passengers are excited for the main event, and in mere moments, they're already out of your ship and exploring {planet}."),
      }
      dest_landed = true
      misn.osdActive(2)
      misn.markerMove(marker, startsys)
   else
      text = {
         _("Passengers disembark and spend some time enjoying the sights on {planet}. It seems they're having a good time."),
         _("You inform passengers that they can now disembark and explore {planet} if they like. Many passengers do so, excited to see an unexpected new location."),
         _("Passengers step out of your ship and look in awe at the unfamiliar spaceport of {planet} before goïng off to explore some more."),
      }
   end

   tk.msg("", fmt.f(text[rnd.rnd(1, #text)], {planet=planet.cur():name()}))
   stops_made[#stops_made + 1] = planet.cur()
end


function tick()
   if timelimit >= time.get() then
      local osd_msg = {
         fmt.f(osd_msg1,
               {planet=destplanet:name(), system=destsys:name(),
                  deadline=timelimit:str(),
                  time=time.str(timelimit - time.get(), 2)}),
         fmt.f(osd_msg1,
               {planet=startpla:name(), system=startsys:name(),
                  deadline=timelimit:str(),
                  time=time.str(timelimit - time.get(), 2)}),
         _("Land on additional planets along the way to earn extra credits"),
      }
      misn.osdCreate(osd_title, osd_msg)
      if dest_landed then
         misn.osdActive(2)
      end
   elseif timelimit2 <= time.get() or not dest_landed then
      -- Case missed second deadline
      mh.showFailMsg(_("You failed to complete the cruise on time."))
      misn.finish(false)
   elseif intime then
      -- Case missed first deadline
      local osd_msg = {
         fmt.f(osd_timeup,
               {planet=destplanet:name(), system=destsys:name(),
                  deadline=timelimit:str()}),
         fmt.f(osd_timeup,
               {planet=startpla:name(), system=startsys:name(),
                  deadline=timelimit:str()}),
      }
      misn.osdCreate(osd_title, osd_msg)
      misn.osdActive(2)
      intime = false
   end
end
