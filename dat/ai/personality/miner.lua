-- Default task to run when idle
function idle ()
   field, ast = system.asteroid() -- Get a random asteroid in the system

   if ai.pilot():cargoFree() == 0 or field == nil then -- Leave this system
      if mem.noleave then
         -- Not allowed to leave, so wander randomly instead.
         local sysrad = rnd.rnd() * system.cur():radius()
         local angle = rnd.rnd() * 2 * math.pi
         ai.pushtask("loiter", vec2.new(math.cos(angle) * sysrad,
               math.sin(angle) * sysrad))
      else
         local pnt = ai.landplanet(mem.land_friendly)
         -- planet must exist
         if pnt == nil then
            ai.settimer(0, rnd.uniform(1, 3))
            ai.pushtask("enterdelay")
         else
            mem.land = pnt:pos()
            ai.pushtask("hyperspace")
            ai.pushtask("land")
         end
      end
   else -- Mine the asteroid
      ai.pushtask("mine", {field, ast})
   end
end
