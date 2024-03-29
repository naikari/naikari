local scom = require "factions.spawn.lib.common"


-- @brief Spawns a single small ship.
function spawn_patrol ()
   local pilots = {}
   local civships = {
      {"Schroedinger", 8, _("Civilian Schroedinger")},
      {"Llama", 8, _("Civilian Llama")},
      {"Gawain", 8, _("Civilian Gawain")},
      {"Hyena", 13, _("Civilian Hyena")},
   }
   local shp = civships[rnd.rnd(1, #civships)]
   scom.addPilot(pilots, shp[1], shp[2], {name=shp[3]})
   return pilots
end

-- @brief Creation hook.
function create ( max )
   local weights = {}

   -- Create weights for spawn table
   weights[ spawn_patrol  ] = 100

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
   local pilots = scom.spawn( spawn_data, "Civilian" )

   -- Calculate spawn data
   spawn_data = scom.choose( spawn_table )

   return scom.calcNextSpawn( presence, scom.presence(spawn_data), max ), pilots
end


