-- Default task to run when idle
function idle ()
   field, ast = system.asteroid() -- Get a random asteroid in the system

   if ai.pilot():cargoFree() == 0 or field == nil then -- Leave this system
      local p = ai.pilot()
      if mem.noleave or p:stats().jumps < 1 then
         -- Not allowed to leave, so wander randomly instead.
         local sysrad = rnd.rnd() * system.cur():radius()
         local angle = rnd.rnd() * 2 * math.pi
         ai.pushtask("loiter", vec2.new(math.cos(angle) * sysrad,
               math.sin(angle) * sysrad))
      else
         ai.pushtask("hyperspace")

         local pnt = ai.landplanet(mem.land_friendly)
         if pnt ~= nil then
            ai.pushtask("land", {pnt, pnt:pos()})
         end
      end
   else -- Mine the asteroid
      ai.pushtask("mine", {field, ast})
   end
end
