local scom = require "factions.spawn.lib.common"


-- @brief Spawns a small fleet.
function spawn_patrol ()
   local pilots = {}
   local r = rnd.rnd()

   if r < 0.5 then
      scom.addPilot(pilots, "Lancelot", 25, {name=_("FLF Lancelot")})
      scom.addPilot(pilots, "Lancelot", 25, {name=_("FLF Lancelot")})
   elseif r < 0.8 then
      scom.addPilot(pilots, "Lancelot", 25, {name=_("FLF Lancelot")})
      scom.addPilot(pilots, "Vendetta", 25, {name=_("FLF Vendetta")})
   else
      scom.addPilot(pilots, "Lancelot", 25, {name=_("FLF Lancelot")})
      scom.addPilot(pilots, "Lancelot", 25, {name=_("FLF Lancelot")})
      scom.addPilot(pilots, "Vendetta", 25, {name=_("FLF Vendetta")})
   end

   return pilots
end


-- @brief Spawns a medium sized squadron.
function spawn_squad ()
   local pilots = {}
   local r = rnd.rnd()

   if r < 0.5 then
      scom.addPilot(pilots, "Lancelot", 25, {name=_("FLF Lancelot")})
      scom.addPilot(pilots, "Lancelot", 25, {name=_("FLF Lancelot")})
      scom.addPilot(pilots, "Vendetta", 25, {name=_("FLF Vendetta")})
   elseif r < 0.8 then
      scom.addPilot(pilots, "Lancelot", 25, {name=_("FLF Lancelot")})
      scom.addPilot(pilots, "Vendetta", 25, {name=_("FLF Vendetta")})
      scom.addPilot(pilots, "Vendetta", 25, {name=_("FLF Vendetta")})
   else
      scom.addPilot(pilots, "Lancelot", 25, {name=_("FLF Lancelot")})
      scom.addPilot(pilots, "Pacifier", 110, {name=_("FLF Pacifier")})
   end

   return pilots
end


-- @brief Creation hook.
function create ( max )
   local weights = {}

   -- Create weights for spawn table
   weights[ spawn_patrol  ] = 100
   weights[ spawn_squad   ] = math.max(1, -80 + 0.80 * max)

   -- Create spawn table base on weights
   spawn_table = scom.createSpawnTable( weights )

   -- Calculate spawn data
   spawn_data = scom.choose( spawn_table )

   return scom.calcNextSpawn( 0, scom.presence(spawn_data), max )
end


-- @brief Spawning hook
function spawn ( presence, max )
   -- Over limit
   if presence > max then
      return 5
   end

   -- Actually spawn the pilots
   local pilots = scom.spawn( spawn_data, "FLF", true )

   -- Calculate spawn data
   spawn_data = scom.choose( spawn_table )

   return scom.calcNextSpawn( presence, scom.presence(spawn_data), max ), pilots
end

