
--[[
-- music will get called with a string parameter indicating status
-- valid parameters:
--    load - game is loading
--    land - player landed
--    combat - player just got a hostile onscreen
--    idle - current playing music ran out
]]--
last = "idle"

-- Faction-specific songs.
factional = {
   Collective = {"collective1", "automat", "ambient4", "terminal", "eureka"},
   Pirate = {"pirate1_theme1", "pirates_orchestra", "ambient4", "terminal"},
   Empire = {"empire1", "empire2", "intro"; add_neutral = true},
   Goddard = {"empire1", "empire2"; add_neutral = true},
   Sirius = {"sirius1", "sirius2"; add_neutral = true},
   Dvaered = {"dvaered1", "dvaered2"; add_neutral = true},
   ["Za'lek"] = {"zalek1", "zalek2"; add_neutral = true},
   Thurion = {"motherload", "dark_city", add_neutral = true},
   Proteron = {"heartofmachine", "imminent_threat", "ambient4", "intro"},
}

-- Planet-specific songs
planet_songs = {
}

-- System-specific songs
system_ambient_songs = {
}

function choose( str )
   -- Stores all the available sound types and their functions
   local choose_table = {
      ["load"] = choose_load,
      ["intro"] = choose_intro,
      ["credits"] = choose_credits,
      ["land"] = choose_land,
      ["ambient"] = choose_ambient,
      ["combat"] = choose_combat
   }

   -- Don't change or play music if a mission or event doesn't want us to
   if var.peek("music_off") then
      -- Save the last music so we don't choose the wrong one when music
      -- is turned back on.
      if str ~= "idle" then
         last = str
      end
      return
   end

   -- Allow restricting play of music until a song finishes
   if var.peek("music_wait") then
      if music.isPlaying() then
         -- Save the last music so we don't choose the wrong one when
         -- the music finishes playing.
         if str ~= "idle" then
            last = str
         end
         return
      else
         var.pop("music_wait")
      end
   end

   -- Means to only change song if needed
   if str == nil then
      str = "ambient"
   end

   if str == "idle" then
      -- If selecting for idle, choose last music.
      if last ~= "idle" then
         choose(last)
      else
         choose_ambient()
         last = "ambient"
         warn(_("'last' variable set to 'idle'; resetting to ambient."))
      end
   else
      -- Normal case
      choose_table[str]()
   end

   -- Save the last music. This ensures that we don't accidentally
   -- change music type to the wrong one when a track finishes playing.
   if str ~= "idle" then
      last = str
   end
end


--[[
Checks to see if a song is being played, if it is it stops it.

   @treturn boolean true if music was playing.
--]]
function checkIfPlayingOrStop( song )
   if music.isPlaying() then
      if music.current() ~= song then
         music.stop()
      end
      return true
   end
   return false
end


--[[
-- @brief Play a song if it's not currently playing.
--]]
function playIfNotPlaying(song)
   if checkIfPlayingOrStop(song) then
      return
   end
   music.load( song )
   music.play()
end


--[[
Chooses Loading songs.
--]]
function choose_load()
   playIfNotPlaying("machina")
end


--[[
Chooses Intro songs.
--]]
function choose_intro()
   playIfNotPlaying("intro")
end


--[[
Chooses Credits songs.
--]]
function choose_credits()
   playIfNotPlaying("machina")
end

--[[
Chooses Land songs.
--]]
function choose_land()
   choose_ambient(true)
end


