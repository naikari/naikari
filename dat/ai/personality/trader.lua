-- Default task to run when idle
function idle ()
   local p = ai.pilot()
   if mem.noleave or p:stats().jumps < 1 then
      -- Can't leave, so wander randomly instead.
      local sysrad = rnd.rnd() * system.cur():radius()
      local angle = rnd.rnd() * 2 * math.pi
      ai.pushtask("loiter", vec2.new(math.cos(angle) * sysrad,
            math.sin(angle) * sysrad))
   else
      ai.pushtask("hyperspace")

      local pnt = ai.landplanet(mem.land_friendly)
      if pnt ~= nil and mem.land_planet and not mem.tookoff then
         ai.pushtask("land", pnt:pos())
      end
   end
end
