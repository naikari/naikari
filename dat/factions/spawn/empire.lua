local scom = require "factions.spawn.lib.common"

local formation = require "scripts.formation"


function spawn_shark()
   local pilots = {}
   scom.addPilot(pilots, "Imperial Shark", 1)
   return pilots
end
function spawn_lancelot()
   local pilots = {}
   scom.addPilot(pilots, "Imperial Lancelot", 1)
   return pilots
end
function spawn_admonisher()
   local pilots = {}
   scom.addPilot(pilots, "Imperial Admonisher", 1.25)
   return pilots
end
function spawn_pacifier()
   local pilots = {}
   scom.addPilot(pilots, "Imperial Pacifier", 1.5)
   return pilots
end
function spawn_hawking()
   local pilots = {}
   scom.addPilot(pilots, "Imperial Hawking", 1.75)
   return pilots
end
function spawn_peacemaker()
   local pilots = {}
   scom.addPilot(pilots, "Imperial Peacemaker", 2)
   return pilots
end


-- @brief Creation hook.
function create (max)
   local weights = {}

    -- Create weights for spawn table
    weights[spawn_shark] = 20
    weights[spawn_lancelot] = 16
    weights[spawn_admonisher] = 8
    weights[spawn_pacifier] = 4
    weights[spawn_hawking] = 2
    weights[spawn_peacemaker] = 1

   -- Create spawn table base on weights
   spawn_table = scom.createSpawnTable(weights)

   -- Calculate spawn data
   spawn_data = scom.choose(spawn_table)

   return scom.calcNextSpawn(0, scom.presence(spawn_data), max)
end


-- @brief Spawning hook
function spawn (presence, max)
   -- Over limit
   if presence > max then
      return 5
   end

   -- Actually spawn the pilots
   local pilots = scom.spawn(spawn_data, "Empire")

   -- Calculate spawn data
   spawn_data = scom.choose(spawn_table)

   return scom.calcNextSpawn(presence, scom.presence(spawn_data), max), pilots
end