-- Save old data
last_sysFaction = nil
last_sysNebuDens = nil
last_sysNebuVol = nil
ambient_neutral = {
   "ambient2", "mission", "peace1", "peace2", "peace4", "peace6",
   "void_sensor", "ambiphonic", "ambient4", "terminal", "eureka", "ambient2_5",
}
ambient_nebula = {"ambient1", "ambient3"}
--[[
Chooses ambient songs.
--]]
function choose_ambient(landed)
   local force = true
   local add_neutral = false

   -- Check to see if we want to update
   if music.isPlaying() and (last == "ambient" or last == "land") then
      force = false
   end

   -- Get information about the current system
   local sys = system.cur()
   local factions = sys:presences()
   local nebu_dens, nebu_vol = sys:nebula()

   local strongest = var.peek("music_ambient_force")

   if landed then
      local pnt = planet.cur()

      -- Planet override
      local override = planet_songs[pnt:nameRaw()]
      if override then
         music.load(override[rnd.rnd(1, #override)])
         music.play()
         return
      end

      if strongest == nil then
         if pnt:faction() ~= nil then
            strongest = pnt:faction():nameRaw()
         end
      end
   else
      -- System override
      local override = system_ambient_songs[sys:nameRaw()]
      if override then
         music.load(override[rnd.rnd(1, #override)])
         music.play()
         return
      end
   end

   if strongest == nil then
      if factions then
         local strongest_amount = 0
         for k, v in pairs(factions) do
            if v > strongest_amount then
               strongest = k
               strongest_amount = v
            end
         end
      end
   end

   -- Check to see if changing faction zone
   if strongest ~= last_sysFaction then
      force = true
      last_sysFaction = strongest
   end

   -- Check to see if entering nebula
   local nebu = nebu_dens > 0
   if nebu ~= last_sysNebuDens then
      force = true
      last_sysNebuDens = nebu
   end
 
   -- Must be forced
   if force then
      -- Choose the music, bias by faction first
      local ambient = {}
      local add_neutral = true
      local neutral_prob = 0.6
      if strongest ~= nil and factional[strongest] ~= nil then
         ambient = factional[strongest]
         add_neutral = factional[strongest].add_neutral
      end

      -- Add generic songs if allowed.
      if add_neutral then
         local amcache = ambient
         ambient = {}
         for i, track in ipairs(amcache) do
            ambient[#ambient + 1] = track
         end
         local neut = nebu and ambient_nebula or ambient_neutral
         for i, track in ipairs(neut) do
            ambient[#ambient + 1] = track
         end
      end

      -- Make sure it's not already in the list or that we have to stop the
      -- currently playing song.
      if music.isPlaying() then
         local cur = music.current()
         for i, track in ipairs(ambient) do
            if cur == track then
               return false
            end
         end

         music.stop()
         return
      end

      -- Load music and play
      -- First check to see if one's lined up explicitly.
      local new_track = var.peek("music_ambient_playnext")
      var.pop("music_ambient_playnext")

      if new_track == nil then
         -- Normal procedure: pick a random track.
         new_track = ambient[rnd.rnd(1, #ambient)]

         -- Make it very unlikely (but not impossible) for the same music
         -- to play twice.
         for i=1,3 do
            if new_track == last_track then
               new_track = ambient[rnd.rnd(1, #ambient)]
            else
               break
            end
         end
      end

      last_track = new_track
      music.load(new_track)
      music.play()
   end
end


-- Faction-specific combat songs
factional_combat = {
   Collective = { "collective2", "galacticbattle", "battlesomething1", "combat3" },
   Pirate     = { "battlesomething2", "blackmoor_tides", add_neutral = true },
   Empire     = { "galacticbattle", "battlesomething2"; add_neutral = true },
   Goddard    = { "flf_battle1", "battlesomething1"; add_neutral = true },
   Dvaered    = { "flf_battle1", "battlesomething1", "battlesomething2"; add_neutral = true },
   ["FLF"]    = { "flf_battle1", "battlesomething2"; add_neutral = true },
   Frontier   = { "flf_battle1"; add_neutral = true },
   Sirius     = { "galacticbattle", "battlesomething1"; add_neutral = true },
   Soromid    = { "galacticbattle", "battlesomething2"; add_neutral = true },
   ["Za'lek"] = { "collective2", "galacticbattle", "battlesomething1", add_neutral = true }
}

--[[
Chooses battle songs.
--]]
function choose_combat()
   -- Get some data about the system
   local sys                  = system.cur()
   local nebu_dens, nebu_vol  = sys:nebula()
   
   local strongest = var.peek("music_combat_force")
   if strongest == nil then
      local presences = sys:presences()
      if presences then
         local strongest_amount = 0
         for k, v in pairs( presences ) do
            if faction.get(k):playerStanding() < 0 and v > strongest_amount then
               strongest = k
               strongest_amount = v
            end
         end
      end
   end

   local nebu = nebu_dens > 0
   if nebu then
      combat = { "nebu_battle1", "nebu_battle2", "combat1", "combat2" }
   else
      combat = { "combat3", "combat1", "combat2" }
   end

   if factional_combat[strongest] then
      if factional_combat[strongest].add_neutral then
         for k, v in ipairs( factional_combat[strongest] ) do
            combat[ #combat + 1 ] = v
         end
      else
         combat = factional_combat[strongest]
      end
   end

   -- Make sure it's not already in the list or that we have to stop the
   -- currently playing song.
   if music.isPlaying() then
      local cur = music.current()
      for k,v in pairs(combat) do
         if cur == v then
            return true
         end
      end

      music.stop()
      return true
   end

   local new_track = combat[rnd.rnd(1, #combat)]

   -- Make it very unlikely (but not impossible) for the same music
   -- to play twice
   for i = 1, 3 do
      if new_track == last_track then
         new_track = combat[rnd.rnd(1, #combat)]
      else
         break
      end
   end

   last_track = new_track
   music.load( new_track )
   music.play()
   return true
end

