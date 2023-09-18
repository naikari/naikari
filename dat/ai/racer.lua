require("ai/tpl/generic")
require("ai/include/distress_behaviour")
local fmt = require "fmt"

mem.armor_localjump = 40


function create()
   local sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(0.5 * sprice, 1 * sprice))

   -- No bribe
   local bribe_msg = {
      p_("bribe_no", "\"Just leave me alone!\""),
      p_("bribe_no", "\"What do you want from me!?\""),
      p_("bribe_no", "\"Get away from me!\"")
   }
   mem.bribe_no = bribe_msg[rnd.rnd(1, #bribe_msg)]

   -- Refuel
   mem.refuel = math.min(rnd.rnd(1000, 3000), player.credits())
   if mem.refuel > 0 then
      mem.refuel_msg = fmt.f(
         p_("refuel_prompt", "\"I'll supply your ship with fuel for {credits}.\""),
         {credits=fmt.credits(mem.refuel)})
   else
      mem.refuel_msg = p_("refuel", "\"Alright, I'll give you some fuel.\"")
   end

   create_post()
end


function idle()
   local p = ai.pilot()
   local pos, radius = table.unpack(mem.race_points[mem.race_next_point])
   if mem.race_current_lap >= mem.race_laps
         and mem.race_next_point >= #mem.race_points then
      local pnt = ai.planetfrompos(mem.race_land_dest:pos())
      ai.pushtask("land", {pnt, pnt:pos()})
   elseif vec2.dist(p:pos(), pos) <= radius then
      mem.race_next_point = mem.race_next_point + 1
      if mem.race_current_lap >= mem.race_laps
            and mem.race_next_point >= #mem.race_points then
         -- Final step.
         local pnt = ai.planetfrompos(mem.race_land_dest:pos())
         ai.pushtask("land", {pnt, pnt:pos()})

         naik.hookTrigger("race_racer_next_point", p, mem.race_next_point - 1)
      elseif mem.race_next_point > #mem.race_points then
         -- Next lap.
         mem.race_next_point = 1
         mem.race_current_lap = mem.race_current_lap + 1

         local pos = mem.race_points[mem.race_next_point][1]
         ai.pushtask("moveto_race", pos)

         naik.hookTrigger("race_racer_next_lap", p, mem.race_current_lap)
      else
         local pos = mem.race_points[mem.race_next_point][1]
         ai.pushtask("moveto_race", pos)

         naik.hookTrigger("race_racer_next_point", p, mem.race_next_point - 1)
      end
   else
      ai.pushtask("moveto_race", pos)
   end
end

