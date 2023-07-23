-- Default task to run when idle
function idle ()
   if mem.loiter == nil then
      mem.loiter = 3
   end

   if mem.loiter == 0 and not mem.noleave then
      -- Try to leave. Civilians will always try to land on a planet if there is one.
      local p = ai.pilot()
      if p:stats().jumps >= 1 then
         ai.pushtask("hyperspace")
      end

      local pnt = ai.landplanet(mem.land_friendly)
      if pnt ~= nil then
         ai.pushtask("land", pnt:pos())
      end
   else -- Stay. Have a beer.
      local sysrad = rnd.rnd() * system.cur():radius()
      local angle = rnd.rnd() * 2 * math.pi
      ai.pushtask("loiter", vec2.new(math.cos(angle) * sysrad, math.sin(angle) * sysrad))
      mem.loiter = mem.loiter - 1
   end
end
