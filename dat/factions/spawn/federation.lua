local scom = require "factions.spawn.lib.common"

-- @brief Spawns a small patrol fleet.
function spawn_patrol ()
   local pilots = {}
   local r = rnd.rnd()

   if r < 0.5 then
      scom.addPilot(pilots, "Lancelot", 25, {name=_("Federation Lancelot")})
   elseif r < 0.8 then
      scom.addPilot(pilots, "Hyena", 20, {name=_("Federation Hyena")})
      scom.addPilot(pilots, "Lancelot", 25, {name=_("Federation Lancelot")})
   else
      scom.addPilot(pilots, "Hyena", 20, {name=_("Federation Hyena")})
      scom.addPilot(pilots, "Ancestor", 30, {name=_("Federation Ancestor")})
   end

   return pilots
end


-- @brief Spawns a medium sized squadron.
function spawn_squad ()
   local pilots = {}
   local r = rnd.rnd()

   if r < 0.5 then
      scom.addPilot(pilots, "Lancelot", 25, {name=_("Federation Lancelot")})
      scom.addPilot(pilots, "Phalanx", 55, {name=_("Federation Phalanx")})
   else
      scom.addPilot(pilots, "Lancelot", 25, {name=_("Federation Lancelot")})
      scom.addPilot(pilots, "Lancelot", 25, {name=_("Federation Lancelot")})
      scom.addPilot(pilots, "Ancestor", 30, {name=_("Federation Ancestor")})
   end

   return pilots
end


-- @brief Creation hook.
function create (max)
    local weights = {}

    -- Create weights for spawn table
    weights[spawn_patrol] = 100
    weights[spawn_squad] = 0.33 * max

    -- Create spawn table base on weights
    spawn_table = scom.createSpawnTable(weights)

    -- Calculate spawn data
    spawn_data = scom.choose(spawn_table)

    return scom.calcNextSpawn(0, scom.presence(spawn_data), max)
end


-- @brief Spawning hook
function spawn ( presence, max )
    -- Over limit
    if presence > max then
       return 5
    end

    -- Actually spawn the pilots
    local pilots = scom.spawn(spawn_data, "Federation")

    -- Calculate spawn data
    spawn_data = scom.choose(spawn_table)

    return scom.calcNextSpawn(presence, scom.presence(spawn_data), max), pilots
end
