--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Racing Skills 2">
 <avail>
  <priority>50</priority>
  <cond>
   planet.cur():class() ~= "1"
   and planet.cur():class() ~= "2"
   and planet.cur():class() ~= "3"
   and system.cur():presence("Civilian") &gt; 0
   and system.cur():presence("Pirate") &lt;= 0
  </cond>
  <done>Racing Skills 1</done>
  <chance>20</chance>
  <location>Bar</location>
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

   MISSION: Racing Skills 2
   DESCRIPTION: The player joins a race sponsored by Melendez.

--]]

local fmt = require "fmt"
local mh = require "misnhelper"
local pilotname = require "pilotname"
local portrait = require "portrait"


local ask_text = _([["Are you interested in participating in the upcoming race? All participants are paid {credits} for participating, and there are prizes if you perform well in the race. You can see the information for the race right here. Would you be interested?"]])

local yes_text = _([[The race organizer signs you up for the race and instructs you to meet the other racers out in space when you're ready.]])

local win_text = {
   _([[A man in a suit and tie takes you up onto a stage. A large name tag on his jacket says "Melendez Corporation". "Congratulations on your win," he says, shaking your hand, "that was a great race. On behalf of Melendez Corporation, I would like to present to you your prize money of {credits}!" He hands you one of those fake oversized checks for the audience, and then a credit chip with the actual prize money and participation payment on it.]]),
   _([[A woman in a suit and tie takes you up onto a stage. A large name tag on her jacket says "Melendez Corporation". "Congratulations on your win," she says, shaking your hand, "that was a great race. On behalf of Melendez Corporation, I would like to present to you your prize money of {credits}!" She hands you one of those fake oversized checks for the audience, and then a credit chip with the actual prize money and participation payment on it.]]),
}

local secondplace_text = {
   _([[You congratulate the winner on a great race. While you didn't win the race, you did well to finish in second place. A man in a suit and tie wearing a tag that says "Melendez Corporation" hands you your prize of {credits} alongside your participation payment and congratulates you.]]),
   _([[You congratulate the winner on a great race. While you didn't win the race, you did well to finish in second place. A woman in a suit and tie wearing a tag that says "Melendez Corporation" hands you your prize of {credits} alongside your participation payment and congratulates you.]]),
   _([[You congratulate the winner on a great race and collect your prize of {credits} for second place as well as your participation payment.]]),
}

local thirdplace_text = {
   _([[You congratulate the winner on a great race and collect your prize of {credits} for third place as well as your participation payment.]]),
}

local lose_text = {
   _([[You congratulate the winner on a great race and collect your participation payment.]]),
}

local fail_left_text = _([[Because you left the race, you have been disqualified.]])

local NPCname = _("Race Organizer")
local NPCdesc = _("This seems to be an organizer for a race that's about to take place.")

local misndesc = _("You're participating in a sponsored race.")

local details_text = _([[
Checkpoints: {checkpoints}
Laps: {laps}
First Place Prize: {credits1}
Second Place Prize: {credits2}
Third Place Prize: {credits3}]])

local OSDtitle = _("Sponsored Race")

local sponsorship_msg = {
   _("This race is sponsored by Melendez Corporation. Problem-free ships for problem-free voyages!"),
   _("Get ready for another exciting race, sponsored by the company you trust, Melendez Corporation!"),
   _("Melendez Corporation presents another exciting race! Get ready, folks!"),
   _("This race is sponsored by Melendez Corporation, the civilian spacecraft company you trust!"),
   _("This race is proudly sponsored by Melendez Corporation. Get ready, folks!"),
}


function create ()
   curplanet, missys = planet.cur()

   -- Only one race is allowed to take place at a time.
   if not misn.claim("race") then
      misn.finish(false)
   end

   -- Get planets, excluding the current planet, and jumps.
   local all_planets = missys:planets()
   local planets = {}
   for i, pnt in ipairs(all_planets) do
      if pnt ~= curplanet then
         planets[#planets + 1] = pnt
      end
   end
   local jumps = missys:jumps()

   -- Define points.
   local numpoints = math.min(rnd.rnd(3, 5), #planets + #jumps)
   points = {}
   points.__save = true
   while #points < numpoints and #planets + #jumps > 0 do
      local i = rnd.rnd(1, #planets + #jumps)
      local point
      if i <= #planets then
         local pnt = table.remove(planets, i)
         points[#points + 1] = {pnt:pos(), pnt:radius()}
      else
         local jp = table.remove(jumps, i - #planets)
         points[#points + 1] = {jp:pos(), 200}
      end
   end

   -- Add the current planet as the last point.
   points[#points + 1] = {curplanet:pos(), curplanet:radius()}

   if #points < 3 then
      misn.finish(false)
   end

   -- Calculate total distance.
   local dist = 0
   local last_pos = points[#points][1]
   for i, point in ipairs(points) do
      local pos = point[1]
      dist = dist + vec2.dist(last_pos, pos)
      last_pos = pos
   end

   -- Choose number of laps.
   laps = rnd.rnd(2, 5)

   -- Calculate reward.
   local total_points = laps * #points
   credits = total_points * 2500
   credits = credits * (1 + 0.05*rnd.twosigma())
   prize1 = total_points*5000 + 0.25*dist*(1.75^(laps-1))
   prize1 = prize1 * (1 + 0.05*rnd.twosigma())
   prize2 = prize1 / 2
   prize3 = prize2 / 2

   -- Choose ships.
   local shipchoices = {
      "Llama",
      "Gawain",
      "Hyena",
      "Shark",
      "Lancelot",
      "Ancestor",
      "Quicksilver",
      "Koäla",
   }
   ships = {}
   ships.__save = true
   for i = 1, 3 do
      local shiptype = shipchoices[rnd.rnd(1, #shipchoices)]
      local p = pilot.add(shiptype, "Civilian")
      local outfits = p:outfits()
      p:rm()
      ships[#ships + 1] = {shiptype, outfits}
   end

   misn.setNPC(NPCname, portrait.get(curplanet:faction()), NPCdesc)
end


function accept ()
   local details = fmt.f(details_text,
         {checkpoints=fmt.number(#points), laps=fmt.number(laps),
            credits1=fmt.credits(prize1), credits2=fmt.credits(prize2),
            credits3=fmt.credits(prize3)})
   local ask_parts = {
      fmt.f(ask_text, {credits=fmt.credits(credits)}),
      details,
   }
   if tk.yesno("", table.concat(ask_parts, "\n\n")) then
      tk.msg("", yes_text)

      misn.accept()

      race_started = false
      next_point = 1
      current_lap = 1
      racers_landed = 0

      misn.setTitle(OSDtitle)
      misn.setDesc(table.concat({misndesc, details}, "\n\n"))
      misn.setReward(fmt.credits(credits))

      gen_osd()

      hook.takeoff("takeoff")
   else
      misn.finish()
   end
end


function gen_osd()
   local osd_desc = {
      fmt.f(_("Wait for Race Referee's signal near {planet} ({system} system)"),
         {planet=curplanet:name(), system=missys:name()}),
      string.format(n_("Go to Checkpoint %d, indicated on overlay map",
            "Go to Checkpoint %d, indicated on overlay map", next_point),
         next_point),
      fmt.f(n_("Lap {current_lap:d}/{total_laps:d}",
            "Lap {current_lap:d}/{total_laps:d}", current_lap),
         {current_lap=current_lap, total_laps=laps}),
      fmt.f(_("Land on {planet} ({system} system)"),
         {planet=curplanet:name(), system=missys:name()}),
   }
   misn.osdCreate(OSDtitle, osd_desc)

   if race_started then
      system.mrkRm(mark)
      if current_lap >= laps and next_point >= #points then
         misn.osdActive(4)
         misn.markerAdd(missys, "high", curplanet)
      else
         misn.osdActive(2)
         local pos = points[next_point][1]
         mark = system.mrkAdd(
            string.format(n_("Checkpoint %d", "Checkpoint %d", next_point),
               next_point),
            pos)
      end
   elseif not player.isLanded() then
      system.mrkRm(mark)
      local ppos = player.pilot():pos()
      local pos, radius = table.unpack(points[#points])
      if vec2.dist(ppos, pos) > radius then
         mark = system.mrkAdd(_("Starting Point"), pos)
      else
         local pos = points[next_point][1]
         mark = system.mrkAdd(
            string.format(n_("Checkpoint %d", "Checkpoint %d", next_point),
               next_point),
            pos)
      end
   end
end


function get_checkpoint_msg(pilot_name, checkpoint)
   local msg_list = {
      _("{pilot} makes it to the next checkpoint!"),
      _("Look at {pilot} go!"),
      n_("{pilot} zooms thru Checkpoint {checkpoint:d}!",
         "{pilot} zooms thru Checkpoint {checkpoint:d}!", checkpoint),
      n_("{pilot} just made it to Checkpoint {checkpoint:d}, folks!",
         "{pilot} just made it to Checkpoint {checkpoint:d}, folks!",
         checkpoint),
      n_("{pilot} reached checkpoint {checkpoint:d}! Go! Go!",
         "{pilot} reached checkpoint {checkpoint:d}! Go! Go!", checkpoint),
   }
   return fmt.f(msg_list[rnd.rnd(1, #msg_list)],
         {pilot=pilot_name, checkpoint=checkpoint})
end


function get_lap_msg(pilot_name, lap)
   local msg_list = {
      _("{Pilot} makes it to the next lap!"),
      _("Look at {pilot} go!"),
      n_("{pilot} zooms thru the starting point and starts lap {lap:d}!",
         "{pilot} zooms thru the starting point and starts lap {lap:d}!", lap),
      n_("{pilot} just started lap {lap:d}, folks!",
         "{pilot} just started lap {lap:d}, folks!", lap),
      n_("{pilot} reached lap {lap:d}! Go! Go!",
         "{pilot} reached lap {lap:d}! Go! Go!", lap),
   }
   return fmt.f(msg_list[rnd.rnd(1, #msg_list)], {pilot=pilot_name, lap=lap})
end


function takeoff()
   gen_osd()

   local f = faction.dynAdd(nil, N_("Referee"), nil, {ai="stationary"})
   local angle = rnd.rnd() * 2 * math.pi
   local radius = 3 * curplanet:radius()
   local pos = (curplanet:pos()
         + vec2.new(math.cos(angle) * radius, math.sin(angle) * radius))
   referee = pilot.add("Mule", f, pos, _("Race Referee"))
   referee:setInvincible()
   referee:setVisible()
   referee:setNoClear()
   referee:broadcast(sponsorship_msg[rnd.rnd(1, #sponsorship_msg)])

   local face_target = points[1][1]
   racers = {}
   for i, t in ipairs(ships) do
      local shiptype, outfits = table.unpack(t)
      local p = pilot.add(shiptype, "Civilian", curplanet, pilotname.generic(),
            {ai="racer"})

      if outfits ~= nil then
         p:outfitRm("all")
         p:outfitRm("cores")
         for j, o in ipairs(outfits) do
            p:outfitAdd(o)
         end
      end

      p:setInvincPlayer()
      p:setVisible()
      p:setHilight()
      p:setNoClear()
      p:control()
      p:face(face_target, true)

      local mem = p:memory()
      mem.race_points = points
      mem.race_laps = laps
      mem.race_next_point = next_point
      mem.race_current_lap = current_lap
      mem.race_land_dest = curplanet

      hook.pilot(p, "land", "racer_land")
      hook.pilot(p, "jump", "racer_jump")

      racers[#racers + 1] = p
   end

   countdown_hook = hook.timer(3, "timer_ready")
   hook.timer(1/20, "timer_check_status")
   hook.custom("race_racer_next_point", "racer_next_point")
   hook.custom("race_racer_next_lap", "racer_next_lap")
   hook.jumpout("jumpout")
   hook.land("land")
end


function timer_ready()
   referee:broadcast(_("Get ready for excitement! Racers, please take your places while I start the countdown."))
   countdown_hook = hook.timer(3, "timer_countdown", 5)
end


function timer_countdown(count)
   if count > 0 then
      referee:broadcast(string.format(p_("race_countdown", "%d…"), count))
      countdown_hook = hook.timer(1, "timer_countdown", count - 1)
   else
      referee:broadcast(p_("race_countdown", "Go!"))
      race_started = true
      gen_osd()
      for i, p in ipairs(racers) do
         p:control(false)
      end
   end
end


function timer_check_status()
   if race_started then
      -- Record the player's progress thru the race.
      local npoints = #points
      local pos, radius = table.unpack(points[next_point])
      if (current_lap < laps or next_point < npoints)
            and vec2.dist(player.pos(), pos) <= radius then
         next_point = next_point + 1
         if current_lap >= laps and next_point >= npoints then
            -- Final step.
            player.msg(fmt.f(_("Land on {planet}."),
                  {planet=curplanet:name()}))
         elseif next_point > npoints then
            -- Next lap.
            next_point = 1
            current_lap = current_lap + 1
            referee:broadcast(get_lap_msg(player.name(), current_lap))
         else
            -- Next checkpoint.
            referee:broadcast(get_checkpoint_msg(player.name(), next_point - 1))
         end
         gen_osd()
      end
   else
      -- Check to see if the player has left or re-enterd the start
      -- point and stop or restart the countdown as needed.
      local dist = vec2.dist(player.pos(), curplanet:pos())
      local radius = curplanet:radius()
      if countdown_hook ~= nil and dist > radius then
         referee:comm(player.pilot(),
               fmt.f(_("{player}, I'm sorry, please come back to the starting point."),
                  {player=player.name()}),
               true)
         hook.rm(countdown_hook)
         countdown_hook = nil
         gen_osd()
      elseif countdown_hook == nil and dist <= radius then
         referee:broadcast(_("Our apologies for the delay. Alright, take your places, racers!"))
         countdown_hook = hook.timer(3, "timer_countdown", 5)
         gen_osd()
      end
   end

   hook.timer(1/20, "timer_check_status")
end


function racer_land(p, land_planet)
   local mem = p:memory()
   if mem.race_next_point < #mem.race_points
         or mem.race_current_lap < mem.race_laps then
      return
   end
   racers_landed = racers_landed + 1
   referee:broadcast(fmt.f(_("{pilot} has landed and finished the race!"),
         {pilot=p:name()}))
end


function racer_jump(p, jp)
end


function racer_next_point(p, point)
   referee:broadcast(get_checkpoint_msg(p:name(), point))
end


function racer_next_lap(p, lap)
   referee:broadcast(get_lap_msg(p:name(), lap))
end


function jumpout()
   mh.showFailMsg(_("You left the race."))
   misn.finish(false)
end


function land()
   if current_lap >= laps and next_point >= #points then
      -- Consider the mission a "success" even if the player loses.
      if racers_landed <= 0 then
         local s = win_text[rnd.rnd(1, #win_text)]
         tk.msg("", fmt.f(s, {credits=fmt.credits(prize1)}))
         player.pay(prize1)
      elseif racers_landed <= 1 then
         local s = secondplace_text[rnd.rnd(1, #secondplace_text)]
         tk.msg("", fmt.f(s, {credits=fmt.credits(prize2)}))
         player.pay(prize2)
      elseif racers_landed <= 2 then
         local s = thirdplace_text[rnd.rnd(1, #thirdplace_text)]
         tk.msg("", fmt.f(s, {credits=fmt.credits(prize3)}))
         player.pay(prize3)
      else
         tk.msg("", lose_text)
      end
      player.pay(credits)
      misn.finish(true)
   else
      tk.msg("", fail_left_text)
      misn.finish(false)
   end
end


function abort()
   system.mrkRm(mark)
   if racers ~= nil then
      for i, p in ipairs(racers) do
         p:setInvincPlayer(false)
         p:setVisible(false)
         p:setHilight(false)
         p:control(false)
      end
   end
end
